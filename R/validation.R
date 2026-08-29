#' Validate a numeric scalar input
#'
#' Internal helper enforcing that a supplied value is a finite, non-missing
#' numeric scalar, optionally bounded. SRIvidhya never substitutes a default
#' when validation fails; it raises an informative error instead.
#'
#' @param x Value to validate.
#' @param name Character. Name of the parameter, used in error messages.
#' @param lower Optional numeric lower bound (inclusive unless
#'   \code{lower_inclusive = FALSE}).
#' @param upper Optional numeric upper bound (inclusive unless
#'   \code{upper_inclusive = FALSE}).
#' @param lower_inclusive Logical. Whether the lower bound is inclusive.
#' @param upper_inclusive Logical. Whether the upper bound is inclusive.
#' @param allow_null Logical. If TRUE, NULL passes validation silently.
#'
#' @return Invisibly returns \code{x} if valid; otherwise throws an error.
#' @keywords internal
.validate_numeric_scalar <- function(x, name, lower = NULL, upper = NULL,
                                      lower_inclusive = TRUE,
                                      upper_inclusive = TRUE,
                                      allow_null = FALSE) {
  if (is.null(x)) {
    if (allow_null) return(invisible(x))
    stop(sprintf("srividhya: '%s' is required and must not be NULL.", name),
         call. = FALSE)
  }
  if (!is.numeric(x) || length(x) != 1L) {
    stop(sprintf("srividhya: '%s' must be a single numeric value.", name),
         call. = FALSE)
  }
  if (is.na(x) || !is.finite(x)) {
    stop(sprintf("srividhya: '%s' must be a finite, non-missing numeric value.",
                 name), call. = FALSE)
  }
  if (!is.null(lower)) {
    ok <- if (lower_inclusive) x >= lower else x > lower
    if (!ok) {
      stop(sprintf("srividhya: '%s' must be %s %s (got %s).",
                    name, if (lower_inclusive) ">=" else ">", lower, x),
           call. = FALSE)
    }
  }
  if (!is.null(upper)) {
    ok <- if (upper_inclusive) x <= upper else x < upper
    if (!ok) {
      stop(sprintf("srividhya: '%s' must be %s %s (got %s).",
                    name, if (upper_inclusive) "<=" else "<", upper, x),
           call. = FALSE)
    }
  }
  invisible(x)
}

#' Valid evidence tiers recognized by SRIvidhya
#'
#' @return Character vector of the five ordered evidence tiers.
#' @export
srividhya_evidence_tiers <- function() {
  c("measured_local", "published_comparable", "breeder_or_extension",
    "project_prior", "provisional_default")
}

#' Validate an evidence tier string
#'
#' @param tier Character scalar. Must be one of
#'   \code{srividhya_evidence_tiers()}.
#' @param name Character. Name of the parameter group, used in error messages.
#'
#' @return Invisibly returns \code{tier} if valid; otherwise throws an error.
#' @keywords internal
.validate_evidence_tier <- function(tier, name) {
  valid <- srividhya_evidence_tiers()
  if (is.null(tier) || !is.character(tier) || length(tier) != 1L ||
      !(tier %in% valid)) {
    stop(sprintf(
      "srividhya: evidence_tier for '%s' must be one of: %s (got: %s).",
      name, paste(valid, collapse = ", "),
      if (is.null(tier)) "NULL" else as.character(tier)
    ), call. = FALSE)
  }
  invisible(tier)
}

