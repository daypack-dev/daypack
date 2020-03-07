open Int64_utils

let brute_force_single ~start ~end_exc ~(base : Sched.sched)
    ((_sched_req_id, sched_req_record_data_list) :
       Sched_req_ds.sched_req_record) : Sched.sched Seq.t =
  let free_time_slots =
    Sched.Time_slot.get_free_time_slots ~start ~end_exc base
  in
  let get_usable_time_slots time_slots =
    time_slots
    |> Time_slot_ds.normalize_list_in_seq_out
    |> Time_slot_ds.intersect free_time_slots
  in
  Seq.flat_map
    (fun sched_req_record_data ->
       match sched_req_record_data with
       | Sched_req_data_unit_skeleton.Fixed
           { task_seg_related_data = task_seg; start } ->
         let _, size = task_seg in
         let usable_time_slots =
           get_usable_time_slots [ (start, start +^ size) ]
         in
         Task_seg_place_gens.multi_task_segs_shift ~incre:1L
           ~task_segs:[ task_seg ] usable_time_slots
         |> OSeq.map (fun place_s ->
             base |> Sched.Agenda.add_task_seg_place_list place_s)
       | Shift x ->
         let usable_time_slots = get_usable_time_slots x.time_slots in
         Task_seg_place_gens.multi_task_segs_shift ~incre:x.incre
           ~task_segs:x.task_seg_related_data_list usable_time_slots
         |> OSeq.map (fun place_s ->
             base |> Sched.Agenda.add_task_seg_place_list place_s)
       | Split_and_shift x ->
         let usable_time_slots = get_usable_time_slots x.time_slots in
         ( match x.split_count with
           | Max_split split_count ->
             Task_seg_place_gens.single_task_seg_multi_splits_max_shift
               ~min_seg_size:x.min_seg_size ~max_seg_size:x.max_seg_size
               ~split_count ~incre:x.incre ~task_seg:x.task_seg_related_data
               usable_time_slots
           | Exact_split split_count ->
             Task_seg_place_gens.single_task_seg_multi_splits_exact_shift
               ~min_seg_size:x.min_seg_size ~max_seg_size:x.max_seg_size
               ~split_count ~incre:x.incre ~task_seg:x.task_seg_related_data
               usable_time_slots )
         |> OSeq.map (fun place_s ->
             base |> Sched.Agenda.add_task_seg_place_list place_s)
       | Split_even x ->
         let usable_time_slots = get_usable_time_slots x.time_slots in
         Task_seg_place_gens.single_task_seg_multi_even_splits ~incre:x.incre
           ~task_seg:x.task_seg_related_data ~buckets:x.buckets
           ~usable_time_slots
         |> OSeq.map (fun place_s ->
             base |> Sched.Agenda.add_task_seg_place_list place_s)
       | Time_share x ->
         let usable_time_slots = get_usable_time_slots x.time_slots in
         let s =
           Task_seg_place_gens.multi_task_segs_interleave
             ~interval_size:x.interval_size
             ~task_segs:x.task_seg_related_data_list usable_time_slots
         in
         Seq.return (base |> Sched.Agenda.add_task_seg_place_seq s)
       | Push_toward x ->
         let usable_time_slots = get_usable_time_slots x.time_slots in
         let s1 =
           Task_seg_place_gens.single_task_seg_shift ~cur_pos:x.target
             ~incre:x.incre ~task_seg:x.task_seg_related_data usable_time_slots
           |> OSeq.take 1
         in
         let s2 =
           Task_seg_place_gens.single_task_seg_shift_rev
             ~cur_end_pos_exc:x.target ~incre:x.incre
             ~task_seg:x.task_seg_related_data usable_time_slots
           |> OSeq.take 1
         in
         let s =
           OSeq.sorted_merge
             ~cmp:(fun (_id1, start1, end_exc1) (_id2, start2, end_exc2) ->
                 let distance1 =
                   let mid1 = (end_exc1 +^ start1) /^ 2L in
                   Int64.abs (mid1 -^ x.target)
                 in
                 let distance2 =
                   let mid2 = (end_exc2 +^ start2) /^ 2L in
                   Int64.abs (mid2 -^ x.target)
                 in
                 compare distance1 distance2)
             s1 s2
           |> OSeq.take 1
         in
         Seq.return (base |> Sched.Agenda.add_task_seg_place_seq s))
    (sched_req_record_data_list |> List.to_seq)

let backtracking_search_multi ~start ~end_exc ~base
    (sched_req_records : Sched_req_ds.sched_req_record list) : Sched.sched Seq.t
  =
  sched_req_records
  |> Sched_req_ds.sort_sched_req_record_list_by_flexibility_score
  |> List.fold_left
    (fun sched_seq sched_req ->
       Seq.flat_map
         (fun sched ->
            brute_force_single ~start ~end_exc ~base:sched sched_req)
         sched_seq)
    (Seq.return base)

let backtracking_search_pending ~start ~end_exc
    ~include_sched_reqs_partially_within_time_period ~up_to_sched_req_id_inc
    ~base : Sched.sched Seq.t =
  let sched_req_records, base =
    Sched.Sched_req.Allocate_task_segs.allocate_task_segs_for_pending_sched_reqs
      ~start ~end_exc ~include_sched_reqs_partially_within_time_period
      ~up_to_sched_req_id_inc base
  in
  backtracking_search_multi ~start ~end_exc ~base sched_req_records
