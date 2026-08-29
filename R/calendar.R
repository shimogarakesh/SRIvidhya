#' Generate a SRIvidhya water-level calendar for a stratum
#'
#' Combines the root-depth trajectory, root-safe drainage ceiling,
#' time-to-target, and SOC-scaled frequency functions into a per-day
#' technical calendar for a given \code{srividhya_stratum}. No methane
#' emission, yield, or credit quantity is calculated or implied.
#'
#' @param stratum A \code{srividhya_stratum} object.
#' @param dat_seq Numeric vector of days after transplanting.
#' @param start_date Date or character coercible to Date, or \code{NULL}.
#' @param water_table_depth_cm Optional numeric vector, same length as
#'   \code{dat_seq}.
#' @param psi_kpa Optional numeric vector, same length as \code{dat_seq}.
#' @param Eh_mV Optional numeric vector, same length as \code{dat_seq}.
#' @param Eh_meth_mV Optional numeric scalar.
#'
#' @return A \code{data.frame} with one row per element of \code{dat_seq}.
#'
#' @export
srividhya_generate_calendar <- function(stratum, dat_seq,
                                         start_date = NULL,
                                         water_table_depth_cm = NULL,
                                         psi_kpa = NULL,
                                         Eh_mV = NULL,
                                         Eh_meth_mV = NULL) {

  if (!inherits(stratum, "srividhya_stratum")) {
    stop("srividhya: 'stratum' must be a srividhya_stratum object created ",
         "by srividhya_define_stratum().", call. = FALSE)
  }
  if (!is.numeric(dat_seq) || length(dat_seq) < 1L || any(!is.finite(dat_seq))) {
    stop("srividhya: 'dat_seq' must be a numeric vector of finite values.",
         call. = FALSE)
  }
  n <- length(dat_seq)

  pad_or_check <- function(x, name) {
    if (is.null(x)) return(rep(NA_real_, n))
    if (length(x) != n) {
      stop(sprintf("srividhya: '%s' must have the same length as 'dat_seq'.",
                    name), call. = FALSE)
    }
    x
  }
  water_table_depth_cm <- pad_or_check(water_table_depth_cm, "water_table_depth_cm")
  psi_kpa <- pad_or_check(psi_kpa, "psi_kpa")
  Eh_mV <- pad_or_check(Eh_mV, "Eh_mV")

  rp <- stratum$root_parameters
  pp <- stratum$percolation_parameters
  sp <- stratum$safety_parameters
  scp <- stratum$soc_parameters

  root_depth_cm <- srividhya_root_depth(
    dat = dat_seq, R_max_cm = rp$R_max_cm, k_day_inv = rp$k_day_inv,
    t50_dat = rp$t50_dat, R0_cm = rp$R0_cm
  )
  safe_depth_ceiling_cm <- srividhya_safe_depth(
    root_depth_cm = root_depth_cm, alpha = sp$alpha, D_max_cm = sp$D_max_cm
  )

  has_curve <- !is.null(pp$depth_cm) && !is.null(pp$rate_cm_h)
  if (has_curve) {
    t_hours <- srividhya_time_to_target(
      target_depth_cm = safe_depth_ceiling_cm,
      depth_cm = pp$depth_cm, rate_cm_h = pp$rate_cm_h, units = "hours"
    )
    percolation_model <- "depth_dependent"
  } else {
    t_hours <- srividhya_time_to_target(
      target_depth_cm = safe_depth_ceiling_cm, P_cm_h = pp$P_cm_h,
      units = "hours"
    )
    percolation_model <- "constant_rate"
  }

  nominal_frequency <- srividhya_soc_frequency(
    SOC_g_kg = scp$SOC_g_kg, f_low_events_season = scp$f_low_events_season,
    f_high_events_season = scp$f_high_events_season
  )
  nominal_frequency <- rep(as.numeric(nominal_frequency), n)

  verification_status <- character(n)
  redox_diagnostic <- character(n)
  for (i in seq_len(n)) {
    v <- srividhya_verify_drainage(
      rule = sp$verification_rule,
      water_table_depth_cm = water_table_depth_cm[i],
      safe_depth_ceiling_cm = safe_depth_ceiling_cm[i],
      psi_kpa = psi_kpa[i],
      psi_threshold_kpa = sp$psi_threshold_kpa,
      Eh_mV = Eh_mV[i],
      Eh_meth_mV = Eh_meth_mV
    )
    verification_status[i] <- if (is.na(v$status)) "not_evaluated" else as.character(v$status)
    redox_diagnostic[i] <- v$redox_diagnostic
  }

  date_col <- rep(as.Date(NA), n)
  if (!is.null(start_date)) {
    sd <- as.Date(start_date)
    date_col <- sd + dat_seq
  }

  provisional_groups <- srividhya_provisional_groups(stratum)
  provisional_warning <- if (length(provisional_groups) > 0) {
    paste0("PROVISIONAL DEFAULT(S) IN USE: ",
           paste(provisional_groups, collapse = ", "),
           ". Treat this output as indicative only; recommend local ",
           "calibration before field use.")
  } else {
    NA_character_
  }

  evidence_tier_summary <- paste0(
    "root=", rp$evidence_tier, "; percolation=", pp$evidence_tier,
    "; safety=", sp$evidence_tier, "; soc=", scp$evidence_tier
  )

  data_quality_flag <- ifelse(
    is.na(t_hours), "time_to_target_unresolved (percolation curve did not cover safe depth)",
    ifelse(!is.na(provisional_warning), "provisional_parameters_in_use", "ok")
  )

  data.frame(
    stratum_id = stratum$stratum_id,
    date = date_col,
    DAT = dat_seq,
    root_depth_cm = root_depth_cm,
    safe_depth_ceiling_cm = safe_depth_ceiling_cm,
    percolation_model = percolation_model,
    expected_time_to_target_hours = t_hours,
    expected_time_to_target_days = t_hours / 24,
    verification_rule = sp$verification_rule,
    verification_status = verification_status,
    redox_diagnostic = redox_diagnostic,
    nominal_frequency_events_season = nominal_frequency,
    frequency_basis = "SOC-scaled interpolation (provisional surface)",
    evidence_tier_summary = evidence_tier_summary,
    provisional_warning = provisional_warning,
    data_quality_flag = data_quality_flag,
    stringsAsFactors = FALSE
  )
}
