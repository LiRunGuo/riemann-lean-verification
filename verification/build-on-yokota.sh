#!/usr/bin/env bash
set -euo pipefail
umask 077

work=${1:?usage: build-on-yokota.sh WORK_DIRECTORY}
if [[ ${2:-} == --resume ]]; then
    stage=$(cat "$work/build-directory")
    [[ -O "$stage" && -d "$stage/lean" ]]
else
    stage=$(mktemp -d "/tmp/riemann-lean-$USER.XXXXXX")
    printf '%s\n' "$stage" > "$work/build-directory"
    mkdir -p "$stage/trusted" "$stage/cache"

    cd "$work"
    sha256sum -c SHA256SUMS
    cat lean.tar.gz.part?? | python3 extract-source.py "$stage"
    cp "$stage"/lean/{lake-manifest.json,lean-toolchain} "$stage/trusted"
    cat > "$stage/trusted/lakefile.toml" <<'TOML'
name = "tree"
[[require]]
name = "mathlib"
git = "https://github.com/leanprover-community/mathlib4"
rev = "0df444a360eaa60ab8c11dca51a86af692955474"
TOML
fi
cp "$work/Audit.lean" "$stage/lean/Audit.lean"
printf 'Node: %s\nBuild directory: %s\n' "$(hostname)" "$stage"
df -h "$stage"

toolchain="$work/elan/toolchains/leanprover--lean4---v4.33.1"
for ((attempt=0; attempt<90; attempt++)); do
    [[ -x "$toolchain/bin/lean" ]] && break
    sleep 2
done
export PATH="$toolchain/bin:/usr/local/bin:/usr/bin:/bin"
export LEAN_NUM_THREADS="${SLURM_CPUS_PER_TASK:-16}"
export XDG_CACHE_HOME="$stage/cache"
export GIT_TERMINAL_PROMPT=0
lean --version
if [[ ! -d "$stage/lean/.lake/packages" ]]; then
cd "$stage/trusted"
# Fetch only the pinned public dependencies in a separate project.
lake update
python3 - "$stage/lean/lake-manifest.json" lake-manifest.json <<'PY'
import json
import sys

def revisions(path):
    with open(path) as manifest:
        return {p["name"]: (p["url"], p["rev"]) for p in json.load(manifest)["packages"]}

assert revisions(sys.argv[1]) == revisions(sys.argv[2]), "dependency pins changed"
PY
lake exe cache get Mathlib
mkdir -p "$stage/lean/.lake"
mv "$stage/trusted/.lake/packages" "$stage/lean/.lake/packages"
fi

run_isolated() {
    local -a system_mounts=()
    for path in /usr /bin /lib /lib64 /etc/ld.so.cache; do
        [[ ! -e "$path" ]] || system_mounts+=(--ro-bind "$path" "$path")
    done
    bwrap --unshare-all --die-with-parent --clearenv "${system_mounts[@]}" \
        --proc /proc --dev /dev --tmpfs /tmp --ro-bind "$toolchain" /toolchain \
        --bind "$stage/lean" /project --dir /home/audit --chdir /project \
        --setenv HOME /home/audit --setenv PATH /toolchain/bin:/usr/bin:/bin \
        --setenv LEAN_NUM_THREADS "$LEAN_NUM_THREADS" "$@"
}

printf '\n=== Build the source dependency closure of Main ===\n'
run_isolated lake --no-cache build +Main:olean
printf '\n=== Check theorem statements and transitive axiom dependencies ===\n'
run_isolated lake env lean Audit.lean | tee "$work/axioms.log"
python3 - "$work/axioms.log" <<'PYAXIOMS'
import re
import sys
from pathlib import Path

output = Path(sys.argv[1]).read_text()
expected = {
    "riemannHypothesis",
    "riemannZeta_eq_zero_re",
    "LFunction_ne_zero_of_half_lt_re",
    "LFunction_eq_zero_re",
    "LFunction_eq_zero_re_of_isPrimitive",
}
allowed = {"propext", "Classical.choice", "Quot.sound"}
seen = set()
for name, axioms in re.findall(r"'([^']+)' depends on axioms: \[([^\]]*)\]", output):
    seen.add(name)
    unexpected = {a.strip() for a in axioms.split(",") if a.strip()} - allowed
    if unexpected:
        raise SystemExit(f"{name}: unexpected axioms {sorted(unexpected)}")
seen.update(re.findall(r"'([^']+)' does not depend on any axioms", output))
if seen != expected:
    raise SystemExit(f"expected axiom reports for {sorted(expected)}; got {sorted(seen)}")
PYAXIOMS
printf '\n=== Replay Main and its imports through the Lean kernel ===\n'
run_isolated lake env leanchecker --verbose --fresh Main
printf '\n=== All verification commands exited successfully ===\n'
