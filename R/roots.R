#' Effective root depth at a given day after transplanting
#'
#' Implements the logistic root-depth trajectory used throughout the
#' SRIvidhya framework:
#' \deqn{R(t) = R_{max} / (1 + \exp[-k(t - t_{50})])}
#' or, equivalently, using the root depth at transplanting \eqn{R_0}:
#' \deqn{R(t) = R_{max} / (1 + A \exp(-kt)), \; A = (R_{max}-R_0)/R_0.}
#' Exactly one parameterization must be supplied (either \code{t50_dat} or
#' \code{R0_cm}); SRIvidhya does not assume or default a growth-rate
#' parameter, inflection day, or root depth at transplanting.
#'
#' @param dat Numeric vector of days after transplanting (DAT >= 0).
#' @param R_max_cm Numeric. Effective variety-specific maximum rooting
#'   depth relevant to water uptake and crop support (cm). Must be > 0.
#' @param k_day_inv Numeric. Root-depth growth-rate parameter (day^-1).
#'   Must be > 0.
#' @param t50_dat Numeric. Day after transplanting at which root depth
#'   reaches \code{R_max_cm / 2}. Mutually exclusive with \code{R0_cm}.
#' @param R0_cm Numeric. Effective root depth at transplanting (cm). Must be
#'   strictly between 0 and \code{R_max_cm}. Mutually exclusive with
#'   \code{t50_dat}.
#'
#' @return Numeric vector of effective root depths (cm), same length as
#'   \code{dat}.
#'
#' @export
srividhya_root_depth <- function(dat, R_max_cm, k_day_inv,
                                  t50_dat = NULL, R0_cm = NULL) {

  if (!is.numeric(dat) || length(dat) < 1L || any(!is.finite(dat))) {
    stop("srividhya: 'dat' must be a numeric vector of finite values.",
         call. = FALSE)
  }
  if (any(dat < 0)) {
    stop("srividhya: 'dat' (days after transplanting) must be >= 0.",
         call. = FALSE)
  }
  .validate_numeric_scalar(R_max_cm, "R_max_cm", lower = 0, lower_inclusive = FALSE)
  .validate_numeric_scalar(k_day_inv, "k_day_inv", lower = 0, lower_inclusive = FALSE)

  has_t50 <- !is.null(t50_dat)
  has_R0 <- !is.null(R0_cm)
  if (has_t50 == has_R0) {
    stop("srividhya: supply exactly one of 't50_dat' or 'R0_cm' to define ",
         "the root-depth trajectory, not both or neither.", call. = FALSE)
  }

  if (has_t50) {
    .validate_numeric_scalar(t50_dat, "t50_dat", lower = 0)
    R <- R_max_cm / (1 + exp(-k_day_inv * (dat - t50_dat)))
  } else {
    .validate_numeric_scalar(R0_cm, "R0_cm", lower = 0, lower_inclusive = FALSE)
    if (R0_cm >= R_max_cm) {
      stop("srividhya: 'R0_cm' must be strictly less than 'R_max_cm'.",
           call. = FALSE)
    }
    A <- (R_max_cm - R0_cm) / R0_cm
    R <- R_max_cm / (1 + A * exp(-k_day_inv * dat))
  }

  R
}
