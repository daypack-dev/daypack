open Cmdliner

let free_time_slots_arg = Arg.(value & flag & info [ "free" ])

let run (list_free_time_slots : bool) : unit =
  match Context.load () with
  | Error msg -> print_endline msg
  | Ok context ->
    let hd =
      Daypack_lib.Sched_ver_history.Read.get_head context.sched_ver_history
    in
    let start = Daypack_lib.Time.Current.cur_unix_time () in
    let end_exc = Daypack_lib.Time.Add.add_days_unix_time ~days:3 start in
    if list_free_time_slots then
      Daypack_lib.Sched.Agenda.Time_slot.get_free_time_slots ~start ~end_exc
        hd
      |> Seq.iter (fun (start, end_exc) ->
          let start_str =
            Daypack_lib.Time.Print.time_to_date_string
              ~display_in_time_zone:`Local start
          in
          let end_exc_str =
            Daypack_lib.Time.Print.time_to_date_string
              ~display_in_time_zone:`Local end_exc
          in
          Printf.printf "| %s - %s | %s\n" start_str end_exc_str
            (Daypack_lib.Time.Print.human_readable_string_of_duration (Int64.sub end_exc start)))
    else
      Daypack_lib.Sched.Agenda.To_seq.task_seg_place_uncompleted
        ~start
        ~end_exc
        ~include_task_seg_place_partially_within_time_period:true
        hd
      |> Seq.iter (fun (task_seg_id, start, end_exc) ->
          let start_str =
            Daypack_lib.Time.Print.time_to_date_string
              ~display_in_time_zone:`Local start
          in
          let end_exc_str =
            Daypack_lib.Time.Print.time_to_date_string
              ~display_in_time_zone:`Local end_exc
          in
          Printf.printf "| %s - %s | %s\n" start_str end_exc_str (Daypack_lib.Task_ds.task_seg_id_to_string task_seg_id)
        )

let cmd = (Term.(const run $ free_time_slots_arg), Term.info "agenda")
