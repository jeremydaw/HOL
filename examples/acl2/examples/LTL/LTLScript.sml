(*****************************************************************************)
(* Create "LTLTheory"                                                        *)
(*                                                                           *)
(* References:                                                               *)
(*                                                                           *)
(*  - Sandip Ray, John Matthews, Mark Tuttle, "Certifying Compositional      *)
(*    Model Checking Algorithms in ACL2".                                    *)
(*                                                                           *)
(*  - Edmund M. Clarke, Jr., Orna Grumberg, Doron A. Peled, "Model           *)
(*    Checking", The MIT Press, 1999.                                        *)
(*                                                                           *)
(*****************************************************************************)

(* record: ACL2 finite function as a "normalized" alist, where *)
(* an alist is ((key0 . val0) (key1 . val1) ... (keyn . valn)) *)

(*  Commands when run interactively:
quietdec := true;                                    (* Switch off output    *)
map load 
 ["pred_setLib","stringLib","finite_mapTheory"];
open
 pred_setTheory stringLib finite_mapTheory;
quietdec := false;                                   (* Restore output       *)
*)

(*****************************************************************************)
(* Boilerplate needed for compilation                                        *)
(*****************************************************************************)

open HolKernel Parse boolLib bossLib pred_setTheory;

(*****************************************************************************)
(* END BOILERPLATE                                                           *)
(*****************************************************************************)



(******************************************************************************
* Start a new theory called LTL
******************************************************************************)

val _ = new_theory "LTL";

(******************************************************************************
* Syntax
******************************************************************************)

(******************************************************************************
* LTL formulas are polymorphic: have type ``:'prop formula``
******************************************************************************)
val formula_def =
 Hol_datatype
  `formula = TRUE  (* one value satisfying ltl-constantp *)
           | FALSE (* one value satisfying ltl-constantp *)
           | ATOMIC     of 'prop (* in ACL2: a symbol satisfying ltl-variablep *)
           | NOT        of formula (* ~ *)
           | AND        of formula => formula (* & *)
           | OR         of formula => formula (* + *)
           | SOMETIMES  of formula (* F *)
           | ALWAYS     of formula (* G *)
           | NEXT       of formula (* X *)
           | UNTIL      of formula => formula (* U *)
           | WEAK_UNTIL of formula => formula`; (* W *)

(******************************************************************************
* Semantics
******************************************************************************)

(******************************************************************************
* A Kripke structure is a 4-tuple (S,R,L,S0) represented as a record:
* 
*  - S  : 'state set              a set of states
*  - R  : ('state # 'state) set   a transition relation
*  - L  : 'state -> 'prop set     maps a state to the true propositions in it
*  - S0 : 'state set              a subset of S, the initial states
*
* The type parameters are: ``: ('state,'prop)model``
* N.B. terms that follow are not contrained to use type variables 'state
* and 'prop, but may use 'a, 'b etc or whatever typechecking assigns.
******************************************************************************)

(******************************************************************************
* Annoyance fix: stop ``I`` and ``S`` parsing to the identity and S-combinators
******************************************************************************)
val _ = hide "I";
val _ = hide "S";


(******************************************************************************
* A Kripke structure has type ``: ('prop,'state)model``
******************************************************************************)
val model_def =
 Hol_datatype
  `model = 
    <| S: 'state set; (* list of states, where: *)
                      (* each state is a record mapping symbols (props) to T or NIL *)
       R: ('state # 'state) set; (* record mapping each state to a list of states *)
       L: 'state -> 'prop set; (* maps state to list of symbols true in that state *)
       S0:'state set |>`; (* list of states *)

(******************************************************************************
* Requirements for a model to be a well-formed Kripke structure
* (Note: the transition relation is not required to be total)
******************************************************************************)
val MODEL_def =
 Define
  `MODEL M =
    M.S0 SUBSET M.S /\ (!s s'. (s,s') IN M.R ==> s IN M.S /\ s' IN M.S)`;

(* See circuit-modelp in ACL2, which recognizes valid Kripke structures:

(defun circuit-modelp (m)
  (and ; Well-formed state: range of a state is contained in {T, NIL}
       (only-evaluations-p (states m) (variables m))
       ; Every well-formed state is in (states m)
       (all-evaluations-p (states m) (variables m))
       ; Only known props are mapped by a state
       (strict-evaluation-list-p (variables m) (states m))
       ; Every prop mapped to T by a state is in its labels
       (only-all-truths-p (states m) m (variables m))
       ; (Converse of the above:)
       ; Every prop in the labels of a state is mapped to T by the state
       (only-truth-p (states m) m)
       ; Every prop in the labels of a state is in the variables of the model
       (label-subset-vars (states m) m (variables m))
       ; For every state, all of its next states are legal states
       (transition-subset-p (states m) (states m) (transition m))
       ; Every initial state is a states
       (subset (initial-states m) (states m))
       ; There is at least one state
       (consp (states m))
       ; Same test as the transition-subset-p test above!
       (next-states-in-states m (states m))))
*)

(******************************************************************************
* PATH M s p is true iff p is a path of model M starting from s
******************************************************************************)
val PATH_def = 
 Define 
  `PATH M s p = (p 0 = s) /\ !i. M.R(p(i),p(i+1))`;

(******************************************************************************
* SUFFIX p in is the ith suffix of p
******************************************************************************)
val SUFFIX_def = 
 Define 
  `SUFFIX p i = \j. p(i+j)`;

(******************************************************************************
* SEM M p f defines the truth of formula f in path p of model M
******************************************************************************)
val SEM_def =
 Define
  `(SEM M p TRUE = T)
   /\
   (SEM M p FALSE = F)
   /\
   (SEM M p (ATOMIC a) = M.L (p 0) a)
   /\
   (SEM M p (NOT f) = ~(SEM M p f))
   /\
   (SEM M p (AND f1 f2) = SEM M p f1 /\ SEM M p f2)
   /\
   (SEM M p (OR f1 f2) = SEM M p f1 \/ SEM M p f2)
   /\
   (SEM M p (SOMETIMES f) = ?i. SEM M (SUFFIX p i) f)
   /\
   (SEM M p (ALWAYS f) = !i. SEM M (SUFFIX p i) f)
   /\
   (SEM M p (NEXT f) = SEM M (SUFFIX p 1) f)
   /\
   (SEM M p (UNTIL f1 f2) =
      ?i. SEM M (SUFFIX p i) f2 /\ !j. j < i ==> SEM M (SUFFIX p j) f1)
   /\
   (SEM M p (WEAK_UNTIL f1 f2) = 
     (?i. SEM M (SUFFIX p i) f2 /\ !j. j < i ==> SEM M (SUFFIX p j) f1)
     \/ 
     !i. SEM M (SUFFIX p i) f1)`;

(* M |= f *)
val SAT_def =
 Define
  `SAT M f = !p. (p 0) IN M.S0 /\ PATH M (p 0) p ==> SEM M p f`;

(* Definition of a bisimulation *)
(* B corresponds to \(s,s'). (circuit-bisim s M s' M' vars) for our
   particular M, M', and (somehow) vars *)
val BISIM_def =
 Define
  `BISIM M M' B =
    !s s'. s IN M.S /\ s' IN M'.S /\ B(s,s')
           ==>
(* The following is by c-bisimilar-states-have-labels-equal *)
           (M.L s = M'.L s')
           /\
           (!s1. s1 IN M.S /\ M.R(s,s1) 
                 ==> 
(* Witness s1' as (c-bisimilar-transition-witness-m->n s s1 M s' M' vars)
   and this works by theorems
   c-bisimilar-witness-member-of-states-m->n
   (says that s1' is IN M'.S)
   and
   c-bisimilar-witness-produces-bisimilar-states-m->n
   (says that B(s1,s1'))
*)
                 ?s1'. s1' IN M'.S /\ M'.R(s',s1') /\ B(s1,s1'))
           /\
           (!s1'. s1' IN M'.S /\ M'.R(s',s1') 
                 ==> 
(* Witness s1 as (c-bisimilar-transition-witness-n->m s M s' s1' M' vars)
   and this works by theorems
   c-bisimilar-witness-member-of-states-n->m
   (says that s1 is IN M.S)
   and
   c-bisimilar-witness-produces-bisimilar-states-n->m
   (says that B(s1,s1'))
*)                 ?s1. s1 IN M.S /\ M.R(s,s1) /\ B(s1,s1'))`;

(*

Here is what we called BISIM0: A particular bisimilarity relation:

(defun c-bisim-equiv (m n vars)
  (and ; m and n are well-formed Kripke structures:
       (circuit-modelp m)
       (circuit-modelp n)
       ; vars is contained in the variables of each structure:
       (subset vars (variables m))
       (subset vars (variables n))
       ; Every pair of "equal" (with respect to vars) states in m and
       ; n has the same set of successor states (with respect to vars).
       (well-formed-transition-p (states m) (transition m) (states n) (transition n) vars)
       (well-formed-transition-p (states n) (transition n) (states m) (transition m) vars)
       ; Every initial state of m is an initial state of n, and
       ; vice-versa, where we consider two states to be the same if
       ; they are the same when restricted to vars.
       (evaluation-eq-subset-p (initial-states m) (initial-states n) vars)
       (evaluation-eq-subset-p (initial-states n) (initial-states m) vars)))

; Note that circuit-bisim is similar, but has states p and q as
; additional formals and that p and q are states of m and n (resp.)
; that are equal with respect to vars.

*)

(* Definition of bisimulation equivalent *)
(* corresponds to (c-bisim-equiv M M' vars) *)
val BISIM_EQ_def =
 Define
  `BISIM_EQ M M' = 
    ?B. BISIM M M' B
(* This particular B will be
   \(s,s'). (circuit-bisim s M s' M' vars)
   for our particular M, M', and (somehow) vars
*)
        /\ 
(* s0' below is (c-bisimilar-initial-state-witness-m->n s0 M M' vars);
   see theorems
   c-bisimilar-equiv-implies-init->init-m->n
   (says s0' is an initial state of N)
   and
   c-bisimilar-equiv-implies-bisimilar-initial-states-m->n
   (says (s0,s0') IN B)
*)
        (!s0. s0 IN M.S0 ==> ?s0'. s0' IN M'.S0 /\ B(s0,s0'))
        /\ 
(* s0  below is (c-bisimilar-initial-state-witness-n->m M s0' M' vars) *)
   see theorems
   c-bisimilar-equiv-implies-init->init-n->m
   (says s0 is an initial state of M)
   and
   c-bisimilar-equiv-implies-bisimilar-initial-states-n->m
   (says (s0,s0') IN B)
*)
        (!s0'. s0' IN M'.S0 ==> ?s0. s0 IN M.S0 /\ B(s0,s0'))`;

(* Preparation for Lemma 1, p 10 of Ray et al. 
   Lemma 31, p 172 of Clarke et al. 
*)
val Lemma1a =
 prove
  (``!M M' B.
      MODEL M /\ MODEL M' /\ BISIM M M' B
      ==>
      !s s'. s IN M.S /\ s' IN M'.S /\ B(s,s') 
      ==> !p. PATH M s p ==> ?p'. PATH M' s' p' /\ !i. B(p i, p' i)``,
   RW_TAC std_ss [IN_DEF,PATH_def]
    THEN Q.EXISTS_TAC `PRIM_REC s' (\t n. @t'. M'.R(t,t') /\ B(p(n+1),t'))`    
    THEN SIMP_TAC std_ss [prim_recTheory.PRIM_REC_THM,GSYM FORALL_AND_THM]
    THEN Induct
    THEN FULL_SIMP_TAC pure_ss [DECIDE ``n + 1 = SUC n``,PATH_def]
    THEN RW_TAC pure_ss [prim_recTheory.PRIM_REC_THM]
    THEN FULL_SIMP_TAC pure_ss 
          (map (SIMP_RULE std_ss [IN_DEF]) [MODEL_def,BISIM_def,PATH_def])
    THEN METIS_TAC[]);

(* My original proof
val Lemma1b =
 prove
  (``MODEL M /\ MODEL M' /\ BISIM M M' B
     ==>
     !s s'. s IN M.S /\ s' IN M'.S /\ B(s,s') 
            ==> !p'. PATH M' s' p' ==> ?p. PATH M s p /\ !i. B(p i, p' i)``,
   RW_TAC std_ss [IN_DEF]
    THEN Q.EXISTS_TAC `PRIM_REC s (\t n. @t'. M.R(t,t') /\ B(t',p'(n+1)))`    
    THEN SIMP_TAC std_ss 
          [PATH_def,prim_recTheory.PRIM_REC_THM,GSYM FORALL_AND_THM]
    THEN Induct
    THEN FULL_SIMP_TAC pure_ss [DECIDE ``n + 1 = SUC n``,PATH_def]
    THEN RW_TAC pure_ss [prim_recTheory.PRIM_REC_THM]
    THEN FULL_SIMP_TAC pure_ss 
          (map (SIMP_RULE std_ss [IN_DEF]) [MODEL_def,BISIM_def,PATH_def])
    THEN METIS_TAC[]);
*)

(* Matt's proof by symmetry *)
val BISIM_SYM =
 store_thm
  ("BISIM_SYM",
   ``!M M' B. BISIM M M' B ==> BISIM M' M (\(x,y). B(y,x))``,
   RW_TAC std_ss [BISIM_def]
    THEN METIS_TAC[]);

val Lemma1b =
 prove
  (``!M M' B.
      MODEL M /\ MODEL M' /\ BISIM M M' B
       ==>
       !s s'. s IN M.S /\ s' IN M'.S /\ B(s,s') 
              ==> !p'. PATH M' s' p' ==> ?p. PATH M s p /\ !i. B(p i, p' i)``,
    METIS_TAC
     [BISIM_SYM,
       pairLib.GEN_BETA_RULE
        (ISPECL
          [``M':('a, 'c) model``, ``M:('a, 'b) model``, 
           ``\(x,y). (B:'b # 'c -> bool)(y,x)``]
          Lemma1a)]);

(* Lemma 1, p 10 of Ray et al. Lemma 31, p 172 of Clarke et al. *)
val Lemma1 = 
 time store_thm
  ("Lemma1",
    ``!M M' B.
       MODEL M /\ MODEL M' /\ BISIM M M' B
        ==>
        !s s'. s IN M.S /\ s' IN M'.S /\ B(s,s')
               ==> 
               (!p. PATH M s p ==> ?p'. PATH M' s' p' /\ !i. B(p i, p' i))
               /\
               (!p'. PATH M' s' p' ==> ?p. PATH M s p /\ !i. B(p i, p' i))``,
   METIS_TAC[Lemma1a,Lemma1b]);

(* Preparation for Lemma  2, p 10 of Ray et al. 
   Lemma 32, p 172 of Clarke et al. 
*)
val BISIM_SUFFIX =
 store_thm
  ("BISIM_SUFFIX",
   ``!p p'. (!i. B(p i, p' i)) ==> !n. (!i. B(SUFFIX p n i,SUFFIX p' n i))``,
   RW_TAC std_ss [SUFFIX_def]
    THEN Induct_on `n`
    THEN RW_TAC arith_ss []);

val PATH_SUFFIX =
 store_thm
  ("PATH_SUFFIX",
   ``!M p. PATH M s p ==> !n. PATH M (p n) (SUFFIX p n)``,
   RW_TAC std_ss [PATH_def,SUFFIX_def]
    THEN METIS_TAC[arithmeticTheory.ADD_ASSOC]);

val PATH_SUFFIX_IN =
 store_thm
  ("PATH_SUFFIX_IN",
   ``!M s p. MODEL M /\ M.S s /\ PATH M s p ==> !n i. M.S (SUFFIX p n i)``,
   RW_TAC std_ss [MODEL_def,PATH_def,SUFFIX_def,IN_DEF]
    THEN Induct_on `n` THEN Induct_on `i`
    THEN RW_TAC arith_ss []
    THEN FULL_SIMP_TAC arith_ss [DECIDE ``n + 1 = SUC n``]
    THEN METIS_TAC[]);

(* Lemma  2, p 10 of Ray et al. Lemma 32, p 172 of Clarke et al. *)
(* runtime: 4978.813s,    gctime: 743.494s,     systime: 9.298s. *)
val Lemma2 =
  time store_thm
  ("Lemma2",
   ``!M M' B.
      MODEL M /\ MODEL M' /\ BISIM M M' B
       ==>
       !f s s'. s IN M.S /\ s' IN M'.S /\ B(s,s') 
                ==>  !p p'. PATH M s p /\ PATH M' s' p' /\ (!i. B(p i, p' i))
                            ==> (SEM M p f = SEM M' p' f)``,
   REPEAT GEN_TAC
    THEN SIMP_TAC std_ss [IN_DEF]
    THEN STRIP_TAC
    THEN Induct
    THEN RW_TAC std_ss [SEM_def]
    THEN METIS_TAC
          [IN_DEF,MODEL_def,BISIM_def,PATH_def,BISIM_SUFFIX,
           PATH_SUFFIX,PATH_SUFFIX_IN]);

(* Theorem 1, p 10 of Ray et al. Theorem 14, p 175 of Clarke et al. *)
val Theorem1 =
 time store_thm
  ("Theorem1",
   ``!M M'. MODEL M /\ MODEL M' /\ BISIM_EQ M M' ==> !f. SAT M f = SAT M' f``,
   RW_TAC std_ss [BISIM_EQ_def,SAT_def,IN_DEF]
    THEN EQ_TAC
    THEN RW_TAC std_ss []
    THEN RES_TAC
    THENL
     [`s0 IN M.S /\ (p 0) IN M'.S` 
       by METIS_TAC[IN_DEF,pred_setTheory.SUBSET_DEF,MODEL_def]
       THEN `!p'. PATH M' (p 0) p' ==> ?p. PATH M s0 p /\ !i. B (p i,p' i)` 
        by METIS_TAC[Lemma1]
       THEN RES_TAC
       THEN `SEM M p' f` by METIS_TAC[PATH_def]
       THEN METIS_TAC[Lemma2,IN_DEF],
      `s0' IN M'.S /\ (p 0) IN M.S` 
        by METIS_TAC[IN_DEF,pred_setTheory.SUBSET_DEF,MODEL_def]
       THEN `?p'. PATH M' s0' p' /\ !i. B (p i,p' i)` by METIS_TAC[Lemma1]
       THEN RES_TAC
       THEN `SEM M' p' f` by METIS_TAC[PATH_def]
       THEN METIS_TAC[Lemma2,IN_DEF]]);

val _ = export_theory();
