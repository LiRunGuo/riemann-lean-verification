import Development.AutomorphicArithmetic.CharacterBoxes.ClaimStrip
import Formalism.GammaFactorNonvanishing.RhOfRight
import Development.AutomorphicArithmetic.PrimitiveCosets.Imports

set_option warningAsError true

-- The analytic deduction is independent of the arithmetic argument for its bound.
example (h : Claim.HalfPlane) : RiemannHypothesis := Claim.zeta h
example (h : Claim.HalfPlane) :
    ∀ (N : ℕ) [NeZero N] (χ : DirichletCharacter ℂ N) (s : ℂ),
      0 < s.re → s.re < 1 → DirichletCharacter.LFunction χ s = 0 → s.re = 1 / 2 :=
  Claim.strip h

#print axioms Claim.factor_ne_zero
#print axioms Claim.prim_reflect
#print axioms Claim.strip
#print axioms Claim.zeta
#print axioms Formalism.VW.rh_of_right
#print axioms Deduction.zeroFree_of_rpow_window
#print axioms UpperTheory.Comparison₂.formB
