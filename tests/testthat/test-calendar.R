make_test_stratum <- function(verification_rule = "either") {
  srividhya_define_stratum(
    stratum_id = "TEST_STRATUM",
    cultivar = "Synthetic cultivar (test only)",
    establishment_method = "transplanted",
    soil_profile_id = "TEST_PROFILE",
    irrigation_setting = "controlled irrigation",
    management_notes = "Unit test fixture; not calibration data.",
    root_parameters = list(R_max_cm = 30, R0_cm = 3, k_day_inv = 0.12,
                            evidence_tier = "provisional_default"),
    percolation_parameters = list(P_cm_h = 0.42,
                                   evidence_tier = "provisional_default"),
    safety_parameters = list(alpha = 0.5, D_max_cm = 12,
                              psi_threshold_kpa = -20,
                              verification_rule = verification_rule,
                              evidence_tier = "provisional_default"),
    soc_parameters = list(SOC_g_kg = 15, f_low_events_season = 3,
                           f_high_events_season = 6,
                           evidence_tier = "provisional_default")
  )
}

test_that("calendar generates one row per DAT with expected columns", {
  stratum <- make_test_stratum()
  cal <- srividhya_generate_calendar(stratum, dat_seq = c(5, 20, 35))
  expect_equal(nrow(cal), 3)
  expect_true(all(c("root_depth_cm", "safe_depth_ceiling_cm",
                     "expected_time_to_target_hours", "verification_status",
                     "nominal_frequency_events_season",
                     "provisional_warning") %in% names(cal)))
})

test_that("provisional evidence tiers propagate a visible warning", {
  stratum <- make_test_stratum()
  cal <- srividhya_generate_calendar(stratum, dat_seq = 20)
  expect_false(is.na(cal$provisional_warning[1]))
  expect_match(cal$provisional_warning[1], "PROVISIONAL")
})

test_that("calendar rejects mismatched auxiliary vector lengths", {
  stratum <- make_test_stratum()
  expect_error(
    srividhya_generate_calendar(stratum, dat_seq = c(5, 20),
                                 water_table_depth_cm = c(4, 5, 6)),
    "same length"
  )
})

test_that("calendar with nonlinear percolation flags unresolved time-to-target", {
  stratum <- make_test_stratum()
  stratum$percolation_parameters <- list(
    depth_cm = c(0, 5), rate_cm_h = c(0.5, 0.3),
    evidence_tier = "provisional_default"
  )
  expect_warning(
    cal <- srividhya_generate_calendar(stratum, dat_seq = 60),
    "outside the observed"
  )
  expect_true(is.na(cal$expected_time_to_target_hours[1]))
  expect_equal(cal$data_quality_flag[1],
               "time_to_target_unresolved (percolation curve did not cover safe depth)")
})

test_that("farmer instruction renders required fields and provisional note", {
  stratum <- make_test_stratum()
  cal <- srividhya_generate_calendar(stratum, dat_seq = 35)
  txt <- srividhya_farmer_instruction(cal[1, ])
  expect_match(txt, "Day after transplanting: 35")
  expect_match(txt, "Do not drain beyond:")
  expect_match(txt, "NOTE:")
})
