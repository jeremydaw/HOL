signature CoreKernel = sig
  structure Tag  : FinalTag
  structure Type : sig
    include FinalType
    val to_kt : hol_type -> KernelTypes.hol_type
    val unsafe_from_kt: KernelTypes.hol_type -> hol_type
    end

  structure Term : sig
    include FinalTerm        where type hol_type = Type.hol_type
    val to_kt : term -> KernelTypes.term
    val unsafe_from_kt: KernelTypes.term -> term
    end

  structure Thm  : sig
    include FinalThm         where type hol_type = Type.hol_type
                                      and type term     = Term.term
                                      and type tag      = Tag.tag
    (* fails - why? - because Thm.sig does not have
      where type thm = KernelTypes.thm 
      compare Term.sig and Type.sig 
      could we put it in? can't see why not
    val to_kt : thm -> KernelTypes.thm
    *)
    end 

  structure Net : Net               where type term = Term.term

end;
