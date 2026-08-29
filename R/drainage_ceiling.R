#' Root-safe drainage ceiling
#'
#' Computes the maximum permissible drainage depth below the soil surface at
#' a given root depth, implementing:
#' \deqn{D_{safe}(t) = \min\{\alpha R(t), D_{max}\}}
#' SRIvidhya does not impose a categorical exclusion window; at
#' \code{root_depth_cm = 0} (e.g. at transplanting) the safe depth is
#' approximately zero, so drainage is continuously limited rather than
#' forbidden outright.
#'
#' @param root_depth_cm Numeric vector. Effective current root depth (cm),
#'   typically from \code{srividhya_root_depth()}. Must be >= 0.
#' @param alpha Numeric. Root-safety margin: fraction of current active root
#'   depth available for safe drawdown (0 <= alpha <= 1). Must be supplied by
#'   the user from local yield and plant-water-status calibration.
#' @param D_max_cm Numeric. Locally accepted upper drainage-depth ceiling
#'   below the soil surface (cm). A familiar safe-AWD reference near 15 cm
#'   may be used only as a visible, editable, explicitly provisional
#'   starting default supplied by the caller -- SRIvidhya itself does not
#'   assume this value.
#'
#' @return Numeric vector of safe drainage-depth ceilings (cm below soil
#'   surface), same length as \code{root_depth_cm}.
#'
#' @export
srividhya_safe_depth <- function(root_depth_cm, alpha, D_max_cm) {
  if (!is.numeric(root_depth_cm) || length(root_depth_cm) < 1L ||
      any(!is.finite(root_depth_cm))) {
    stop("srividhya: 'root_depth_cm' must be a numeric vector of finite values.",
         call. = FALSE)
  }
  if (any(root_depth_cm < 0)) {
    stop("srividhya: 'root_depth_cm' must be >= 0.", call. = FALSE)
  }
  .validate_numeric_scalar(alpha, "alpha", lower = 0, upper = 1)
  .validate_numeric_scalar(D_max_cm, "D_max_cm", lower = 0, lower_inclusive = FALSE)

  pmin(alpha * root_depth_cm, D_max_cm)
}
