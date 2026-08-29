#' Define a SRIvidhya project stratum
#'
#' Creates an auditable \code{srividhya_stratum} object combining identifying
#' metadata with four parameter groups: root parameters, percolation
#' parameters, safety parameters, and soil-organic-carbon (SOC) parameters.
#' A stratum is defined by cultivar, establishment method, soil profile,
#' irrigation setting, and materially relevant management conditions, per the
#' SRIvidhya framework specification. No scientifically sensitive parameter
#' is given a package default; every value must be supplied explicitly with
#' an evidence tier.
#'
#' @param stratum_id Character. Unique stratum identifier.
#' @param cultivar Character. Cultivar or variety name.
#' @param establishment_method Character, e.g. "transplanted" or
#'   "direct_seeded".
#' @param soil_profile_id Character. Identifier linking to a soil profile
#'   description.
#' @param irrigation_setting Character. Description of irrigation
#'   delivery/reliability context.
#' @param management_notes Character. Free-text notes on materially relevant
#'   management conditions (e.g. residue incorporation, salinity status).
#' @param root_parameters List with elements \code{R_max_cm} (required),
#'   one of \code{R0_cm} or \code{t50_dat} (required), \code{k_day_inv}
#'   (required), \code{evidence_tier} (required), and optionally
#'   \code{evidence_source}, \code{uncertainty_distribution}.
#' @param percolation_parameters List with either a constant \code{P_cm_h}
#'   or paired vectors \code{depth_cm}/\code{rate_cm_h} describing a
#'   depth-dependent decline rate, plus \code{evidence_tier} (required) and
#'   optionally \code{evidence_source}.
#' @param safety_parameters List with elements \code{alpha}, \code{D_max_cm},
#'   \code{verification_rule} (one of "depth_only", "tension_only", "either",
#'   "both"), \code{psi_threshold_kpa} (required unless
#'   \code{verification_rule = "depth_only"}), and \code{evidence_tier}.
#' @param soc_parameters List with elements \code{SOC_g_kg},
#'   \code{f_low_events_season}, \code{f_high_events_season}, and
#'   \code{evidence_tier}.
#' @param created_at POSIXct. Defaults to the current system time.
#'
#' @return An object of class \code{srividhya_stratum}: a list containing the
#'   supplied metadata and parameter groups, each retaining its evidence
#'   tier for downstream auditing.
#'
#' @export
srividhya_define_stratum <- function(stratum_id,
                                      cultivar,
                                      establishment_method,
                                      soil_profile_id,
                                      irrigation_setting,
                                      management_notes = NA_character_,
                                      root_parameters,
                                      percolation_parameters,
                                      safety_parameters,
                                      soc_parameters,
                                      created_at = Sys.time()) {

  if (missing(stratum_id) || !is.character(stratum_id) ||
      length(stratum_id) != 1L || is.na(stratum_id) || stratum_id == "") {
    stop("srividhya: 'stratum_id' must be a single non-empty character value.",
         call. = FALSE)
  }
  for (nm in c("cultivar", "establishment_method", "soil_profile_id",
               "irrigation_setting")) {
    val <- get(nm)
    if (!is.character(val) || length(val) != 1L || is.na(val) || val == "") {
      stop(sprintf("srividhya: '%s' must be a single non-empty character value.",
                    nm), call. = FALSE)
    }
  }

  srividhya_validate_parameters(
    root_parameters = root_parameters,
    percolation_parameters = percolation_parameters,
    safety_parameters = safety_parameters,
    soc_parameters = soc_parameters
  )

  stratum <- list(
    stratum_id = stratum_id,
    cultivar = cultivar,
    establishment_method = establishment_method,
    soil_profile_id = soil_profile_id,
    irrigation_setting = irrigation_setting,
    management_notes = management_notes,
    created_at = created_at,
    root_parameters = root_parameters,
    percolation_parameters = percolation_parameters,
    safety_parameters = safety_parameters,
    soc_parameters = soc_parameters
  )
  class(stratum) <- "srividhya_stratum"
  stratum
}

#' @export
print.srividhya_stratum <- function(x, ...) {
  cat("<srividhya_stratum>\n")
  cat(" stratum_id:           ", x$stratum_id, "\n")
  cat(" cultivar:             ", x$cultivar, "\n")
  cat(" establishment_method: ", x$establishment_method, "\n")
  cat(" soil_profile_id:      ", x$soil_profile_id, "\n")
  cat(" irrigation_setting:   ", x$irrigation_setting, "\n")
  tiers <- c(
    root = x$root_parameters$evidence_tier,
    percolation = x$percolation_parameters$evidence_tier,
    safety = x$safety_parameters$evidence_tier,
    soc = x$soc_parameters$evidence_tier
  )
  cat(" evidence tiers:\n")
  for (i in seq_along(tiers)) {
    flag <- if (identical(tiers[[i]], "provisional_default")) "  [PROVISIONAL]" else ""
    cat(sprintf("   %-12s %s%s\n", names(tiers)[i], tiers[[i]], flag))
  }
  invisible(x)
}

#' Check whether any parameter group in a stratum is provisional
#'
#' @param stratum A \code{srividhya_stratum} object.
#'
#' @return Character vector of parameter-group names with
#'   \code{evidence_tier == "provisional_default"}; empty if none.
#' @export
srividhya_provisional_groups <- function(stratum) {
  if (!inherits(stratum, "srividhya_stratum")) {
    stop("srividhya: 'stratum' must be a srividhya_stratum object.",
         call. = FALSE)
  }
  groups <- c("root_parameters", "percolation_parameters",
              "safety_parameters", "soc_parameters")
  tiers <- vapply(groups, function(g) stratum[[g]]$evidence_tier %||% NA_character_,
                   character(1))
  groups[!is.na(tiers) & tiers == "provisional_default"]
}

`%||%` <- function(x, y) if (is.null(x)) y else x
