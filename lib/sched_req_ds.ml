open Int64_utils

type sched_req_id = int64

type sched_req = sched_req_id * sched_req_data

and sched_req_data_unit =
  ( Task_ds.task_seg_alloc_req,
    int64,
    Time_slot_ds.t )
    Sched_req_data_unit_skeleton.t

and sched_req_data = sched_req_data_unit list

type sched_req_record = sched_req_id * sched_req_record_data

and sched_req_record_data_unit =
  (Task_ds.task_seg, int64, Time_slot_ds.t) Sched_req_data_unit_skeleton.t

and sched_req_record_data = sched_req_record_data_unit list

let flexibility_score_of_sched_req_record
    ((_id, req_record_data_unit_list) : sched_req_record) : float =
  match List.hd req_record_data_unit_list with
  | Sched_req_data_unit_skeleton.Fixed _ -> 0.0
  | Shift x ->
    let task_seg_alloc_req_sum_len =
      Task_ds.task_seg_alloc_req_sum_length x.task_seg_related_data_list
      |> Int64.to_float
    in
    let time_slot_sum_len =
      Time_slot_ds.sum_length_list x.time_slots |> Int64.to_float
    in
    1. -. (task_seg_alloc_req_sum_len /. time_slot_sum_len)
  | Split_and_shift x ->
    let _, size = x.task_seg_related_data in
    let time_slot_sum_len =
      Time_slot_ds.sum_length_list x.time_slots |> Int64.to_float
    in
    1. -. (Int64.to_float size /. time_slot_sum_len)
  | Split_even x ->
    let _, size = x.task_seg_related_data in
    let time_slot_sum_len =
      Time_slot_ds.intersect
        (x.time_slots |> List.to_seq)
        (x.buckets |> List.to_seq)
      |> List.of_seq
      |> Time_slot_ds.sum_length_list
      |> Int64.to_float
    in
    1. -. (Int64.to_float size /. time_slot_sum_len)
  | Time_share x ->
    let task_seg_alloc_req_sum_len =
      Task_ds.task_seg_alloc_req_sum_length x.task_seg_related_data_list
      |> Int64.to_float
    in
    let time_slot_sum_len =
      Time_slot_ds.sum_length_list x.time_slots |> Int64.to_float
    in
    1. -. (task_seg_alloc_req_sum_len /. time_slot_sum_len)
  | Push_toward x ->
    let _, size = x.task_seg_related_data in
    let time_slot_sum_len =
      Time_slot_ds.sum_length_list x.time_slots |> Int64.to_float
    in
    1. -. (Int64.to_float size /. time_slot_sum_len)

let sort_sched_req_record_list_by_flexibility_score
    (reqs : sched_req_record list) : sched_req_record list =
  List.sort
    (fun x y ->
       compare
         (flexibility_score_of_sched_req_record x)
         (flexibility_score_of_sched_req_record y))
    reqs

let sched_req_bound_on_start_and_end_exc
    ((_id, req_record_data_unit_list) : sched_req) : (int64 * int64) option =
  List.fold_left
    (fun acc req_record_data_unit ->
       let cur =
         match req_record_data_unit with
         | Sched_req_data_unit_skeleton.Fixed
             { task_seg_related_data = _, task_seg_size; start } ->
           Some (start, start +^ task_seg_size)
         | Shift { time_slots; _ }
         | Split_and_shift { time_slots }
         | Split_even { time_slots; _ }
         | Time_share { time_slots; _ }
         | Push_toward { time_slots; _ } ->
           Time_slot_ds.min_start_and_max_end_exc_list time_slots
       in
       match acc with
       | None -> cur
       | Some (start, end_exc) -> (
           match cur with
           | None -> acc
           | Some (cur_start, cur_end_exc) ->
             Some (min start cur_start, max end_exc cur_end_exc) ))
    None req_record_data_unit_list

let sched_req_fully_within_time_period ~start ~end_exc (sched_req : sched_req) :
  bool =
  match sched_req_bound_on_start_and_end_exc sched_req with
  | None -> false
  | Some (start', end_exc') -> start <= start' && end_exc' <= end_exc

let sched_req_partially_within_time_period ~start ~end_exc
    (sched_req : sched_req) : bool =
  match sched_req_bound_on_start_and_end_exc sched_req with
  | None -> false
  | Some (start', end_exc') ->
    (start' < start && start < end_exc')
    || (start' < end_exc && end_exc < end_exc')

module Serialize = struct
  let rec pack_sched_req (id, data) : Sched_req_ds_t.sched_req =
    (Int64.to_float id, List.map pack_sched_req_data_unit data)

  and pack_sched_req_data_unit (sched_req_data_unit : sched_req_data_unit) :
    Sched_req_ds_t.sched_req_data_unit =
    Sched_req_data_unit_skeleton.Serialize.pack
      ~pack_data:Task_ds.Serialize.pack_task_seg_alloc_req
      ~pack_time:Int64.to_float
      ~pack_time_slot:Time_slot_ds.Serialize.pack_time_slot
      sched_req_data_unit

  let rec pack_sched_req_record (id, data_list) :
    Sched_req_ds_t.sched_req_record =
    (Int64.to_float id, List.map pack_sched_req_record_data_unit data_list)

  and pack_sched_req_record_data_unit
      (sched_req_record_data : sched_req_record_data_unit) :
    Sched_req_ds_t.sched_req_record_data_unit =
    Sched_req_data_unit_skeleton.Serialize.pack
      ~pack_data:Task_ds.Serialize.pack_task_seg
      ~pack_time:Int64.to_float
      ~pack_time_slot:Time_slot_ds.Serialize.pack_time_slot
      sched_req_record_data
