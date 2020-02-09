type t

val of_sched_list : Sched.sched list -> t

module In_place_head : sig
  val add_task :
    parent_user_id:int64 ->
    Task.task_data ->
    Task.task_inst_data list ->
    t ->
    Task.task

  val add_task_inst :
    parent_task_id:Task.task_id -> Task.task_inst_data -> t -> Task.task_inst

  val queue_sched_req : Sched_req.sched_req_data -> t -> Sched_req.sched_req
end

module Maybe_append_to_head : sig
  val remove_task : Task.task_id -> t -> unit

  val remove_task_inst : Task.task_inst_id -> t -> unit

  val sched :
    start:int64 ->
    end_exc:int64 ->
    include_sched_reqs_partially_within_time_period:bool ->
    up_to_sched_req_id_inc:Sched_req.sched_req_id option ->
    t ->
    (unit, unit) result
end

module Equal : sig
  val equal : t -> t -> bool
end

module Serialize : sig
  val list_to_base_and_diffs :
    Sched.sched list -> (Sched.sched * Sched.sched_diff list) option

  val to_base_and_diffs : t -> (Sched.sched * Sched.sched_diff list) option
end

module Deserialize : sig
  val list_of_base_and_diffs :
    Sched.sched -> Sched.sched_diff list -> Sched.sched list

  val of_base_and_diffs : Sched.sched -> Sched.sched_diff list -> t
end