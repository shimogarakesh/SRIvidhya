#' Generate a simplified farmer-facing instruction from a calendar row
#'
#' Converts a single row of a SRIvidhya water-level calendar into a concise,
#' actionable field instruction. Any provisional-parameter warning attached
#' to the row is retained in the returned text.
#'
#' @param calendar_row A single-row \code{data.frame} or list produced by
#'   \code{srividhya_generate_calendar()}.
#'
#' @return Character scalar containing the farmer-facing instruction text.
#'
#' @export
srividhya_farmer_instruction <- function(calendar_row) {
  required <- c("DAT", "safe_depth_ceiling_cm", "expected_time_to_target_hours",
                "verification_rule")
  missing_cols <- setdiff(required, names(calendar_row))
  if (length(missing_cols) > 0) {
    stop(sprintf("srividhya: calendar_row is missing required field(s): %s.",
                 paste(missing_cols, collapse = ", ")), call. = FALSE)
  }

  dat <- calendar_row$DAT[1]
  depth <- round(calendar_row$safe_depth_ceiling_cm[1], 1)
  hours <- calendar_row$expected_time_to_target_hours[1]
  hours_txt <- if (is.na(hours)) "not resolved from current percolation data" else
    paste0(round(hours, 1), " hours")
  rule <- calendar_row$verification_rule[1]

  reirrigate_txt <- switch(rule,
    depth_only = sprintf("the monitoring tube reaches %s cm below the surface", depth),
    tension_only = "the soil-tension indicator reaches the locally set threshold",
    sprintf("the monitoring tube reaches %s cm below the surface or the soil-tension indicator reaches the locally set threshold", depth)
  )

  txt <- paste0(
    "Day after transplanting: ", dat, "\n",
    "Action: Stop inlet when scheduled drainage begins.\n",
    "Do not drain beyond: ", depth, " cm below the soil surface.\n",
    "Expected time to target: ", hours_txt, ".\n",
    "Re-irrigate when: ", reirrigate_txt, "."
  )

  if ("provisional_warning" %in% names(calendar_row) &&
      !is.na(calendar_row$provisional_warning[1])) {
    txt <- paste0(txt, "\n\nNOTE: ", calendar_row$provisional_warning[1])
  }

  txt
}
