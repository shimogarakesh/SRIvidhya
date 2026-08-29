test_that("depth_only rule works and ignores tension inputs", {
  v <- srividhya_verify_drainage(rule = "depth_only", water_table_depth_cm = 9,
                                  safe_depth_ceiling_cm = 8)
  expect_true(v$status)
  expect_true(is.na(v$tension_condition))
})

test_that("tension_only rule works and ignores depth inputs", {
  v <- srividhya_verify_drainage(rule = "tension_only", psi_kpa = -25,
                                  psi_threshold_kpa = -20)
  expect_true(v$status)
  expect_true(is.na(v$depth_condition))
})

test_that("either rule passes if at least one condition passes", {
  v <- srividhya_verify_drainage(rule = "either", water_table_depth_cm = 5,
                                  safe_depth_ceiling_cm = 8, psi_kpa = -25,
                                  psi_threshold_kpa = -20)
  expect_true(v$status)
  expect_false(v$depth_condition)
  expect_true(v$tension_condition)
})

test_that("both rule fails if either condition fails", {
  v <- srividhya_verify_drainage(rule = "both", water_table_depth_cm = 5,
                                  safe_depth_ceiling_cm = 8, psi_kpa = -25,
                                  psi_threshold_kpa = -20)
  expect_false(v$status)
})

test_that("missing required inputs yield NA status with a warning, not FALSE", {
  expect_warning(
    v <- srividhya_verify_drainage(rule = "depth_only",
                                    water_table_depth_cm = NA,
                                    safe_depth_ceiling_cm = 8),
    "requires"
  )
  expect_true(is.na(v$status))
})

test_that("redox diagnostic is reported independently of verification status", {
  v <- srividhya_verify_drainage(rule = "depth_only", water_table_depth_cm = 9,
                                  safe_depth_ceiling_cm = 8, Eh_mV = -180,
                                  Eh_meth_mV = -150)
  expect_equal(v$redox_diagnostic, "below_threshold")
})
