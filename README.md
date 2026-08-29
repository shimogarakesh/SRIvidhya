# SRIvidhya (R package: `srividhya`)

**SRIvidhya** is an open, research-grade R package implementing a proposed
site-adaptive alternate wetting and drying (AWD) decision-support and
monitoring, reporting, and verification (MRV) framework for irrigated rice.
The installable R package is named `srividhya`; load it in R with
`library(srividhya)`.

SRIvidhya operationalizes the site-adaptive AWD algorithm described in
Tiwari et al., *Site-specific water management for credible rice methane
credits* (commentary manuscript). It replaces a single universal AWD
water-table depth with transparent, locally calibrated functions that
generate a stratum- and crop-specific water-level calendar.

## What SRIvidhya is

- A decision-support tool for generating locally calibrated AWD
  recommendations.
- A monitoring, reporting, and verification (MRV) aid that keeps parameter
  provenance, evidence tiers, and uncertainty visible.
- A transparent implementation of root-development, percolation, drainage
  verification, and soil-organic-carbon-scaled frequency logic.

## What SRIvidhya is not

- Not a universal methane emission-factor model.
- Not an autonomous carbon-credit calculator or registry adapter.
- Not a replacement for direct greenhouse-gas measurement where feasible.
- Not a source of default scientific parameter values. `R_max`, `R0`, `k`,
  `t50`, `alpha`, `D_max`, `psi_threshold`, `f_low`, and `f_high` must always
  be supplied by the user, tagged with an evidence tier, and treated as
  provisional until locally calibrated.

## The three questions SRIvidhya separates

1. **How far may the field safely drain today?**
   Governed by current active root depth and a locally calibrated agronomic
   ceiling (`srividhya_safe_depth()`).
2. **How long will it take to reach that depth?**
   Governed by profile-representative water-table decline, not a generic
   soil-texture label (`srividhya_time_to_target()`).
3. **How frequently should drainage recur?**
   Governed initially by SOC-scaled local calibration
   (`srividhya_soc_frequency()`), extensible to methane, weather, and
   management covariates in later versions.

## Installation (development)

```r
# install.packages("devtools")
devtools::install_github("shimogarakesh/srividhya")
```

## Minimal example

```r
library(srividhya)

stratum <- srividhya_define_stratum(
  stratum_id = "SYNTHETIC_A",
  cultivar = "Synthetic cultivar (example only)",
  establishment_method = "transplanted",
  soil_profile_id = "SYNTHETIC_PROFILE",
  irrigation_setting = "controlled irrigation",
  management_notes = "Synthetic example; not calibration data.",
  root_parameters = list(
    R_max_cm = 30, R0_cm = 3, k_day_inv = 0.12,
    evidence_tier = "provisional_default",
    evidence_source = "Synthetic demonstration only"
  ),
  percolation_parameters = list(
    P_cm_h = 0.42,
    evidence_tier = "provisional_default",
    evidence_source = "Synthetic demonstration only"
  ),
  safety_parameters = list(
    alpha = 0.50, D_max_cm = 12, psi_threshold_kpa = -20,
    verification_rule = "either",
    evidence_tier = "provisional_default"
  ),
  soc_parameters = list(
    SOC_g_kg = 15, f_low_events_season = 3, f_high_events_season = 6,
    evidence_tier = "provisional_default"
  )
)

calendar <- srividhya_generate_calendar(stratum, dat_seq = 20:40)
head(calendar)
```

Every value in this example is synthetic and explicitly labelled
`provisional_default`. Do not use it as agronomic guidance.

## Evidence tiers

Every scientifically sensitive parameter carries one of:

1. `measured_local`
2. `published_comparable`
3. `breeder_or_extension`
4. `project_prior`
5. `provisional_default`

Any calculation touching a `provisional_default` parameter returns a visible
warning and a recommended calibration action.

## Status

v0.1.0 implements the deterministic core of the SRIvidhya framework:
root-depth trajectory, root-safe drainage ceiling, time-to-target (constant
and depth-dependent percolation), dual depth/tension verification,
SOC-scaled frequency, and a stratum-level calendar generator. Root/percolation
curve fitting, Monte Carlo uncertainty propagation, and machine-readable
audit-log serialization are planned for subsequent milestones.

## License

MIT. See `LICENSE`.

## Citation

Tiwari, R., Pattanayak, K.C., Basavaraju, Y., & Kambalagere, Y.
*Site-specific water management for credible rice methane credits.*
Commentary manuscript.
