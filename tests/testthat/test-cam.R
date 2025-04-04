library(testthat)

Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
wt_auth(force = TRUE)
test_data_set <- wt_download_report(project_id = 391, sensor_id = 'CAM', reports = 'main', weather_cols = F)
ind_detections <- wt_ind_detect(test_data_set, threshold = 60, units = "minutes", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE)


################################### Camera Test suite

test_that("Downloading CAM report", {
  test_data_set
  expect_true(!is.null(test_data_set))
})


test_that("Individual detections", {
  ind_detections <- wt_ind_detect(test_data_set, threshold = 60, units = "minutes", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE)
  expect_true(nrow(test_data_set) > nrow(ind_detections))

})

test_that("Individual detections", {
  summary <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", variable = "detections", output_format = "wide")
  expect_true(ncol(summary) > ncol(ind_detections))
})

# Test equality of summarized camera data
test_that("Summarise cam", {
  test_data_set
  summary <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "month", variable = "detections", output_format = "wide")
  expect_true(!is.null(test_data_set))
})

test_that("A specific summarized cam process", {

  df <- test_data_set

  summary <- wt_summarise_cam(
    detect_data = ind_detections,
    raw_data = df,
    time_interval = "month",
    variable = "counts",
    output_format = "long")

  ind_detec.focal <- ind_detections |>
    filter(location=="OGW-ABMI-1057-71-11" & species_common_name=="Moose")
  summary.focal <- summary |>
    filter(location=="OGW-ABMI-1057-71-11" & species_common_name=="Moose",!value==0) |>
    select(value)

  expected <- ind_detec.focal |>
    mutate(month = as.numeric(format(as.Date(start_time),"%m"))) |>
    group_by(month) |>
    summarise(total_count=sum(max_animals)) |>
    select(total_count)

  expected
  summary.focal

  expect_true(identical(sort(expected$total_count), sort(summary.focal$value)))
})

test_that("error when both raw_data and effort_data are provided", {
  test_data_set
  expect_error(wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, effort_data = test_data_set), "Please only supply a value for one of `raw_data` or `effort_data`.")
})

test_that("output format 'wide' works correctly", {
  result <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "wide")
  expect_true("OGW-ABMI-1057-71-11" %in% result$location)
  expect_true("Beaver" %in% colnames(result))
})

test_that("output format 'long' works correctly", {
  result <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "long")
  expect_true(nrow(result) == 36108)
})

test_that("valid time intervals are handled", {

  result_day <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "long")
  result_week <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "week", output_format = "long")
  result_month <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "month", output_format = "long")
  #result_full <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "full", output_format = "long")
  result_day_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "wide")
  result_week_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "week", output_format = "wide")
  result_month_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "month", output_format = "wide")
  #result_full_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "full", output_format = "wide")

  expect_equal(nrow(result_day), 36108)  # Adjust this based on the actual expected number of rows for each case
  expect_equal(nrow(result_week), 5454)
  expect_equal(nrow(result_month), 1530)
  expect_true(nrow(result_day_w) == 2006)
  expect_true(nrow(result_week_w) == 303)
  expect_true(nrow(result_month_w) == 85)
})

test_that("all specified variables are included in the summarised output", {
  result <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, variable = "all", time_interval = "day", output_format = "long")
  expect_true(!is.null(result))
})

test_that("exclude_out_of_range removes data outside of the camera's field of view", {
  result <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, exclude_out_of_range = TRUE, time_interval = "day", output_format = "long", variable = "counts")
  result_out <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, exclude_out_of_range = FALSE, time_interval = "day", output_format = "long", variable = "counts")
  expect_true(nrow(result_out) > nrow(result))
})




