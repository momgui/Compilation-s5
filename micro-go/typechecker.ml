open Mgoast

exception Error of Mgoast.location * string
let error loc s = raise (Error (loc,s))

let type_error loc ty_actual ty_expected =
  error loc (Printf.sprintf "expected %s, got %s"
           (typ_to_string ty_expected) (typ_to_string ty_actual))

module Env = Map.Make(String)

(* 3 environnements pour stocker
     les variables avec leur type,
     les fonctions avec leur signature
     les structures avec leurs champs
*)
    
type tenv = typ Env.t
type fenv = (typ list * typ list) Env.t 
type senv = (ident * typ) list Env.t

let dummy = "_"

let add_env l tenv =
  List.fold_left (fun env (x, t) -> if x.id = dummy then env else Env.add x.id t env) tenv l

let prog (fmt,ld) =
  let has_print = ref false in
  (* collecte les noms des fonctions et des structures sans les vérifier *)
  let (fenv,senv) =
    List.fold_left
      (fun (fenv,senv) d ->
         match d with 
         | Struct(s) -> 
             if Env.mem s.sname.id senv then error s.sname.loc ("Structure " ^ s.sname.id ^ " already defined")
             else (fenv, Env.add s.sname.id s.fields senv)
         | Fun(f)   -> 
             if Env.mem f.fname.id fenv then error f.fname.loc ("Function " ^ f.fname.id ^ " already defined")
             else 
               let param_types = List.map (fun (_,t) -> t) f.params in
               (Env.add f.fname.id (param_types, f.return) fenv, senv))
      (Env.empty, Env.empty) ld
  in
  
  let check_typ t loc = 
    match t with
    | TBool | TInt | TString -> ()
    | TStruct s -> if not (Env.mem s senv) then error loc ("Unknown struct " ^ s)
  in

  let check_fields lf =
    let names = List.map (fun (id,_) -> id.id) lf in
    let sorted_names = List.sort String.compare names in
    let rec check_dup = function
      | [] | [_] -> ()
      | x::y::xs -> if x = y then failwith ("Duplicate field " ^ x) else check_dup (y::xs)
    in
    check_dup sorted_names;
    List.iter (fun (id,t) -> check_typ t id.loc) lf
  in

  (* J'ai simplifié la structure type_expr est maintenant détaché de check expr *)
  (*J'ai aussi divisé type_expr en 2 c'est plus simple pour tout ce qui est plusieurs var*)
  let rec type_expr e tenv : typ list = 
    match e.edesc with
    | Int _  -> [TInt]
    | Bool _   -> [TBool]
    | String _ -> [TString]
    | Unop (op,e) -> 
        let t = type_expr_one e tenv in
        (match op with
          | Opp -> if t = TInt then [TInt] else type_error e.eloc t TInt
          | Not -> if t = TBool then [TBool] else type_error e.eloc t TBool)
    | Binop (op, e1, e2) ->
          let is_nil e = match e.edesc with Nil -> true | _ -> false in
          if is_nil e1 && is_nil e2 then error e.eloc "Cannot compare nil with nil";
          
          if is_nil e1 then (
             let t2 = type_expr_one e2 tenv in
             match t2 with
             | TStruct _ -> 
                (match op with Eq | Neq -> [TBool] | _ -> error e.eloc "Nil only supports == and !=")
             | _ -> error e.eloc "Nil can only be compared to a pointer"
          ) else if is_nil e2 then (
             let t1 = type_expr_one e1 tenv in
             match t1 with
             | TStruct _ -> 
                (match op with Eq | Neq -> [TBool] | _ -> error e.eloc "Nil only supports == and !=")
             | _ -> error e.eloc "Nil can only be compared to a pointer"
          ) else (
              let t1 = type_expr_one e1 tenv in
              let t2 = type_expr_one e2 tenv in
              match op with
              | Add | Sub | Mul | Div | Rem ->
                  if t1 = TInt && t2 = TInt then [TInt]
                  else error e.eloc "Arithmetic operator expects int"
              | And | Or ->
                  if t1 = TBool && t2 = TBool then [TBool]
                  else error e.eloc "Logical operator expects bool"
              | Lt | Le | Gt | Ge ->
                  if t1 = TInt && t2 = TInt then [TBool]
                  else error e.eloc "Comparison operator expects int"
              | Eq | Neq ->
                  if t1 = t2 then [TBool]
                  else error e.eloc "Equality operator expects same types"
          )
    | Var id -> 
        [try Env.find id.id tenv with Not_found -> error id.loc ("Variable " ^ id.id ^ " not found")]
    | Dot (e, id) -> 
        let t = type_expr_one e tenv in
        (match t with
         | TStruct s -> 
             let fields = try Env.find s senv with Not_found -> error e.eloc ("Unknown struct " ^ s) in
             (match List.find_opt (fun (fid, _) -> fid.id = id.id) fields with
              | Some (_, t) -> [t]
              | None -> error id.loc ("Field " ^ id.id ^ " not found in struct " ^ s))
         | _ -> error e.eloc "Dot access requires a struct pointer")
    | New s -> 
        if Env.mem s senv then [TStruct s] else error e.eloc ("Unknown struct " ^ s)
    | Nil -> failwith "Nil has no type by itself" 
    | Call (f, args) ->
        let (ptypes, rtypes) = try Env.find f.id fenv with Not_found -> error f.loc ("Function " ^ f.id ^ " not found") in
        if List.length args <> List.length ptypes then error f.loc "Wrong number of arguments";
        List.iter2 (fun arg expected -> check_expr arg expected tenv) args ptypes;
        rtypes
    | Print args ->
        has_print := true;
        let types = List.flatten (List.map (fun e -> type_expr e tenv) args) in
        List.iter (fun t -> match t with TInt | TBool | TString | TStruct _ -> () ) types;
        [] 

  and type_expr_one e tenv = 
    match type_expr e tenv with
    | [t] -> t
    | _ -> error e.eloc "Expression expected to return a single value"

  and check_expr e expected tenv =
    if e.edesc = Nil then 
      match expected with TStruct _ -> () | _ -> error e.eloc "Nil must be a struct pointer"
    else
      let t = type_expr_one e tenv in
      if t <> expected then type_error e.eloc t expected
  in

  let type_lvalue e tenv =
    match e.edesc with
    | Var id -> (try Env.find id.id tenv with Not_found -> error e.eloc (Printf.sprintf "Variable '%s' non déclarée." id.id))
    | Dot (e, id) -> 
        let t = type_expr_one e tenv in
        (match t with
         | TStruct s -> 
             let fields = try Env.find s senv with Not_found -> error e.eloc ("Unknown struct " ^ s) in
             (match List.find_opt (fun (fid, _) -> fid.id = id.id) fields with
              | Some (_, t) -> t
              | None -> error id.loc ("Field " ^ id.id ^ " not found in struct " ^ s))
         | _ -> error e.eloc "Dot access requires a struct pointer")
    | _ -> error e.eloc "Invalid lvalue"
  in

  let rec check_instr i ret tenv = match i.idesc with
    | Expr e -> ignore (type_expr e tenv); tenv
    | Inc e | Dec e ->
        let t = type_lvalue e tenv in 
        if t <> TInt then type_error e.eloc t TInt;
        tenv
    | Set (es1,es2) -> 
      if List.length es1 = List.length es2 then
        List.iter2 (fun e1 e2 ->
          match e1.edesc with
          | Var {loc=_; id="_"} -> if e2.edesc <> Nil then ignore (type_expr e2 tenv)
          | _ ->
            let t1 = type_lvalue e1 tenv in
            if e2.edesc = Nil then
               match t1 with
               | TStruct _ -> ()
               | _ -> error e2.eloc "Cannot assign nil to non-pointer"
            else
               let t2 = type_expr_one e2 tenv in
               if t1 <> t2 then type_error e1.eloc t2 t1
        ) es1 es2
      else (
        let t2s = List.flatten (List.map (fun e -> type_expr e tenv) es2) in
        if List.length es1 <> List.length t2s then error i.iloc "Mismatch in assignment count";
        
        List.iter2 (fun e1 t2 ->
          match e1.edesc with
          | Var {loc=_; id="_"} -> ()
          | _ ->
            let t1 = type_lvalue e1 tenv in
            if t1 <> t2 then type_error e1.eloc t2 t1
        ) es1 t2s
      );
      tenv

    | If (b,s1,s2) -> 
        check_expr b TBool tenv;
        check_seq s1 ret tenv;
        check_seq s2 ret tenv;
        tenv
    | For (e,s) -> 
        check_expr e TBool tenv;
        check_seq s ret tenv;
        tenv
    | Block s -> 
        check_seq s ret tenv;
        tenv
    | Vars (ids, topt, init_seq) ->
        let new_types = 
          match topt, init_seq with
          | Some t, [] -> List.map (fun _ -> t) ids
          | Some t, [ { idesc = Set(_, rhs); _ } ] ->
              if List.length ids = List.length rhs then (
                 List.iter (fun e ->
                   if e.edesc = Nil then
                     match t with TStruct _ -> () | _ -> error e.eloc "Cannot assign nil to non-pointer"
                   else
                     let te = type_expr_one e tenv in
                     if te <> t then type_error e.eloc te t
                 ) rhs;
                 List.map (fun _ -> t) ids
              ) else (
                  let rhs_types = List.flatten (List.map (fun e -> type_expr e tenv) rhs) in
                  if List.length ids <> List.length rhs_types then error i.iloc "Mismatch in initialization count";
                  List.iter (fun rt -> if rt <> t then type_error i.iloc rt t) rhs_types;
                  List.map (fun _ -> t) ids
              )
          | None, [ { idesc = Set(_, rhs); _ } ] ->
              let rhs_types = List.flatten (List.map (fun e -> type_expr e tenv) rhs) in
              if List.length ids <> List.length rhs_types then error i.iloc "Mismatch in initialization count";
              rhs_types
          | _ -> error i.iloc "Invalid variable declaration"
        in
        let tenv' = List.fold_left2 (fun env id t -> 
            if id.id = dummy then env else Env.add id.id t env
        ) tenv ids new_types in
        tenv'

    | Return es -> 
        if List.length es = List.length ret then
           List.iter2 (fun e t_expected ->
             if e.edesc = Nil then
               match t_expected with TStruct _ -> () | _ -> error e.eloc "Cannot return nil as non-pointer"
             else
               let t = type_expr_one e tenv in
               if t <> t_expected then type_error e.eloc t t_expected
           ) es ret
        else (
           let t_es = List.flatten (List.map (fun e -> type_expr e tenv) es) in
           if List.length t_es <> List.length ret then error i.iloc "Wrong number of return values";
           List.iter2 (fun t expected -> if t <> expected then type_error i.iloc t expected) t_es ret
        );
        tenv

  and check_seq s ret tenv = 
    match s with
    | [] -> ()
    | i :: rest ->
        let tenv' = check_instr i ret tenv in
        check_seq rest ret tenv'
  in
  
  let rec returns_on_all_paths s =
    let instr_returns i = match i.idesc with
      | Return _ -> true
      | Block b -> returns_on_all_paths b
      | If (_, s1, s2) -> returns_on_all_paths s1 && returns_on_all_paths s2
      | For ({edesc=Bool true;_}, _) -> true
      | _ -> false
    in
    List.exists instr_returns s
  in

  let check_function f = 
    let tenv = add_env f.params Env.empty in
    check_seq f.body f.return tenv;
    if f.return <> [] && not (returns_on_all_paths f.body) then
      error f.fname.loc "Function does not return on all paths"
  in 
  (* Deuxieme passe car on peut déclarer des fonctions ou struct après les avoir appelé *)
  Env.iter (fun _ lf -> check_fields lf) senv;
  List.iter (function 
    | Fun f -> 
        List.iter (fun (_,t) -> check_typ t f.fname.loc) f.params;
        List.iter (fun t -> check_typ t f.fname.loc) f.return;
        check_function f
    | _ -> ()
  ) ld;

  (* Check main and fmt *)
  (try 
    let (params, ret) = Env.find "main" fenv in
    if params <> [] || ret <> [] then error (Lexing.dummy_pos, Lexing.dummy_pos) "main function must have no parameters and no return value"
   with Not_found -> error (Lexing.dummy_pos, Lexing.dummy_pos) "main function missing");
   
  if fmt && not !has_print then error (Lexing.dummy_pos, Lexing.dummy_pos) "fmt imported but not used";
  if not fmt && !has_print then error (Lexing.dummy_pos, Lexing.dummy_pos) "fmt used but not imported";
  ld


