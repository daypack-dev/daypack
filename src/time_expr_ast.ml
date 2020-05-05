type bound =
  [ `Every
  | `Next
  ]

type second_expr = int

type minute_second_expr = {
  minute : int;
  second : int;
}

type hour_minute_second_expr = {
  hour : int;
  minute : int;
  second : int;
}

type second_range_expr = second_expr Range.range

type minute_second_range_expr = minute_second_expr Range.range

type hour_minute_second_range_expr = hour_minute_second_expr Range.range

type day_expr =
  | Weekday of Time.weekday
  | Month_day of int

type day_range_expr =
  | Weekday_range of Time.weekday_range
  | Month_day_range of Time.month_day_range

type month_expr = Time.month

type year_expr = int

type unbounded_time_points_expr =
  | Tpe_name of string
  | Tpe_unix_times of int64 list
  | Second of second_expr
  | Minute_second of minute_second_expr
  | Hour_minute_second of hour_minute_second_expr
  | Day_hour_minute_second of {
      day : day_expr;
      hour_minute_second : hour_minute_second_expr;
    }
  | Month_day_hour_minute_second of {
      month : month_expr;
      month_day : int;
      hour_minute_second : hour_minute_second_expr;
    }
  | Year_month_day_hour_minute_second of {
      year : year_expr;
      month : month_expr;
      month_day : int;
      hour_minute_second : hour_minute_second_expr;
    }

type time_points_expr = bound * unbounded_time_points_expr

type month_weekday_mode =
  | First_n of int
  | Last_n of int

type unbounded_time_slots_expr =
  | Tse_name of string
  | Explicit_time_slots of
      (unbounded_time_points_expr * unbounded_time_points_expr) list
  | Month_days_and_hour_minute_second_ranges of {
      month_days : int Range.range list;
      hour_minute_second_ranges : hour_minute_second_range_expr list;
    }
  | Weekdays_and_hour_minute_second_ranges of {
      weekdays : Time.weekday Range.range list;
      hour_minute_second_ranges : hour_minute_second_range_expr list;
    }
  | Months_and_month_days_and_hour_minute_second_ranges of {
      months : month_expr Range.range list;
      month_days : int Range.range list;
      hour_minute_second_ranges : hour_minute_second_range_expr list;
    }
  | Months_and_weekdays_and_hour_minute_second_ranges of {
      months : month_expr Range.range list;
      weekdays : Time.weekday Range.range list;
      hour_minute_second_ranges : hour_minute_second_range_expr list;
    }
  | Months_and_weekday_and_hour_minute_second_ranges of {
      months : month_expr Range.range list;
      weekday : Time.weekday;
      hour_minute_second_ranges : hour_minute_second_range_expr list;
      month_weekday_mode : month_weekday_mode option;
    }
  | Years_and_months_and_month_days_and_hour_minute_second_ranges of {
      years : int Range.range list;
      months : month_expr Range.range list;
      month_days : int Range.range list;
      hour_minute_second_ranges : hour_minute_second_range_expr list;
    }

type time_slots_expr = bound * unbounded_time_slots_expr

type t =
  | Time_points_expr of time_points_expr
  | Time_slots_expr of time_slots_expr