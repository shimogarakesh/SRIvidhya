---
title: 'SRIvidhya: an R package for site-adaptive alternate wetting and drying decision support in rice'
tags:
  - R
  - agronomy
  - rice
  - methane
  - irrigation
  - carbon markets
authors:
  - name: Rakesh Tiwari
    orcid: 0000-0002-2191-769X
    corresponding: true
    affiliation: "1, 2, 3"
  - name: Kanhu Charan Pattanayak
    orcid: 0000-0001-9589-8789
    affiliation: "4"
  - name: Yashwanth Basavaraju
    orcid: 0009-0005-2763-1579
    affiliation: "2"
  - name: Yogendra Kambalagere
    orcid: 0000-0001-8652-8444
    affiliation: "3"
affiliations:
  - index: 1
    name: Plant Ecology and Evolution, Uppsala Universitet, Sweden
  - index: 2
    name: Bharati Environment and Sustainable Technology Solutions Pvt. Ltd., Tumakuru, India
  - index: 3
    name: Department of PG Studies and Research in Environmental Science, Kuvempu University, Shivamogga, India
  - index: 4
    name: climaTRACES Lab, University of Cambridge, Cambridge, United Kingdom
date: 30 August 2026
bibliography: paper.bib
---

# Summary

Alternate wetting and drying (AWD) is a rice water-management practice that periodically drains
paddy fields to suppress methane-producing soil bacteria, and it has become a central instrument
in voluntary and compliance carbon markets for crediting agricultural methane reductions
[@lampayan2015; @wang2023]. Most operational AWD guidance specifies a single water-table depth
threshold applied uniformly regardless of soil texture, crop developmental stage, varietal rooting
depth, or soil organic carbon content [@cdm2014; @goldstandard2023; @isometric2026; @verra2024].
`SRIvidhya` is an open-source R package that provides computational tooling for a proposed
site-adaptive alternative to that fixed-threshold approach: a set of transparent, locally
calibrated functions that generate a stratum- and crop-specific water-level calendar in place of a
universal depth constant. The package computes a continuously updated, root-development-aware safe
drainage depth, a profile-representative time-to-target estimate under either constant or
depth-dependent percolation, a configurable dual depth/tension verification rule, and a
soil-organic-carbon-scaled drainage-event frequency, and it converts these calculations into both
a machine-readable monitoring, reporting, and verification (MRV) record and a simplified
farmer-facing instruction. `SRIvidhya` is explicitly designed as a decision-support and MRV tool,
not as a validated emission-factor model, an autonomous carbon-credit calculator, or a substitute
for direct greenhouse-gas measurement.

# Statement of need

Translating agronomic and microbial mechanisms into a single operational drainage rule is
difficult in practice: percolation behaviour, root development, and methanogen dynamics each
depend on locally measurable quantities, but most published guidance and crediting documentation
expresses them as fixed constants rather than as functions of field conditions
[@lampayan2015; @carrijo2017; @zhao2024]. A companion commentary by the same author group examines
this gap in detail from an agronomic and carbon-market perspective, proposing a site-adaptive
decision algorithm that ties permissible drainage depth to current root depth, ties drawdown
timing to a locally measured percolation profile, and ties drainage frequency to measured soil
organic carbon [@tiwari_commentary]. `SRIvidhya` exists to give that proposed algorithm a concrete,
inspectable, and reusable software form: a researcher or project developer should not have to
reimplement logistic root-growth curves, nonlinear percolation integration, or bounded
SOC-frequency interpolation from a manuscript's equations each time the framework is applied to a
new stratum.

No open-source R package currently provides this specific combination -- a locally calibrated,
evidence-tiered, per-stratum AWD scheduling engine with explicit warnings when provisional
parameter values are in use -- to the authors' knowledge. `SRIvidhya` fills that tooling gap by
separating three computations that a fixed-threshold rule conflates into one number: how far a
field may safely drain today, given current root development; how long that target will take to
reach, given a profile-representative percolation measurement rather than a generic soil-texture
label; and how frequently drainage should recur, given locally observed soil organic carbon
[@sass1994; @zhao2024]. The intended audience includes rice methane-mitigation researchers testing
or extending the underlying algorithm, carbon-project developers who need an auditable
implementation for MRV purposes, and agricultural extension programs producing farmer-facing
irrigation calendars.

