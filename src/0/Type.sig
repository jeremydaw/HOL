signature Type =
sig

  include FinalType where type hol_type = KernelTypes.hol_type

  val to_kt : hol_type -> hol_type
  val unsafe_from_kt: hol_type -> hol_type
end
