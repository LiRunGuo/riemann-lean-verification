# Yokota 验证状态

**服务器作业仍在进行，形式化验证结论待定。**

- 更新于 2026-11-20 20:00 UTC
- Slurm 作业 `157166`
- 状态 `RUNNING`，耗时 `04:01:09`，退出码 `0:0`
- 最近编译进度 `[55882/56359] Built`（Lake 会继续发现依赖）

```text
error: resource exhausted (error code: 28, no space left on device)
✖ [115532/115741] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.ImportsExtra (392ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115537/115741] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.ExistsGlobalLatticeLocalGiven (396ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115545/115741] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.NumberFieldEmbMemAlgebraicClosure (378ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115547/115741] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.ImportsRest (393ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115552/115741] Building Formalism.LocalToGlobal.LatticeGeometry.GeometryDefinitions.DefsNN (392ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115636/115768] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.ChainLocalDataIntegralOffLevels (404ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115652/115796] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.LastColumnStepDatumEqTwistTopDatum (449ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115655/115796] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.ImportsTer (366ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115695/115900] Building Formalism.LocalToGlobal.Columns.ChainLawPhiTop (967ms)
error: resource exhausted (error code: 28, no space left on device)
✖ [115722/115917] Building Development.AbelianVarietyTheory.Proofs.SatakeParameters.CoprimeAbsNormCcKOfGIdx (1.1s)
error: resource exhausted (error code: 28, no space left on device)
✖ [115739/115937] Building Formalism.PeriodIntegrals.EtaInfGen (1.6s)
error: resource exhausted (error code: 28, no space left on device)
✖ [115741/115956] Building Formalism.PeriodIntegrals.InfTypeChar (1.6s)
error: resource exhausted (error code: 28, no space left on device)
```

服务器原始日志位于 `~/riemann-lean-verification.6wrVzm/slurm-157166.log`。
