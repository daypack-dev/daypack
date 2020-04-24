type hms_expr = {
  hour : int;
  minute : int;
  second : int;
}

type hms_range_expr = hms_expr Range.t

type day_expr = Time_expr_ast.day_expr

type day_range_expr = Time_expr_ast.day_range_expr

type month_expr = Time.month

type year_expr = int

type bound = Time_expr_ast.bound

type unbounded_time_point_expr =
  | Year_month_day_hms of {
      year : year_expr;
      month : month_expr;
      month_day : int;
      hms : hms_expr;
    }
  | Month_day_hms of {
      month : month_expr;
      month_day : int;
      hms : hms_expr;
    }
  | Day_hms of {
      day : day_expr;
      hms : hms_expr;
    }
  | Hms of {
      hms : hms_expr;
    }

type time_point_expr = bound * unbounded_time_point_expr

type month_weekday_mode = Time_expr_ast.month_weekday_mode

type unbounded_time_slots_expr =
  | Single_time_slot of {
      start : unbounded_time_point_expr;
      end_exc : unbounded_time_point_expr;
    }
  | Month_days_and_hms_ranges of {
      month_days : int Range.t list;
      hms_ranges : hms_range_expr list;
    }
  | Weekdays_and_hms_ranges of {
      weekdays : Time.weekday Range.t list;
      hms_ranges : hms_range_expr list;
    }
  | Months_and_month_days_and_hms_ranges of {
      months : month_expr Range.t list;
      month_days : int Range.t list;
      hms_ranges : hms_range_expr list;
    }
  | Months_and_weekdays_and_hms_ranges of {
      months : month_expr Range.t list;
      weekdays : Time.weekday Range.t list;
      hms_ranges : hms_range_expr list;
    }
  | Months_and_weekday_and_hms_ranges of {
      months : month_expr Range.t list;
      weekday : Time.weekday;
      hms_ranges : hms_range_expr list;
      month_weekday_mode : month_weekday_mode option;
    }
  | Years_and_months_and_month_days_and_hms_ranges of {
      years : int Range.t list;
      months : month_expr Range.t list;
      month_days : int Range.t list;
      hms_ranges : hms_range_expr list;
    }

type time_slots_expr = bound * unbounded_time_slots_expr

type t =
  | Time_point_expr of time_point_expr
  | Time_slots_expr of time_slots_expr
