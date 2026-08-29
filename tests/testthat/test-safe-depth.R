test_that("safe depth respects both root-safety and ceiling constraints", {
  root_depth <- c(0, 4, 40)
  d <- srividhya_safe_depth(root_depth, alpha = 0.5, D_max_cm = 12)
  expect_equal(d, c(0, 2, 12))
})

test_that("safe depth is bounded by D_max even for very deep roots", {
  d <- srividhya_safe_depth(100, alpha = 0.9, D_max_cm = 15)
  expect_equal(d, 15)
})

test_that("safe depth rejects invalid alpha and negative root depth", {
  expect_error(srividhya_safe_depth(10, alpha = 1.5, D_max_cm = 15), "alpha")
  expect_error(srividhya_safe_depth(-1, alpha = 0.5, D_max_cm = 15), ">= 0")
  expect_error(srividhya_safe_depth(10, alpha = 0.5, D_max_cm = 0), "D_max_cm")
})