# State of the field

Software support for rice water-management scheduling is generally split between two categories,
neither of which covers what `SRIvidhya` implements. The first is crop- and field-scale
water-balance simulation software and R packages, which model evapotranspiration, seepage, and
irrigation scheduling in considerable process detail [@bouman2001] but are not built around the
specific joint parameterization of root-safe drainage depth, percolation-derived time-to-target,
and organic-carbon-scaled event frequency that AWD carbon-crediting protocols require. The second
is the quantification tooling embedded in individual carbon-crediting methodologies themselves
(e.g., DNDC-based emission-factor models), which are typically proprietary, methodology-specific,
and oriented toward retrospective emissions accounting rather than forward-looking, farmer-facing
scheduling. Neither category exposes a stratum-level, root-development-aware drainage calendar as
a general-purpose, open, and independently testable computational object.

`SRIvidhya` is positioned to sit alongside, rather than replace, the first category: its outputs
(a safe depth ceiling and an expected time-to-target) are natural inputs to a more detailed
water-balance model, and future versions are intended to accept evapotranspiration and effective
rainfall as additional covariates on the time-to-target calculation. Relative to the second
category, `SRIvidhya` deliberately does not attempt emissions quantification at all; it returns a
drainage-timing and verification schedule only, leaving methane-reduction quantification to
registry-approved methodologies and direct measurement where feasible. This separation of concerns
-- an open, auditable scheduling engine that is agnostic to any particular crediting methodology's
accounting rules -- is, to the authors' knowledge, not currently available as reusable open-source
software.

# Software design

`SRIvidhya` is implemented as a lightweight R package with a single non-base dependency (`stats`,
for interpolation) to keep the computational core auditable line by line. The package follows five
design principles:

1. **No hidden defaults.** Scientifically sensitive parameters -- maximum rooting depth (`R_max`),
   root growth-rate (`k`), the root-safety margin (`alpha`), the agronomic drainage ceiling
   (`D_max`), the soil-water-potential verification threshold, and the soil-organic-carbon
   frequency anchors (`f_low`, `f_high`) -- are never assigned package-level default values.
   `srividhya_define_stratum()` and its internal validator, `srividhya_validate_parameters()`,
   raise an explicit error if any of these are omitted, and require every parameter group to carry
   one of five ordered evidence tiers (`measured_local`, `published_comparable`,
   `breeder_or_extension`, `project_prior`, `provisional_default`).
2. **Explicit provisional-value warnings.** Any downstream calculation that depends on a
   `provisional_default` parameter propagates a visible warning and a recommended calibration
   action into the returned calendar object, rather than silently returning a numeric result
   indistinguishable from a locally calibrated one.
3. **No collapse of nonlinear observations.** `srividhya_time_to_target()` supports both a
   constant percolation rate and a depth-dependent percolation curve fitted from repeated
   perforated-tube observations, and evaluates the depth-dependent case by numerical (trapezoidal)
   integration of the inverse rate curve rather than approximating it with a single averaged rate.
4. **Configurable, falsifiable verification.** `srividhya_verify_drainage()` implements four
   user-selectable verification rules (`depth_only`, `tension_only`, `either`, `both`), and treats
   an optional soil redox potential input as a diagnostic signal only, never as a silent override
   of the primary verification outcome [@masscheleyn1993].
5. **Separation of scientific engine and farmer-facing output.** `srividhya_generate_calendar()`
   returns a fully annotated, machine-readable data frame suitable for monitoring, reporting, and
   verification (MRV) auditing, while `srividhya_farmer_instruction()` renders a single calendar
   row into a short, plain-language field instruction, keeping the parameterization burden at the
   project-stratum level rather than the individual-farmer level.

The package is organized with one function per file under `R/` (`roots.R`, `drainage_ceiling.R`,
`percolation.R`, `verification.R`, `soc_frequency.R`, `calendar.R`, `farmer_instruction.R`,
`strata.R`, `validation.R`), uses `roxygen2` for documentation [@roxygen2024], and is tested with
`testthat`, with unit tests covering ordinary, boundary, missing-data, nonlinear-percolation, and
provisional-warning cases [@wickham2011]. All example and test data are explicitly labelled
synthetic and are not derived from field measurement.

