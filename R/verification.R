#' Verify a drainage event against a configurable rule
#'
#' Applies project-configurable drainage-verification logic combining
#' water-table depth and/or soil-water potential, and optionally reports an
#' independent redox diagnostic. SRIvidhya treats redox potential as a
#' diagnostic validation signal, not a universal operational field
#' threshold.
#'
#' @param rule Character. One of \code{"depth_only"}, \code{"tension_only"},
#'   \code{"either"}, \code{"both"}.
#' @param water_table_depth_cm Numeric or \code{NA}. Measured water-table
#'   depth (cm below soil surface). Required unless \code{rule =
#'   "tension_only"}.
#' @param safe_depth_ceiling_cm Numeric. Target safe depth ceiling (cm).
#'   Required unless \code{rule = "tension_only"}.
#' @param psi_kpa Numeric or \code{NA}. Measured soil-water potential (kPa).
#'   Required unless \code{rule = "depth_only"}.
#' @param psi_threshold_kpa Numeric. Locally calibrated soil-water-potential
#'   verification trigger (kPa). Required unless \code{rule = "depth_only"}.
#' @param Eh_mV Numeric or \code{NA}. Optional measured soil redox potential
#'   (mV), used only for diagnostic reporting.
#' @param Eh_meth_mV Numeric. Diagnostic reference redox potential (mV).
#'   If not supplied, redox diagnostics are omitted.
#'
#' @return A list with elements: \code{status}, \code{rule},
#'   \code{depth_condition}, \code{tension_condition}, and
#'   \code{redox_diagnostic}.
#'
#' @export
srividhya_verify_drainage <- function(rule = c("depth_only", "tension_only",
                                                "either", "both"),
                                       water_table_depth_cm = NA_real_,
                                       safe_depth_ceiling_cm = NA_real_,
                                       psi_kpa = NA_real_,
                                       psi_threshold_kpa = NA_real_,
                                       Eh_mV = NA_real_,
                                       Eh_meth_mV = NULL) {

  rule <- match.arg(rule)
  needs_depth <- rule %in% c("depth_only", "either", "both")
  needs_tension <- rule %in% c("tension_only", "either", "both")

  depth_condition <- NA
  tension_condition <- NA

  if (needs_depth) {
    if (is.na(water_table_depth_cm) || is.na(safe_depth_ceiling_cm)) {
      warning("srividhya: depth-based verification requires ",
              "'water_table_depth_cm' and 'safe_depth_ceiling_cm'; ",
              "returning NA depth_condition.", call. = FALSE)
    } else {
      depth_condition <- water_table_depth_cm >= safe_depth_ceiling_cm
    }
  }

  if (needs_tension) {
    if (is.na(psi_kpa) || is.na(psi_threshold_kpa)) {
      warning("srividhya: tension-based verification requires 'psi_kpa' ",
              "and 'psi_threshold_kpa'; returning NA tension_condition.",
              call. = FALSE)
    } else {
      tension_condition <- psi_kpa <= psi_threshold_kpa
    }
  }

  status <- switch(rule,
    depth_only = depth_condition,
    tension_only = tension_condition,
    either = {
      if (is.na(depth_condition) && is.na(tension_condition)) NA
      else isTRUE(depth_condition) || isTRUE(tension_condition)
    },
    both = {
      if (is.na(depth_condition) || is.na(tension_condition)) NA
      else depth_condition && tension_condition
    }
  )

  redox_diagnostic <- "not_evaluated"
  if (!is.null(Eh_meth_mV) && !is.na(Eh_mV)) {
    redox_diagnostic <- if (Eh_mV < Eh_meth_mV) "below_threshold" else "at_or_above_threshold"
  }

  list(
    status = status,
    rule = rule,
    depth_condition = depth_condition,
    tension_condition = tension_condition,
    redox_diagnostic = redox_diagnostic
  )
}
