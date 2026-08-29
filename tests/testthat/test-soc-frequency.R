test_that("SOC frequency is bounded at anchor extremes", {
  f <- srividhya_soc_frequency(c(2, 12, 18, 25), f_low_events_season = 3,
                                f_high_events_season = 6)
  expect_equal(as.numeric(f), c(3, 3, 6, 6))
})

test_that("SOC frequency interpolates linearly between anchors", {
  f <- srividhya_soc_frequency(15, f_low_events_season = 3, f_high_events_season = 6)
  expect_equal(as.numeric(f), 4.5)
})

test_that("SOC frequency output is flagged provisional", {
  f <- srividhya_soc_frequency(15, f_low_events_season = 3, f_high_events_season = 6)
  expect_true(attr(f, "provisional"))
})

test_that("SOC frequency rejects invalid inputs", {
  expect_error(srividhya_soc_frequency(-1, 3, 6), ">= 0")
  expect_error(srividhya_soc_frequency(15, -1, 6), ">= 0")
})
