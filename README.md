# 黎曼猜想 Lean 验证

本仓库记录对 Levent Alpöge 发布的黎曼猜想（RH）及 Dirichlet 广义黎曼猜想（GRH）Lean 形式化的复现。[原始公告](https://alpo.ge/remark.pdf)

## 阅读源码

- [完整 Lean 项目](lean/)包含原始归档的 175,187 个 Lean 文件和三个项目配置文件。
- [Main.lean](lean/src/Main.lean)包含五个顶层定理。RH 使用 [Mathlib 的 `RiemannHypothesis`](https://github.com/leanprover-community/mathlib4/blob/0df444a360eaa60ab8c11dca51a86af692955474/Mathlib/NumberTheory/LSeries/RiemannZeta.lean#L185)。
- [Statements.lean](lean/src/Statements.lean)定义了附带的 ζ 函数与 Dirichlet L 函数命题。
- [MainTheorems.lean](lean/src/Supplements/Kernels/MainTheorems.lean)连接顶层命题与证明依赖。

## 验证进度

- 2026-11-20（America/Chicago），本地 PDF 与发布者网站的 PDF 的 SHA-256 相同。[`notice.sha256`](evidence/notice.sha256)
- 在 `yokota_runguoli` 下载原始 14 个分卷，记录校验值，成功合并并解包。[`archive.sha256`](evidence/archive.sha256)
- 安装归档要求的 Lean `v4.33.1`，取回 Mathlib 固定提交 `0df444a360eaa60ab8c11dca51a86af692955474` 及其依赖。
- Slurm 作业 `157149` 完成环境准备，之后因 Lake 目标写法出错而退出。作业 `157153` 复用该环境，开始从源码构建。改用作业 `157166` 续跑，采用 32 个 CPU 和 72 小时时限。

## 验证命令

[运行脚本](verification/build-on-yokota.sh)在 Slurm 计算节点的隔离环境内执行以下命令。构建范围是顶层模块 `Main` 和它实际导入的依赖。

```bash
lake --no-cache build +Main:olean
lake env lean Audit.lean
lake env leanchecker --verbose --fresh Main
```

[Audit.lean](verification/Audit.lean)用 Mathlib 的命题验证 RH 的类型，并直接展开 Dirichlet GRH 的目标。脚本检查五个顶层定理的传递公理依赖，允许 `propext`、`Classical.choice`、`Quot.sound`。

远程工作目录为 `~/riemann-lean-verification.6wrVzm`，作业日志为其中的 `slurm-157166.log`。本机保持在线时，每 15 分钟同步一次作业状态，直到 Slurm 作业结束。[最新验证状态](evidence/status.md)
