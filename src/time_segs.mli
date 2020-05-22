exception Time_segs_are_not_sorted

exception Time_segs_are_not_disjoint

module Check : sig
  val check_if_valid : Time_seg.t Seq.t -> Time_seg.t Seq.t

  val check_if_not_empty : Time_seg.t Seq.t -> Time_seg.t Seq.t

  val check_if_sorted : Time_seg.t Seq.t -> Time_seg.t Seq.t

  val check_if_disjoint : Time_seg.t Seq.t -> Time_seg.t Seq.t

  val check_if_normalized : Time_seg.t Seq.t -> Time_seg.t Seq.t
end

module Filter : sig
  val filter_invalid : Time_seg.t Seq.t -> Time_seg.t Seq.t

  val filter_invalid_list : Time_seg.t list -> Time_seg.t list

  val filter_empty : Time_seg.t Seq.t -> Time_seg.t Seq.t

  val filter_empty_list : Time_seg.t list -> Time_seg.t list
end

module Sort : sig
  val sort_time_segs_list :
    ?skip_check:bool -> Time_seg.t list -> Time_seg.t list

  val sort_time_segs : ?skip_check:bool -> Time_seg.t Seq.t -> Time_seg.t Seq.t

  val sort_uniq_time_segs_list :
    ?skip_check:bool -> Time_seg.t list -> Time_seg.t list

  val sort_uniq_time_segs :
    ?skip_check:bool -> Time_seg.t Seq.t -> Time_seg.t Seq.t
end

val join : ?skip_check:bool -> Time_seg.t Seq.t -> Time_seg.t Seq.t

module Normalize : sig
  val normalize :
    ?skip_filter_invalid:bool ->
    ?skip_filter_empty:bool ->
    ?skip_sort:bool ->
    Time_seg.t Seq.t ->
    Time_seg.t Seq.t

  val normalize_list_in_seq_out :
    ?skip_filter_invalid:bool ->
    ?skip_filter_empty:bool ->
    ?skip_sort:bool ->
    Time_seg.t list ->
    Time_seg.t Seq.t
end

module Slice : sig
  val slice :
    ?skip_check:bool ->
    ?start:int64 ->
    ?end_exc:int64 ->
    Time_seg.t Seq.t ->
    Time_seg.t Seq.t

  val slice_rev :
    ?skip_check:bool ->
    ?start:int64 ->
    ?end_exc:int64 ->
    Time_seg.t Seq.t ->
    Time_seg.t Seq.t
end

val invert :
  ?skip_check:bool ->
  start:int64 ->
  end_exc:int64 ->
  Time_seg.t Seq.t ->
  Time_seg.t Seq.t

val relative_complement :
  ?skip_check:bool ->
  not_mem_of:Time_seg.t Seq.t ->
  Time_seg.t Seq.t ->
  Time_seg.t Seq.t

module Merge : sig
  val merge :
    ?skip_check:bool -> Time_seg.t Seq.t -> Time_seg.t Seq.t -> Time_seg.t Seq.t

  val merge_multi_seq :
    ?skip_check:bool -> Time_seg.t Seq.t Seq.t -> Time_seg.t Seq.t

  val merge_multi_list :
    ?skip_check:bool -> Time_seg.t Seq.t list -> Time_seg.t Seq.t
end

module Round_robin : sig
  val collect_round_robin_non_decreasing :
    ?skip_check:bool -> Time_seg.t Seq.t list -> Time_seg.t option list Seq.t

  val merge_multi_seq_round_robin_non_decreasing :
    ?skip_check:bool -> Time_seg.t Seq.t Seq.t -> Time_seg.t Seq.t

  val merge_multi_list_round_robin_non_decreasing :
    ?skip_check:bool -> Time_seg.t Seq.t list -> Time_seg.t Seq.t
end

val intersect :
  ?skip_check:bool -> Time_seg.t Seq.t -> Time_seg.t Seq.t -> Time_seg.t Seq.t

module Union : sig
  val union :
    ?skip_check:bool -> Time_seg.t Seq.t -> Time_seg.t Seq.t -> Time_seg.t Seq.t

  val union_multi_seq :
    ?skip_check:bool -> Time_seg.t Seq.t Seq.t -> Time_seg.t Seq.t

  val union_multi_list :
    ?skip_check:bool -> Time_seg.t Seq.t list -> Time_seg.t Seq.t
end

val chunk :
  ?skip_check:bool ->
  ?drop_partial:bool ->
  chunk_size:int64 ->
  Time_seg.t Seq.t ->
  Time_seg.t Seq.t

module Sum : sig
  val sum_length : ?skip_check:bool -> Time_seg.t Seq.t -> int64

  val sum_length_list : ?skip_check:bool -> Time_seg.t list -> int64
end

module Bound : sig
  val min_start_and_max_end_exc :
    ?skip_check:bool -> Time_seg.t Seq.t -> (int64 * int64) option

  val min_start_and_max_end_exc_list :
    ?skip_check:bool -> Time_seg.t list -> (int64 * int64) option
end

val shift_list : offset:int64 -> Time_seg.t list -> Time_seg.t list

val equal : Time_seg.t list -> Time_seg.t list -> bool

val a_is_subset_of_b : a:Time_seg.t Seq.t -> b:Time_seg.t Seq.t -> bool

val count_overlap :
  ?skip_check:bool -> Time_seg.t Seq.t -> (Time_seg.t * int) Seq.t

module Serialize : sig
  val pack_time_segs :
    (int64 * int64) list -> ((int32 * int32) * (int32 * int32)) list
end

module Deserialize : sig
  val unpack_time_segs :
    ((int32 * int32) * (int32 * int32)) list -> (int64 * int64) list
end