# Function reference

`srividhya` v0.1 exports nine functions, summarized in Table 1. A stratum is defined and validated
first, then root depth, safe depth, time-to-target, verification, and SOC-scaled frequency are
computed per day-after-transplanting (DAT), and finally these are assembled into a calendar and
rendered as a farmer instruction.

Table: Exported functions in `srividhya` v0.1.

| Function | Purpose | Returns |
|---|---|---|
| `srividhya_define_stratum()` | Creates an auditable stratum object combining identifying metadata with four evidence-tiered parameter groups | `srividhya_stratum` object |
| `srividhya_validate_parameters()` | Internal validator checking units, required fields, and evidence-tier membership | Invisibly `TRUE`, or error |
| `srividhya_root_depth()` | Logistic root-depth trajectory $R(t)$ | Numeric vector (cm) |
| `srividhya_safe_depth()` | Root-safe drainage ceiling $D_{safe}(t)=\min(\alpha R(t), D_{max})$ | Numeric vector (cm) |
| `srividhya_time_to_target()` | Time to reach target depth, constant or depth-dependent percolation | Numeric vector (h or days) |
| `srividhya_verify_drainage()` | Configurable depth/tension verification with optional redox diagnostic | List of status/conditions |
| `srividhya_soc_frequency()` | SOC-scaled drainage-event frequency, bounded interpolation | Numeric vector |
| `srividhya_generate_calendar()` | Assembles a per-day stratum calendar | `data.frame` |
| `srividhya_farmer_instruction()` | Renders one calendar row as plain-language field guidance | Character scalar |

The root-depth trajectory follows

$$R(t) = \frac{R_{max}}{1 + \exp[-k(t - t_{50})]}$$

or, equivalently, using the root depth at transplanting $R_0$,

$$R(t) = \frac{R_{max}}{1 + A\exp(-kt)}, \quad A = \frac{R_{max}-R_0}{R_0},$$

consistent with documented S-shaped rice root elongation [@liu2018; @yang2022]. The root-safe
drainage ceiling is the more restrictive of a root-safety fraction and a locally accepted
agronomic maximum, $D_{safe}(t) = \min\{\alpha R(t), D_{max}\}$, so that at transplanting
($R(t)\approx 0$) drainage is continuously limited rather than categorically forbidden, consistent
with the documented sensitivity of rice yield to root disturbance during the establishment window
[@lee2021; @rahman2013]. Time-to-target is computed as $t^*(t) = D_{safe}(t)/P$ for a constant
percolation rate $P$, or by trapezoidal integration of $1/P(d)$ over $[0, D_{safe}(t)]$ for a
depth-dependent rate fitted from repeated perforated-tube observations, avoiding the collapse of a
nonlinear percolation profile -- for example one containing a compacted plough pan -- into a
single misleading average rate. Drainage verification supports `depth_only`, `tension_only`,
`either`, and `both` rules, combining `water_table_depth_cm >= safe_depth_ceiling_cm` and/or
`psi_kpa <= psi_threshold_kpa` as configured. Seasonal drainage-event frequency follows a bounded,
first-order interpolation between soil-organic-carbon anchors of 12 and 18 g kg$^{-1}$ reported by
@zhao2024, and always carries a `"provisional"` attribute noting that the interpolation is
illustrative rather than a fitted universal response.

# Installation and usage

```r
# install.packages("devtools")
devtools::install_github("shimogarakesh/srividhya")
library(srividhya)

stratum <- srividhya_define_stratum(
  stratum_id = "SYNTHETIC_A",
  cultivar = "Synthetic cultivar (example only)",
  establishment_method = "transplanted",
  soil_profile_id = "SYNTHETIC_PROFILE_CLAY",
  irrigation_setting = "controlled irrigation",
  management_notes = "Synthetic example; not calibration data.",
  root_parameters = list(R_max_cm = 30, R0_cm = 3, k_day_inv = 0.12,
                          evidence_tier = "provisional_default"),
  percolation_parameters = list(P_cm_h = 0.18,
                                 evidence_tier = "provisional_default"),
  safety_parameters = list(alpha = 0.50, D_max_cm = 12,
                            psi_threshold_kpa = -20,
                            verification_rule = "either",
                            evidence_tier = "provisional_default"),
  soc_parameters = list(SOC_g_kg = 15, f_low_events_season = 3,
                         f_high_events_season = 6,
                         evidence_tier = "provisional_default")
)

calendar <- srividhya_generate_calendar(stratum, dat_seq = 20:40)
cat(srividhya_farmer_instruction(calendar[calendar$DAT == 35, ]))
```

