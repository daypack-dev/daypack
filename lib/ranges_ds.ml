module Normalize = struct
  let normalize_to_inc (type a) ~(to_int64 : a -> int64)
      ~(of_int64 : int64 -> a) (x : a Range_ds.t) : a * a =
    match x with
    | `Range_inc (x, y) -> (x, y)
    | `Range_exc (x, y) -> (x, y |> to_int64 |> Int64.pred |> of_int64)

  let normalize_to_exc (type a) ~(to_int64 : a -> int64)
      ~(of_int64 : int64 -> a) (x : a Range_ds.t) : a * a =
    match x with
    | `Range_inc (x, y) -> (x, y |> to_int64 |> Int64.succ |> of_int64)
    | `Range_exc (x, y) -> (x, y)

  let normalize (type a) ?(skip_filter = false) ?(skip_sort = false)
      ~(to_int64 : a -> int64) ~(of_int64 : int64 -> a) (s : a Range_ds.t Seq.t)
    =
    s
    |> Seq.map (normalize_to_exc ~to_int64 ~of_int64)
    |> Seq.map (fun (x, y) -> (to_int64 x, to_int64 y))
    |> Time_slots.Normalize.normalize ~skip_filter ~skip_sort
    |> Seq.map (fun (x, y) -> (of_int64 x, of_int64 y))
    |> Seq.map (fun (x, y) -> `Range_exc (x, y))
end

module Flatten = struct
  let flatten_into_seq_internal_int64 ~(modulo : int64 option)
      ~(to_int64 : 'a -> int64) ~(of_int64 : int64 -> 'a) (t : 'a Range_ds.t) :
    'a Seq.t =
    match t with
    | `Range_inc (start, end_inc) -> (
        let start = to_int64 start in
        let end_inc = to_int64 end_inc in
        if start <= end_inc then
          Seq_utils.a_to_b_inc_int64 ~a:start ~b:end_inc |> Seq.map of_int64
        else
          match modulo with
          | None -> raise (Invalid_argument "End is before start")
          | Some modulo ->
            if modulo <= 0L then raise (Invalid_argument "Modulo is <= 0")
            else
              OSeq.append
                (Seq_utils.a_to_b_exc_int64 ~a:start ~b:modulo)
                (Seq_utils.a_to_b_inc_int64 ~a:0L ~b:end_inc)
              |> Seq.map of_int64 )
    | `Range_exc (start, end_exc) -> (
        let start = to_int64 start in
        let end_exc = to_int64 end_exc in
        if start <= end_exc then
          Seq_utils.a_to_b_exc_int64 ~a:start ~b:end_exc |> Seq.map of_int64
        else
          match modulo with
          | None -> raise (Invalid_argument "End is before start")
          | Some modulo ->
            if modulo <= 0L then raise (Invalid_argument "Modulo is <= 0")
            else
              OSeq.append
                (Seq_utils.a_to_b_exc_int64 ~a:start ~b:modulo)
                (Seq_utils.a_to_b_exc_int64 ~a:0L ~b:end_exc)
              |> Seq.map of_int64 )

  let flatten_into_seq_internal ~(modulo : int option) ~(to_int : 'a -> int)
      ~(of_int : int -> 'a) (t : 'a Range_ds.t) : 'a Seq.t =
    let modulo = Option.map Int64.of_int modulo in
    let of_int64 = Misc_utils.convert_of_int_to_int64 of_int in
    let to_int64 = Misc_utils.convert_to_int_to_int64 to_int in
    flatten_into_seq_internal_int64 ~modulo ~of_int64 ~to_int64 t

  let flatten_into_seq_big ?(modulo : int64 option) ~(to_int64 : 'a -> int64)
      ~(of_int64 : int64 -> 'a) (t : 'a Range_ds.t) : 'a Seq.t =
    flatten_into_seq_internal_int64 ~modulo ~of_int64 ~to_int64 t

  let flatten_into_list_big ?(modulo : int64 option) ~(to_int64 : 'a -> int64)
      ~(of_int64 : int64 -> 'a) (t : 'a Range_ds.t) : 'a list =
    flatten_into_seq_internal_int64 ~modulo ~of_int64 ~to_int64 t |> List.of_seq

  let flatten_into_seq ?(modulo : int option) ~(to_int : 'a -> int)
      ~(of_int : int -> 'a) (t : 'a Range_ds.t) : 'a Seq.t =
    flatten_into_seq_internal ~modulo ~of_int ~to_int t

  let flatten_into_list ?(modulo : int option) ~(to_int : 'a -> int)
      ~(of_int : int -> 'a) (t : 'a Range_ds.t) : 'a list =
    flatten_into_seq_internal ~modulo ~of_int ~to_int t |> List.of_seq
end

module Of_seq = struct
  let range_seq_of_seq_big (type a) ~(to_int64 : a -> int64)
      ~(of_int64 : int64 -> a) (s : a Seq.t) : a Range_ds.t Seq.t =
    s
    |> Seq.map (fun x -> `Range_inc (x, x))
    |> Normalize.normalize ~skip_filter:true ~skip_sort:true ~to_int64 ~of_int64

  let range_list_of_seq_big (type a) ~(to_int64 : a -> int64)
      ~(of_int64 : int64 -> a) (s : a Seq.t) : a Range_ds.t list =
    range_seq_of_seq_big ~to_int64 ~of_int64 s |> List.of_seq

  let range_seq_of_seq (type a) ~(to_int : a -> int) ~(of_int : int -> a)
      (s : a Seq.t) : a Range_ds.t Seq.t =
    let to_int64 = Misc_utils.convert_to_int_to_int64 to_int in
    let of_int64 = Misc_utils.convert_of_int_to_int64 of_int in
    range_seq_of_seq_big ~to_int64 ~of_int64 s

  let range_list_of_seq (type a) ~(to_int : a -> int) ~(of_int : int -> a)
      (s : a Seq.t) : a Range_ds.t list =
    range_seq_of_seq ~to_int ~of_int s |> List.of_seq
