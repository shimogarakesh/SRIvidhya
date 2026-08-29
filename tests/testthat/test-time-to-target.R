test_that("constant-rate time-to-target matches direct division", {
  t <- srividhya_time_to_target(target_depth_cm = c(4, 8, 12), P_cm_h = 0.4)
  expect_equal(t, c(4, 8, 12) / 0.4)
})

test_that("depth-dependent time-to-target integrates a decreasing rate curve", {
  depth_cm <- c(0, 5, 10, 15)
  rate_cm_h <- c(0.9, 0.6, 0.3, 0.15)
  t <- srividhya_time_to_target(target_depth_cm = c(5, 15),
                                 depth_cm = depth_cm, rate_cm_h = rate_cm_h,
                                 n_grid = 2000)
  expect_true(all(diff(t) > 0))
  naive_fastest <- 15 / max(rate_cm_h)
  expect_gt(t[2], naive_fastest)
})

test_that("out-of-range nonlinear targets return NA with a warning, not extrapolation", {
  expect_warning(
    out <- srividhya_time_to_target(target_depth_cm = 100,
                                     depth_cm = c(0, 5, 10),
                                     rate_cm_h = c(0.9, 0.5, 0.2)),
    "outside the observed"
  )
  expect_true(is.na(out))
})

test_that("time-to-target requires exactly one method and validates inputs", {
  expect_error(srividhya_time_to_target(target_depth_cm = 5), "supply either")
  expect_error(srividhya_time_to_target(target_depth_cm = 5, P_cm_h = 0.4,
                                         depth_cm = c(0, 5), rate_cm_h = c(0.5, 0.4)),
               "not both")
  expect_error(srividhya_time_to_target(target_depth_cm = 5,
                                         depth_cm = c(0, 5), rate_cm_h = c(0.5, -0.1)),
               "must all be > 0")
  expect_error(srividhya_time_to_target(target_depth_cm = -1, P_cm_h = 0.4),
               ">= 0")
})

test_that("days unit conversion is correct", {
  t_h <- srividhya_time_to_target(target_depth_cm = 12, P_cm_h = 0.5, units = "hours")
  t_d <- srividhya_time_to_target(target_depth_cm = 12, P_cm_h = 0.5, units = "days")
  expect_equal(t_h / 24, t_d)
})
