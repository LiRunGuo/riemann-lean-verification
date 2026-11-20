"""Publish the status of the Yokota run while the local SSH client is online."""

import argparse
import base64
import datetime
import json
import re
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("job", type=int)
parser.add_argument("--preview", action="store_true")
args = parser.parse_args()

api_path = "repos/LiRunGuo/riemann-lean-verification/contents/evidence/status.md"
terminal = {
    "COMPLETED", "FAILED", "CANCELLED", "TIMEOUT", "OUT_OF_MEMORY",
    "NODE_FAIL", "BOOT_FAIL", "DEADLINE", "PREEMPTED", "REVOKED",
}
theorems = (
    "riemannHypothesis", "riemannZeta_eq_zero_re",
    "LFunction_ne_zero_of_half_lt_re", "LFunction_eq_zero_re",
    "LFunction_eq_zero_re_of_isPrimitive",
)
audit_line = re.compile(
    r"'(?:" + "|".join(theorems) + r")' (?:does not depend on any axioms|"
    r"depends on axioms: \[[\w., ]*\])"
)

def run(command, **kwargs):
    return subprocess.check_output(command, text=True, timeout=75, **kwargs)


def snapshot():
    remote = run([
        "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15",
        "yokota_runguoli", "bash", "-s", "--", str(args.job),
    ], input="""
set -eu
job=$1
work="$HOME/riemann-lean-verification.6wrVzm"
sacct -X -j "$job" -n -P -o JobID,State%24,Elapsed,ExitCode
log="$work/slurm-$job.log"
if [ -f "$log" ]; then
    grep -aE '^===|^Build completed successfully|^replaying Main|^error:|^✖|depends on axioms|depends on any axioms|unexpected axioms' "$log" | tail -25 || true
    grep -aoE '\[[0-9]+/[0-9]+\] Built' "$log" | tail -1 || true
fi
""")
    rows = remote.splitlines()
    match = re.fullmatch(rf"{args.job}\|([A-Z_]+)(?: [^|]*)?\|([0-9:-]+)\|([0-9:]+)", rows[0])
    if match is None:
        raise ValueError(f"unexpected sacct result for {args.job}")
    state, elapsed, exit_code = match.groups()
    last_step = next((row for row in rows if re.fullmatch(r"\[\d+/\d+\] Built", row)), None)
    axioms = [row for row in rows if audit_line.fullmatch(row)]
    stages = [row for row in rows if row.startswith(("=== ", "Build completed successfully", "replaying Main"))]
    failures = [row for row in rows if row.startswith(("error:", "✖")) or "unexpected axioms" in row]
    completed = (
        state == "COMPLETED" and exit_code == "0:0" and len(axioms) == len(theorems)
        and "=== All verification commands exited successfully ===" in stages
    )
    time_utc = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    result = (
        "Lean 构建、命题与公理审计及内核重放全部通过。"
        if completed else "本次作业未通过全部验证步骤。"
        if state in terminal else "服务器作业仍在进行，形式化验证结论待定。"
    )
    lines = [
        "# Yokota 验证状态", "", f"**{result}**", "",
        f"- 更新于 {time_utc}", f"- Slurm 作业 `{args.job}`",
        f"- 状态 `{state}`，耗时 `{elapsed}`，退出码 `{exit_code}`",
    ]
    if last_step:
        lines.append(f"- 最近编译进度 `{last_step}`（Lake 会继续发现依赖）")
    details = stages + axioms + failures
    if details:
        lines.extend(("", "```text", *details, "```"))
    lines.extend(("", f"服务器原始日志位于 `~/riemann-lean-verification.6wrVzm/slurm-{args.job}.log`。", ""))
    return "\n".join(lines), state


while True:
    try:
        report, state = snapshot()
        if args.preview:
            print(report)
            break
        old_sha = run(["gh", "api", api_path, "--jq", ".sha"]).strip()
        body = json.dumps({
            "message": f"Record Yokota job {args.job} status",
            "sha": old_sha,
            "content": base64.b64encode(report.encode()).decode(),
        })
        run(["gh", "api", "-X", "PUT", api_path, "--input", "-"], input=body)
        print(f"Published {state} for {args.job}", flush=True)
        if state in terminal:
            break
    except (subprocess.SubprocessError, ValueError, IndexError) as error:
        if args.preview:
            raise
        print(error, flush=True)
    time.sleep(900)