end

module Of_list = struct
  let range_seq_of_list_big (type a) ~(to_int64 : a -> int64)
      ~(of_int64 : int64 -> a) (l : a list) : a Range_ds.t Seq.t =
    List.to_seq l |> Of_seq.range_seq_of_seq_big ~to_int64 ~of_int64

  let range_list_of_list_big (type a) ~(to_int64 : a -> int64)
      ~(of_int64 : int64 -> a) (l : a list) : a Range_ds.t list =
    List.to_seq l
    |> Of_seq.range_seq_of_seq_big ~to_int64 ~of_int64
    |> List.of_seq

  let range_seq_of_list (type a) ~(to_int : a -> int) ~(of_int : int -> a)
      (l : a list) : a Range_ds.t Seq.t =
    List.to_seq l |> Of_seq.range_seq_of_seq ~to_int ~of_int

  let range_list_of_list (type a) ~(to_int : a -> int) ~(of_int : int -> a)
      (l : a list) : a Range_ds.t list =
    List.to_seq l |> Of_seq.range_seq_of_seq ~to_int ~of_int |> List.of_seq
end

module Compress = struct
  let compress_seq_big (type a) ~(to_int64 : a -> int64)
      (s : a Range_ds.t Seq.t) : a Range_ds.t Seq.t =
    let rec aux (to_int64 : a -> int64) (acc : a Range_ds.t option)
        (s : a Range_ds.t Seq.t) : a Range_ds.t Seq.t =
      match s () with
      | Seq.Nil -> (
          match acc with None -> Seq.empty | Some x -> Seq.return x )
      | Seq.Cons (x, rest) -> (
          match acc with
          | None -> aux to_int64 (Some x) rest
          | Some acc -> (
              match Range_ds.Merge.merge_big ~to_int64 acc x with
              | None -> fun () -> Seq.Cons (acc, aux to_int64 (Some x) rest)
              | Some res -> aux to_int64 (Some res) rest ) )
    in
    aux to_int64 None s

  let compress_list_big (type a) ~(to_int64 : a -> int64)
      (l : a Range_ds.t list) : a Range_ds.t list =
    List.to_seq l |> compress_seq_big ~to_int64 |> List.of_seq

  let compress_seq (type a) ~(to_int : a -> int) (s : a Range_ds.t Seq.t) :
    a Range_ds.t Seq.t =
    let to_int64 = Misc_utils.convert_to_int_to_int64 to_int in
    compress_seq_big ~to_int64 s

  let compress_list (type a) ~(to_int : a -> int) (l : a Range_ds.t list) :
    a Range_ds.t list =
    let to_int64 = Misc_utils.convert_to_int_to_int64 to_int in
    compress_list_big ~to_int64 l
end
