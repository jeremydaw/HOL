signature KernelTypes =
sig

(*---------------------------------------------------------------------------
    Elements in signatures are determined by a (name,theory) pair.
    The reference cell is for uniqueness: an interactive session may
    create more than one such pair, and they need to be distinguished.
 ---------------------------------------------------------------------------*)

(*---------------------------------------------------------------------------*
 *                  HOL types                                                *
 *---------------------------------------------------------------------------*)

type id = KernelSig.kernelid

datatype ('name, 'ty) tbs = Set of 'ty | Unset of 'name | Noref of 'ty ;

type tyconst = id * int

datatype hol_type = Tyv of string
                  | Tyapp of tyconst * hol_type list
                  | Tyref of (string, hol_type) tbs ref ;


(*---------------------------------------------------------------------------*
 * HOL terms are represented internally using deBruijn indices and explicit  *
 * substitutions. Externally, as always, the interface is to a               *
 * name-carrying syntax.                                                     *
 *---------------------------------------------------------------------------*)

datatype holty = GRND of hol_type
               | POLY of hol_type

val to_hol_type : holty -> hol_type

type tmconst = id * holty

datatype term = Fv of string * hol_type
              | Bv of int
              | Const of tmconst
              | Comb  of term * term
              | Abs   of term * term
              | Tmref of (string * hol_type, term) tbs ref
              | Clos  of term Subst.subs * term;


(*---------------------------------------------------------------------------
     The representation of theorems, and their tags
 ---------------------------------------------------------------------------*)

datatype thm = THM of Tag.tag * term HOLset.set * term


(*---------------------------------------------------------------------------
     The type of witnesses, used by the definition principles.
 ---------------------------------------------------------------------------*)

  datatype witness
       = TERM of term
       | THEOREM of thm
end