Every value in this example is synthetic and tagged `"provisional_default"`; each downstream
calculation therefore propagates a visible warning recommending local calibration before any field
use, rather than returning a numeric result indistinguishable from a locally measured one.

# Figures

```{=latex}
\begin{figure}[htbp]
\centering
\includegraphics[width=0.95\textwidth]{figures/srividhya_synthetic_calendar_plot.png}
\caption{SRIvidhya synthetic-stratum diagnostic plot. Top panel: effective root depth $R(t)$
(green) and the resulting safe drainage ceiling $D_{safe}(t) = \min(\alpha R(t), D_{max})$ (blue,
shaded) against days after transplanting (DAT), for the package's bundled synthetic stratum
($R_{max}=30$ cm, $R_0=3$ cm, $k=0.12$ day$^{-1}$, $\alpha=0.5$, $D_{max}=12$ cm). The dashed red
line marks the agronomic ceiling $D_{max}$; the dotted vertical line marks DAT 30, the day on
which the fixed ceiling first becomes more restrictive than the root-safety fraction and takes
over as the governing constraint. Bottom panel: expected time to reach the safe depth ceiling
under a constant percolation rate ($P = 0.18$ cm h$^{-1}$), in hours (left axis) and days (right
axis). Both panels use provisional-default synthetic parameters and illustrate the package's
output structure only; they do not represent a calibrated or field-validated recommendation.}
\label{fig:calendar}
\end{figure}
```

The two-panel structure in Figure \ref{fig:calendar} is produced directly by the two governing
equations of the package: the root-safety/agronomic-ceiling constraint and the time-to-target
integral. The switch from a root-limited to a ceiling-limited regime around DAT 30 illustrates why
a single fixed depth threshold cannot be biologically appropriate across the full growing season
for this stratum: the same 12 cm target that is safely reachable from DAT 30 onward would have
exposed roots to drawdown beyond the locally calibrated safety margin $\alpha$ had it been applied
during the first three weeks after transplanting.

# Research impact statement

`srividhya` provides a reference software implementation of the site-adaptive AWD algorithm
proposed in a companion commentary by the same author group [@tiwari_commentary]; readers seeking
the underlying agronomic and carbon-market argument for site-adaptive drainage scheduling should
consult that manuscript, while this paper documents the software that operationalizes it. The
package is intended to make the proposed algorithm directly testable and reusable in practice:
project developers can instantiate a stratum with locally measured parameters and evidence tiers,
generate an auditable calendar, and compare recommended drainage timing against fixed-threshold
baselines. As a v0.1 release, the package does not yet have external citing publications; its
research contribution at this stage is the availability of a fully reproducible, unit-tested
reference implementation, released alongside the manuscript that motivates it, so that reviewers,
replicators, and downstream implementers can inspect and extend the exact computational logic
rather than reimplementing it from prose.

# AI usage disclosure

The `srividhya` R package source code, tests, and package scaffold were drafted with the
assistance of a conversational AI system (Perplexity) under direct specification, iterative
review, and correction by the corresponding author, following an explicit written build brief that
prohibited the AI from inventing empirical default values for any scientifically sensitive
parameter. Each function's behaviour was checked against hand-derived numerical examples before
being committed to the package repository. This manuscript's prose was likewise drafted with AI
assistance and subsequently reviewed by the authors.

# Acknowledgements

RT thanks the Wenner-Gren and Birgitta Sintring Foundations and the Swedish Vegetation Society for
postdoctoral funding at Uppsala. RT thanks Shāradā-Chandramaulishwara and Ubhaya Jagathgurus of
Sringeri for their guidance.

# References
