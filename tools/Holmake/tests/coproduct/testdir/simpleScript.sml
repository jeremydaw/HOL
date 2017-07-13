open HolKernel Parse boolLib

val _ = new_theory "simple";

val _ = let
  val ostrm = TextIO.openOut "foo"
in
  TextIO.output(ostrm, "Generated by simpleScript.sml\n");
  TextIO.closeOut ostrm
end

val foo = save_thm("foo", DISCH_ALL (ASSUME ``p:bool``))


val _ = export_theory();