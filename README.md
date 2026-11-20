# 黎曼猜想 Lean 验证

本仓库记录对 Levent Alpöge 发布的黎曼猜想（RH）及 Dirichlet 广义黎曼猜想（GRH）Lean 形式化的复现。[原始公告](https://alpo.ge/remark.pdf)

## 阅读源码

- [英文技术导读（A4 PDF）](output/pdf/riemann-lean-guide.pdf)梳理 RH 与 Dirichlet GRH 的证明链、关键估计和验证范围。[LaTeX 源文件](output/pdf/riemann-lean-guide.tex)

- [完整 Lean 项目](lean/)包含原始归档的 175,187 个 Lean 文件和三个项目配置文件。
- [Main.lean](lean/src/Main.lean)包含五个顶层定理。RH 使用 [Mathlib 的 `RiemannHypothesis`](https://github.com/leanprover-community/mathlib4/blob/0df444a360eaa60ab8c11dca51a86af692955474/Mathlib/NumberTheory/LSeries/RiemannZeta.lean#L185)。
- [Statements.lean](lean/src/Statements.lean)定义了附带的 ζ 函数与 Dirichlet L 函数命题。
- [MainTheorems.lean](lean/src/Supplements/Kernels/MainTheorems.lean)连接顶层命题与证明依赖。

## 验证进度

- 2026-11-20（America/Chicago），本地 PDF 与发布者网站的 PDF 的 SHA-256 相同。[`notice.sha256`](evidence/notice.sha256)
- 在验证服务器下载原始 14 个分卷，记录校验值，成功合并并解包。[`archive.sha256`](evidence/archive.sha256)
- 安装归档要求的 Lean `v4.33.1`，取回 Mathlib 固定提交 `0df444a360eaa60ab8c11dca51a86af692955474` 及其依赖。
- Slurm 作业 `157149` 完成环境准备，之后因 Lake 目标写法出错而退出。作业 `157153` 复用该环境，开始从源码构建。改用作业 `157166` 续跑，采用 32 个 CPU 和 72 小时时限。

## 人工审读

1. **目标命题与函数方程。** RH 直接使用 Mathlib 的 `RiemannHypothesis`。Dirichlet GRH 覆盖每个正模数上的每个特征和开临界带内的所有零点。原始特征的函数方程把左半带零点送到逆特征在右半带的零点。非原始特征通过导子降到原始特征，缺失的欧拉因子满足 `|χ(p) p^(-s)| ≤ p^(-Re(s)) < 1`。模 1 特征的 L 函数就是 ζ 函数。[源码](lean/src/Development/AutomorphicArithmetic/CharacterBoxes/ClaimStrip.lean)
2. **单边窗口估计如何排除零点。** 代码对正权重的平滑 von Mangoldt 和使用 Mellin 变换。核 `x/n − 1` 的积分给出分母 `s(s−1)`，对数导数提供零点重数；在零点 `ρ` 处的留数为 `−S/[ρ(ρ−1)]`，其中 `S > 0` 是加权重数之和。同一零点的贡献不会相消，且实零点 `0 < ρ < 1` 的留数为正。窗口引理用高阶导数把积分集中在 `[log Y, (1+δ) log Y]`，分别处理非实极点与实极点。代码需要任意远处存在完整的 `[Y, Y^(1+δ)]` 窗口。误差指数里的 `eD,eL` 在选择任意小的 `ε` 之前固定，这使指数可以压到候选零点实部之下。[留数](lean/src/Development/AutomorphicArithmetic/DedekindLFunctions/LandauTheorems/poleData.lean#L248) · [窗口论证](lean/src/Development/AutomorphicArithmetic/DedekindLFunctions/LandauTheorems/landauWindow.lean#L83) · [量词与误差指数](lean/src/Formalism/SharpRestriction/RamificationFrobenius/TotientGaloisClasses/TopWin.lean#L65)
3. **仍待验证的突破。** 上述归约需要在这些窗口内得到 `Gm(x) ≤ x^(1/2+(eD+eL+7)ε)`。源码把证明分成两条关键支路。一条用 `VWinAt` 给辅助数域的 Galois 上同调核定量上界，并用它建立所需的算术数据。另一条用 theta 积分匹配、协体积界等推出可用于窗口估计的整除与误差控制。顶层提供了这些前提的 Lean 证明项，人工审读已追到其构造入口，尚未逐条验证其深层定义和证明。[上同调界](lean/src/Development/AutomorphicArithmetic/CharacterBoxes/ExistsPageN.lean#L12) · [算术估计](lean/src/Development/AutomorphicArithmetic/PrimitiveCosets/CoreGm.lean#L12) · [顶层装配](lean/src/Development/AutomorphicArithmetic/CharacterBoxes/MainConclusion.lean#L7)

另开隔离作业 `157173` 验证上述解析归约。Lean 构建成功，两个条件推论通过检查，审计的七条引理只依赖标准公理 `propext`、`Classical.choice`、`Quot.sound`。[审计代码](verification/AuditReduction.lean) · [作业输出](evidence/reduction-audit.txt)

## 验证命令

[运行脚本](verification/build-on-slurm.sh)在 Slurm 计算节点的隔离环境内执行以下命令。构建范围是顶层模块 `Main` 和它实际导入的依赖。

```bash
lake --no-cache build +Main:olean
lake env lean Audit.lean
lake env leanchecker --verbose --fresh Main
```

[Audit.lean](verification/Audit.lean)用 Mathlib 的命题验证 RH 的类型，并直接展开 Dirichlet GRH 的目标。脚本检查五个顶层定理的传递公理依赖，允许 `propext`、`Classical.choice`、`Quot.sound`。

本机保持在线时，每 15 分钟同步一次作业状态，直到 Slurm 作业结束。[最新验证状态](evidence/status.md)
