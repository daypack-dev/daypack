(* let () =
 *   let suites =
 *     [
 *       ("Map_utils", Map_utils.suite);
 *       ("Set_utils", Set_utils.suite);
 *       ("Time_slot", Time_slot_ds.suite);
 *       ("Task_seg_place_gens", Task_seg_place_gens.suite);
 *       ("Task", Task_ds.suite);
 *       ("Sched", Sched.suite);
 *       ("Sched_ver_history", Sched_ver_history.suite);
 *     ]
 *     |> List.map (fun (name, suite) ->
 *         (name, List.map QCheck_alcotest.to_alcotest suite))
 *   in
 *   Alcotest.run "daypack_lib" suites *)

let () =
  QCheck.Test.check_exn
    Sched_ver_history.qc_read_from_dir_is_inverse_of_write_to_dir
