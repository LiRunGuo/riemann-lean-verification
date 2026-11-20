# Riemann hypothesis Lean verification

Independent reproduction of the Lean formalization linked in [Levent Alpöge's announcement](https://alpo.ge/remark.pdf). The announcement claims the Riemann hypothesis (RH) and generalized Riemann hypothesis (GRH).

## Progress

- 2026-11-20 (America/Chicago): Matched the local announcement to the publisher's PDF by SHA-256.
- Downloaded `lean.tar.gz.part01` through `lean.tar.gz.part14` from `https://alpo.ge/` on `yokota_runguoli`. Recorded the hashes in [evidence/archive.sha256](evidence/archive.sha256) and successfully listed the concatenated gzip/tar archive (175,190 entries).
- Lean verification is in progress. A completed run must identify the checked statements and their transitive axioms.

The hashes identify the copies used for this run.
