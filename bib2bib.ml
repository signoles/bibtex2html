

open Printf;;
open Bibtex;;
  

  

(*
let test_criteria fields =
  try
    let date = List.assoc "YEAR" fields
    in date = [Id("1996")]
  with
      Not_found -> false
;;
*)

(*
let test_criteria fields =
  try
    let [String(author)] = List.assoc "AUTHOR" fields
    in 
      try

	let _ = Str.search_forward 
		  (Str.regexp_case_fold "claude march")
		  author
		  0
	in true
      with
	  Not_found -> false
  with
      Not_found -> false
;;
*)



(* command-line arguments *)

let input_file_names = ref ([] : string list);;

let bib_output_file_name = ref "";;

let cite_output_file_name = ref "";;

let get_input_file_name f =
  input_file_names := f :: !input_file_names;;

let condition = ref Condition.True;;

let add_condition c = 
  try
    let c = Parse_condition.condition c in
    condition := if !condition = Condition.True then c 
    else Condition.And(!condition,c)
  with
      Condition_lexer.Lex_error msg ->
	prerr_endline ("Lexical error in condition: "^msg);
	exit 1
    | Parsing.Parse_error ->
	prerr_endline "Syntax error in condition";
	exit 1
;;



let args_spec =
  [
    ("-ob", 
     Arg.String(fun f -> bib_output_file_name := f),"bib output file name");
    ("-oc",
     Arg.String(fun f -> cite_output_file_name := f),"citations output file name");
    ("-c", Arg.String(add_condition),"filter condition")
  ]




let output_cite_file keys = 
  try
    let ch =
      if !cite_output_file_name = "" then stdout
      else open_out !cite_output_file_name
    in
      KeySet.iter (fun k -> output_string ch (k ^ "\n")) keys;
      if !cite_output_file_name <> "" then close_out ch
  with
      Sys_error msg ->
	prerr_endline ("Cannot write output citations file (" ^ msg ^ ")");
	exit 1
;;


let output_bib_file biblio keys =
if !bib_output_file_name = "" then 
  printf "No bib output (no file name specified)\n"
else
  try    
    let ch = open_out !bib_output_file_name in 
    let cmd = List.fold_right (fun s t -> " "^s^t) (Array.to_list Sys.argv) "" in
      Biboutput.output_bib false ch 
	((Comment "This file has been generated by bib2bib") ::
	 (Comment ("Command line:" ^ cmd)) ::
	 biblio )
	keys;
      close_out ch
  with
      Sys_error msg ->
	prerr_endline ("Cannot write output bib file (" ^ msg ^ ")");
	exit 1
;;


let main () =
  Arg.parse args_spec get_input_file_name "Usage: bib2bib [options] <input file names>\nOptions are:";
  (*
  Condition.print !condition; Printf.printf "\n";
  *)
  let all_entries =
    List.fold_left
      (fun l file -> l@(Readbib.read_entries_from_file file))
      []
      (List.rev !input_file_names)
  in 
  let expanded = Bibtex.expand_abbrevs all_entries
  in
  let matching_keys =
    Bibfilter.filter expanded 
      (fun k f -> Condition.evaluate_cond k f !condition) 
  in
  let needed_keys =
    Bibfilter.saturate all_entries matching_keys
  in
    (*
      let needed_entries =
      List.filter
      (fun entry -> StringSet.mem (get_key entry) needed_keys)
      all_entries
      in		 
      List.iter print_command needed_entries
    *)
    output_cite_file matching_keys;
    output_bib_file all_entries (Some needed_keys)
;;




Printexc.catch main ();;

  
  
