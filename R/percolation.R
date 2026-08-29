#' Expected time to reach a target drainage depth
#'
#' Computes the expected time after inlet closure to reach a target safe
#' drainage depth, supporting both a constant water-table decline rate and a
#' depth-dependent (nonlinear) decline rate. SRIvidhya does not silently
#' collapse nonlinear percolation observations to a constant-rate model.
#'
#' @param target_depth_cm Numeric vector. Target safe drainage depth(s)
#'   (cm below soil surface). Must be >= 0.
#' @param P_cm_h Numeric scalar. Constant water-table decline rate (cm/h).
#'   Mutually exclusive with \code{depth_cm}/\code{rate_cm_h}.
#' @param depth_cm Numeric vector. Depths (cm) at which \code{rate_cm_h} was
#'   observed, sorted increasing. Mutually exclusive with \code{P_cm_h}.
#' @param rate_cm_h Numeric vector, same length as \code{depth_cm}. Observed
#'   decline rate (cm/h) at each depth. All values must be > 0.
#' @param n_grid Integer. Number of grid points for numerical integration.
#' @param units Character, either \code{"hours"} (default) or \code{"days"}.
#'
#' @return Numeric vector of expected times, same length as
#'   \code{target_depth_cm}. Returns \code{NA} with a warning for any target
#'   depth outside the range covered by \code{depth_cm}.
#'
#' @export
srividhya_time_to_target <- function(target_depth_cm,
                                      P_cm_h = NULL,
                                      depth_cm = NULL,
                                      rate_cm_h = NULL,
                                      n_grid = 200L,
                                      units = c("hours", "days")) {

  units <- match.arg(units)

  if (!is.numeric(target_depth_cm) || length(target_depth_cm) < 1L ||
      any(!is.finite(target_depth_cm))) {
    stop("srividhya: 'target_depth_cm' must be a numeric vector of finite values.",
         call. = FALSE)
  }
  if (any(target_depth_cm < 0)) {
    stop("srividhya: 'target_depth_cm' must be >= 0.", call. = FALSE)
  }

  has_constant <- !is.null(P_cm_h)
  has_curve <- !is.null(depth_cm) || !is.null(rate_cm_h)

  if (has_constant && has_curve) {
    stop("srividhya: supply either 'P_cm_h' (constant rate) or ",
         "'depth_cm'/'rate_cm_h' (depth-dependent rate), not both.",
         call. = FALSE)
  }
  if (!has_constant && !has_curve) {
    stop("srividhya: supply either 'P_cm_h' or 'depth_cm'/'rate_cm_h'.",
         call. = FALSE)
  }

  if (has_constant) {
    .validate_numeric_scalar(P_cm_h, "P_cm_h", lower = 0, lower_inclusive = FALSE)
    t_hours <- target_depth_cm / P_cm_h
  } else {
    if (is.null(depth_cm) || is.null(rate_cm_h)) {
      stop("srividhya: both 'depth_cm' and 'rate_cm_h' must be supplied ",
           "together for the depth-dependent method.", call. = FALSE)
    }
    if (length(depth_cm) != length(rate_cm_h)) {
      stop("srividhya: 'depth_cm' and 'rate_cm_h' must have equal length.",
           call. = FALSE)
    }
    if (length(depth_cm) < 2L) {
      stop("srividhya: at least two depth/rate observations are required ",
           "to fit a depth-dependent percolation rate.", call. = FALSE)
    }
    if (is.unsorted(depth_cm)) {
      stop("srividhya: 'depth_cm' must be sorted in increasing order.",
           call. = FALSE)
    }
    if (any(!is.finite(depth_cm)) || any(!is.finite(rate_cm_h))) {
      stop("srividhya: 'depth_cm' and 'rate_cm_h' must be finite, ",
           "non-missing values.", call. = FALSE)
    }
    if (any(rate_cm_h <= 0)) {
      stop("srividhya: all 'rate_cm_h' values must be > 0 (a non-positive ",
           "decline rate is not physically valid for drawdown).",
           call. = FALSE)
    }

    d_min <- min(depth_cm)
    d_max <- max(depth_cm)

    t_hours <- vapply(target_depth_cm, function(target) {
      if (target < d_min || target > d_max) {
        warning(sprintf(
          "srividhya: target_depth_cm = %s is outside the observed ",
          "percolation depth range [%s, %s]; returning NA rather than ",
          "extrapolating.", target, d_min, d_max), call. = FALSE)
        return(NA_real_)
      }
      if (target == 0) return(0)
      grid <- seq(0, target, length.out = max(n_grid, 2L))
      rate_at_grid <- stats::approx(x = depth_cm, y = rate_cm_h, xout = grid,
                                     rule = 2)$y
      inv_rate <- 1 / rate_at_grid
      dd <- diff(grid)
      area <- sum((inv_rate[-1] + inv_rate[-length(inv_rate)]) / 2 * dd)
      area
    }, numeric(1))
  }

  if (units == "days") t_hours <- t_hours / 24
  t_hours
}