#' Validate a set of stratum parameters
#'
#' Checks internal consistency of the parameter groups used to define a
#' SRIvidhya project stratum: root parameters, percolation parameters,
#' safety parameters, and soc parameters. This function does not fabricate
#' any missing values; it only validates what is supplied.
#'
#' @param root_parameters List. See \code{srividhya_define_stratum()}.
#' @param percolation_parameters List. See \code{srividhya_define_stratum()}.
#' @param safety_parameters List. See \code{srividhya_define_stratum()}.
#' @param soc_parameters List. See \code{srividhya_define_stratum()}.
#'
#' @return Invisibly \code{TRUE} if all supplied parameters are valid.
#' @export
srividhya_validate_parameters <- function(root_parameters = NULL,
                                           percolation_parameters = NULL,
                                           safety_parameters = NULL,
                                           soc_parameters = NULL) {

  if (!is.null(root_parameters)) {
    rp <- root_parameters
    .validate_numeric_scalar(rp$R_max_cm, "root_parameters$R_max_cm", lower = 0,
                              lower_inclusive = FALSE)
    if (!is.null(rp$R0_cm)) {
      .validate_numeric_scalar(rp$R0_cm, "root_parameters$R0_cm", lower = 0,
                                lower_inclusive = FALSE)
      if (!is.null(rp$R_max_cm) && rp$R0_cm >= rp$R_max_cm) {
        stop("srividhya: root_parameters$R0_cm must be < R_max_cm.",
             call. = FALSE)
      }
    }
    if (!is.null(rp$t50_dat)) {
      .validate_numeric_scalar(rp$t50_dat, "root_parameters$t50_dat", lower = 0)
    }
    if (is.null(rp$R0_cm) && is.null(rp$t50_dat)) {
      stop("srividhya: root_parameters must include either 'R0_cm' or ",
           "'t50_dat' to define the root-depth trajectory.", call. = FALSE)
    }
    .validate_numeric_scalar(rp$k_day_inv, "root_parameters$k_day_inv",
                              lower = 0, lower_inclusive = FALSE)
    .validate_evidence_tier(rp$evidence_tier, "root_parameters")
  }

  if (!is.null(percolation_parameters)) {
    pp <- percolation_parameters
    has_constant <- !is.null(pp$P_cm_h)
    has_curve <- !is.null(pp$depth_cm) && !is.null(pp$rate_cm_h)
    if (!has_constant && !has_curve) {
      stop("srividhya: percolation_parameters must include either a ",
           "constant 'P_cm_h' or paired 'depth_cm'/'rate_cm_h' vectors.",
           call. = FALSE)
    }
    if (has_constant) {
      .validate_numeric_scalar(pp$P_cm_h, "percolation_parameters$P_cm_h",
                                lower = 0, lower_inclusive = FALSE)
    }
    if (has_curve) {
      if (length(pp$depth_cm) != length(pp$rate_cm_h)) {
        stop("srividhya: percolation_parameters$depth_cm and rate_cm_h ",
             "must have equal length.", call. = FALSE)
      }
      if (any(!is.finite(pp$depth_cm)) || any(!is.finite(pp$rate_cm_h))) {
        stop("srividhya: percolation_parameters depth/rate observations ",
             "must be finite, non-missing values.", call. = FALSE)
      }
      if (any(pp$rate_cm_h <= 0)) {
        stop("srividhya: percolation_parameters$rate_cm_h values must all ",
             "be > 0.", call. = FALSE)
      }
      if (is.unsorted(pp$depth_cm)) {
        stop("srividhya: percolation_parameters$depth_cm must be sorted ",
             "in increasing order.", call. = FALSE)
      }
    }
    .validate_evidence_tier(pp$evidence_tier, "percolation_parameters")
  }

  if (!is.null(safety_parameters)) {
    sp <- safety_parameters
    .validate_numeric_scalar(sp$alpha, "safety_parameters$alpha",
                              lower = 0, upper = 1)
    .validate_numeric_scalar(sp$D_max_cm, "safety_parameters$D_max_cm",
                              lower = 0, lower_inclusive = FALSE)
    valid_rules <- c("depth_only", "tension_only", "either", "both")
    if (is.null(sp$verification_rule) ||
        !(sp$verification_rule %in% valid_rules)) {
      stop(sprintf(
        "srividhya: safety_parameters$verification_rule must be one of: %s.",
        paste(valid_rules, collapse = ", ")), call. = FALSE)
    }
    if (sp$verification_rule %in% c("tension_only", "either", "both")) {
      .validate_numeric_scalar(sp$psi_threshold_kpa,
                                "safety_parameters$psi_threshold_kpa")
    }
    .validate_evidence_tier(sp$evidence_tier, "safety_parameters")
  }

  if (!is.null(soc_parameters)) {
    scp <- soc_parameters
    .validate_numeric_scalar(scp$SOC_g_kg, "soc_parameters$SOC_g_kg",
                              lower = 0, lower_inclusive = FALSE)
    .validate_numeric_scalar(scp$f_low_events_season,
                              "soc_parameters$f_low_events_season", lower = 0)
    .validate_numeric_scalar(scp$f_high_events_season,
                              "soc_parameters$f_high_events_season", lower = 0)
    if (scp$f_high_events_season < scp$f_low_events_season) {
      stop("srividhya: soc_parameters$f_high_events_season should not be ",
           "lower than f_low_events_season. Verify calibration direction.",
           call. = FALSE)
    }
    .validate_evidence_tier(scp$evidence_tier, "soc_parameters")
  }

  invisible(TRUE)
}
