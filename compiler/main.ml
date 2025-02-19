(***********************************************************************)
(*                                                                     *)
(*                              CamlIDL                                *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1999 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Lesser General Public License LGPL v2.1 *)
(*                                                                     *)
(***********************************************************************)

(* $Id: main.ml,v 1.16 2002-04-19 13:24:29 xleroy Exp $ *)

open Printf
open Clflags
open Utils
open Idltypes
open File

let process_file name =
  let pref =
    if Filename.check_suffix name ".idl"
    then Filename.chop_suffix name ".idl"
    else name in
  let intf = Normalize.normalize_file name in
  eval_constants intf;
  let oc = open_out (pref ^ ".mli") in
  begin try
    gen_mli_file oc intf;
    close_out oc
  with x ->
    close_out oc; remove_file (pref ^ ".ml"); raise x
  end;
  let oc = open_out (pref ^ ".ml") in
  begin try
    gen_ml_file oc intf;
    close_out oc
  with x ->
    close_out oc; remove_file (pref ^ ".ml"); raise x
  end;
  let oc = open_out (pref ^ "_stubs.c") in
  begin try
    gen_c_stub oc intf;
    close_out oc
  with x ->
    close_out oc; remove_file (pref ^ "_stubs.c"); raise x
  end;
  if !Clflags.gen_header then begin
    let oc = open_out (pref ^ ".h") in
    begin try
      gen_c_header oc intf;
      close_out oc
    with x ->
      close_out oc; remove_file (pref ^ ".h"); raise x
    end
  end

let _ =
  try
    Arg.parse
      ["-I", Arg.String(fun s -> search_path := !search_path @ [s]),
         "<dir>  Add directory to search path";
       "-D", Arg.String(fun s -> prepro_defines := !prepro_defines @ [s]),
         "<symbol>  Pass -D<symbol> to the C preprocessor";
       "-cpp", Arg.Set use_cpp,
         "  Pass the .idl files through the C preprocessor (default)";
       "-nocpp", Arg.Clear use_cpp,
         "  Do not pass the .idl files through the C preprocessor";
       "-prepro", Arg.String(fun s -> preprocessor := s),
         "<cmd>  Use <cmd> as the preprocessor instead of the C preprocessor";
       "-header", Arg.Set gen_header,
         "  Generate a .h file containing all type definitions";
       "-no-include", Arg.Clear include_header,
         "  Do not #include the .h file in the generated .c file";
       "-prefix-all-labels", Arg.Set prefix_all_labels,
         "  Prefix all ML name of record labels with name of enclosing struct";
       "-keep-labels", Arg.Set keep_labels,
         "  Do not prefix ML names of record labels, even if ambiguous"
      ]
      process_file
      "Usage: camlidl [options]<.idl file> ... <.idl file>\nOptions are:\n"
  with Error ->
    exit 2
