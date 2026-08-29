#' Soil-organic-carbon-scaled drainage-event frequency
#'
#' Returns a bounded, first-order interpolation of seasonal drainage-event
#' frequency as a function of soil organic carbon (SOC), anchored at 12 and
#' 18 g SOC/kg following Zhao et al. (2024). This is an initial, locally
#' calibratable surface, not a fitted universal methane response.
#' \code{f_low} and \code{f_high} must be supplied by the caller from
#' project-level calibration; SRIvidhya does not assume values for either.
#'
#' @param SOC_g_kg Numeric vector. Soil organic carbon concentration(s)
#'   (g/kg). Must be >= 0.
#' @param f_low_events_season Numeric. Seasonal drainage-event target at the
#'   lower SOC anchor (12 g/kg). Must be >= 0.
#' @param f_high_events_season Numeric. Seasonal drainage-event target at
#'   the upper SOC anchor (18 g/kg). Must be >= 0.
#'
#' @return Numeric vector of drainage-event frequencies (events/season),
#'   with attribute \code{"provisional"} (\code{TRUE}) attached.
#'
#' @export
srividhya_soc_frequency <- function(SOC_g_kg, f_low_events_season,
                                     f_high_events_season) {
  if (!is.numeric(SOC_g_kg) || length(SOC_g_kg) < 1L ||
      any(!is.finite(SOC_g_kg))) {
    stop("srividhya: 'SOC_g_kg' must be a numeric vector of finite values.",
         call. = FALSE)
  }
  if (any(SOC_g_kg < 0)) {
    stop("srividhya: 'SOC_g_kg' must be >= 0.", call. = FALSE)
  }
  .validate_numeric_scalar(f_low_events_season, "f_low_events_season", lower = 0)
  .validate_numeric_scalar(f_high_events_season, "f_high_events_season", lower = 0)

  f <- ifelse(
    SOC_g_kg <= 12, f_low_events_season,
    ifelse(SOC_g_kg >= 18, f_high_events_season,
           f_low_events_season +
             (f_high_events_season - f_low_events_season) *
             (SOC_g_kg - 12) / 6)
  )
  attr(f, "provisional") <- TRUE
  attr(f, "note") <- paste(
    "Linear interpolation between literature-anchored SOC boundary points",
    "(12, 18 g/kg); illustrative, not a fitted universal response.",
    "Requires local calibration."
  )
  f
}