end

module Deserialize = struct
  let rec unpack_sched_req (id, data) : sched_req =
    (Int64.of_float id, List.map unpack_sched_req_data_unit data)

  and unpack_sched_req_data_unit
      (sched_req_data_unit : Sched_req_ds_t.sched_req_data_unit) :
    sched_req_data_unit =
    Sched_req_data_unit_skeleton.Deserialize.unpack
      ~unpack_data:Task_ds.Deserialize.unpack_task_seg_alloc_req
      ~unpack_time:Int64.of_float
      ~unpack_time_slot:Time_slot_ds.Deserialize.unpack_time_slot
      sched_req_data_unit

  let rec unpack_sched_req_record (id, data) : sched_req_record =
    (Int64.of_float id, List.map unpack_sched_req_record_data_unit data)

  and unpack_sched_req_record_data_unit
      (sched_req_record_data_unit : Sched_req_ds_t.sched_req_record_data_unit) :
    sched_req_record_data_unit =
    Sched_req_data_unit_skeleton.Deserialize.unpack
      ~unpack_data:Task_ds.Deserialize.unpack_task_seg
      ~unpack_time:Int64.of_float
      ~unpack_time_slot:Time_slot_ds.Deserialize.unpack_time_slot
      sched_req_record_data_unit
end

module Print = struct
  let debug_string_of_sched_req_data_unit ?(indent_level = 0)
      ?(buffer = Buffer.create 4096) req_data =
    Sched_req_data_unit_skeleton.Print
    .debug_string_of_sched_req_data_unit_skeleton ~indent_level ~buffer
      ~string_of_data:(fun (id, len) ->
          Printf.sprintf "id : %s, len : %Ld\n"
            (Task_ds.task_inst_id_to_string id)
            len)
      ~string_of_time:Int64.to_string
      ~string_of_time_slot:Time_slot_ds.to_string req_data

  let debug_string_of_sched_req_data ?(indent_level = 0)
      ?(buffer = Buffer.create 4096) req_data =
    List.iter
      (fun data_unit ->
         debug_string_of_sched_req_data_unit ~indent_level ~buffer data_unit
         |> ignore)
      req_data;
    Buffer.contents buffer

  let debug_string_of_sched_req ?(indent_level = 0)
      ?(buffer = Buffer.create 4096) (id, req_data) =
    Debug_print.bprintf ~indent_level buffer "schedule request id : %Ld\n" id;
    debug_string_of_sched_req_data ~indent_level:(indent_level + 1) ~buffer
      req_data
    |> ignore;
    Buffer.contents buffer

  let debug_string_of_sched_req_record_data_unit ?(indent_level = 0)
      ?(buffer = Buffer.create 4096) req_data =
    Sched_req_data_unit_skeleton.Print
    .debug_string_of_sched_req_data_unit_skeleton ~indent_level ~buffer
      ~string_of_data:(fun (id, len) ->
          Printf.sprintf "id : %s, len : %Ld\n"
            (Task_ds.task_seg_id_to_string id)
            len)
      ~string_of_time:Int64.to_string
      ~string_of_time_slot:Time_slot_ds.to_string req_data

  let debug_string_of_sched_req_record_data ?(indent_level = 0)
      ?(buffer = Buffer.create 4096) req_record_data_list =
    List.iter
      (fun req_record_data ->
         debug_string_of_sched_req_record_data_unit ~indent_level ~buffer
           req_record_data
         |> ignore)
      req_record_data_list;
    Buffer.contents buffer

  let debug_string_of_sched_req_record ?(indent_level = 0)
      ?(buffer = Buffer.create 4096) (id, req_data_list) =
    Debug_print.bprintf ~indent_level buffer
      "schedule request record id : %Ld\n" id;
    debug_string_of_sched_req_record_data ~indent_level:(indent_level + 1)
      ~buffer req_data_list
    |> ignore;
    Buffer.contents buffer

  let debug_print_sched_req_data_unit ?(indent_level = 0) sched_req_data_unit =
    print_string
      (debug_string_of_sched_req_data_unit ~indent_level sched_req_data_unit)

  let debug_print_sched_req_data ?(indent_level = 0) sched_req_data =
    print_string (debug_string_of_sched_req_data ~indent_level sched_req_data)

  let debug_print_sched_req ?(indent_level = 0) sched_req =
    print_string (debug_string_of_sched_req ~indent_level sched_req)

  let debug_print_sched_req_record_data_unit ?(indent_level = 0)
      sched_req_data_unit =
    print_string
      (debug_string_of_sched_req_record_data_unit ~indent_level
         sched_req_data_unit)

  let debug_print_sched_req_record_data ?(indent_level = 0) sched_req_data =
    print_string
      (debug_string_of_sched_req_record_data ~indent_level sched_req_data)

  let debug_print_sched_req_record ?(indent_level = 0) sched_req =
    print_string (debug_string_of_sched_req_record ~indent_level sched_req)
end
