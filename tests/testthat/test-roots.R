test_that("root depth increases monotonically toward R_max (R0 parameterization)", {
  dat <- seq(0, 60, by = 5)
  R <- srividhya_root_depth(dat, R_max_cm = 30, k_day_inv = 0.12, R0_cm = 3)
  expect_true(all(diff(R) > 0))
  expect_lt(max(R), 30)
  expect_gt(min(R), 0)
})

test_that("t50 and R0 parameterizations are consistent near the midpoint", {
  R_max <- 30; k <- 0.15
  R0 <- 3
  A <- (R_max - R0) / R0
  t50 <- log(A) / k
  dat <- c(0, t50, 40)
  R_t50 <- srividhya_root_depth(dat, R_max_cm = R_max, k_day_inv = k, t50_dat = t50)
  R_r0 <- srividhya_root_depth(dat, R_max_cm = R_max, k_day_inv = k, R0_cm = R0)
  expect_equal(R_t50, R_r0, tolerance = 1e-8)
  expect_equal(R_t50[2], R_max / 2, tolerance = 1e-8)
})

test_that("root depth rejects invalid inputs", {
  expect_error(srividhya_root_depth(-1, R_max_cm = 30, k_day_inv = 0.1, R0_cm = 3),
               "DAT")
  expect_error(srividhya_root_depth(10, R_max_cm = 30, k_day_inv = 0.1),
               "exactly one")
  expect_error(srividhya_root_depth(10, R_max_cm = 30, k_day_inv = 0.1,
                                     t50_dat = 10, R0_cm = 3),
               "exactly one")
  expect_error(srividhya_root_depth(10, R_max_cm = 30, k_day_inv = 0.1, R0_cm = 30),
               "strictly less")
  expect_error(srividhya_root_depth(10, R_max_cm = -5, k_day_inv = 0.1, R0_cm = 3),
               "R_max_cm")
})

test_that("boundary DAT = 0 behaves sensibly", {
  R <- srividhya_root_depth(0, R_max_cm = 30, k_day_inv = 0.12, R0_cm = 3)
  expect_equal(R, 3)
})
