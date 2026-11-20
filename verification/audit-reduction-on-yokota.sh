#!/usr/bin/env bash
set -euo pipefail
umask 077

work=${1:?usage: audit-reduction-on-yokota.sh WORK_DIRECTORY}
main=$(cat "$work/build-directory")/lean
toolchain="$work/elan/toolchains/leanprover--lean4---v4.33.1"
stage=$(mktemp -d "/tmp/riemann-reduction-$USER.XXXXXX")
mkdir -p "$stage/src" "$stage/.lake/packages"
cp "$main"/{lakefile.toml,lake-manifest.json,lean-toolchain} "$stage"
cp "$work/AuditReduction.lean" "$stage"

isolated() {
    local -a system_mounts=()
    for path in /usr /bin /lib /lib64 /etc/ld.so.cache; do
        [[ ! -e "$path" ]] || system_mounts+=(--ro-bind "$path" "$path")
    done
    bwrap --unshare-all --die-with-parent --clearenv "${system_mounts[@]}" \
        --proc /proc --dev /dev --tmpfs /tmp --ro-bind "$toolchain" /toolchain \
        --bind "$stage" /project --ro-bind "$main/src" /project/src \
        --ro-bind "$main/.lake/packages" /project/.lake/packages \
        --dir /home/audit --chdir /project --setenv HOME /home/audit \
        --setenv PATH /toolchain/bin:/usr/bin:/bin \
        --setenv LEAN_NUM_THREADS "${SLURM_CPUS_PER_TASK:-8}" "$@"
}

isolated lean --version
isolated lake --no-cache build \
    +Development.AutomorphicArithmetic.CharacterBoxes.ClaimStrip:olean \
    +Formalism.GammaFactorNonvanishing.RhOfRight:olean \
    +Development.AutomorphicArithmetic.PrimitiveCosets.Imports:olean
isolated lake env lean AuditReduction.lean
