open Test_utils

let qc_unpack_is_inverse_of_pack_period =
  QCheck.Test.make ~count:5000 ~name:"qc_unpack_is_inverse_of_pack_period"
    QCheck.(pair time_pattern time_pattern)
    (fun p ->
       let p' =
         p
         |> Daypack_lib.Time_profile.Serialize.pack_period
         |> Daypack_lib.Time_profile.Deserialize.unpack_period
       in
       p = p')

let qc_unpack_is_inverse_of_pack_data =
  QCheck.Test.make ~count:5000 ~name:"qc_unpack_is_inverse_of_pack_data"
    QCheck.(list_of_size Gen.(int_bound 100) (pair time_pattern time_pattern))
    (fun periods ->
       let d = Daypack_lib.Time_profile.{ periods } in
       let d' =
         d
         |> Daypack_lib.Time_profile.Serialize.pack_data
         |> Daypack_lib.Time_profile.Deserialize.unpack_data
       in
       d = d')

let suite =
  [ qc_unpack_is_inverse_of_pack_period; qc_unpack_is_inverse_of_pack_data ]
