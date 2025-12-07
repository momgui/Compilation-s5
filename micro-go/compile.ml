open Mgoast
open Mips

let new_label =
  let cpt = ref (-1) in
  fun () -> incr cpt; Printf.sprintf "_label_%i" !cpt

let strings = Hashtbl.create 16
let fenv = Hashtbl.create 16
let struct_layout = Hashtbl.create 16

type loc = Local of int | Global of string
type env = (string * (loc * typ)) list

let lookup id env =
  try List.assoc id env
  with Not_found -> failwith ("Variable non trouvée: " ^ id)

(* le résultat de l'expression est dans le registre $t0,
   la pile est utilisée pour les valeurs intermédiaires *)
let rec tr_expr env e = match e.edesc with
  | Int(n)  -> li t0 (Int64.to_int n), TInt
  | Bool(b) -> li t0 (if b then 1 else 0), TBool
  | String(s) ->
    let l = try Hashtbl.find strings s with Not_found ->
      let l = new_label() in
      Hashtbl.add strings s l;
      l
    in
    la t0 l, TString
  | Nil -> li t0 0, TStruct "nil"
  | New n ->
    let (size, _) = Hashtbl.find struct_layout n in
    li a0 size
    @@ li v0 9
    @@ syscall
    @@ move t0 v0, TStruct n
  | Dot(e, id) ->
    let (c, ty) = tr_expr env e in
    let s_name = match ty with TStruct n -> n | _ -> failwith "Dot sur non-struct" in
    let (_, fields) = Hashtbl.find struct_layout s_name in
    let (offset, ty_field) = Hashtbl.find fields id.id in
    c
    @@ lw t0 offset t0, ty_field
  | Var(id) ->
    let (loc, ty) = lookup id.id env in
    (match loc with
     | Local o -> lw t0 o "$fp"
     | Global l -> la t0 l @@ lw t0 0 t0), ty
  | Unop(uop, e1) ->
    let (c1, _) = tr_expr env e1 in
    let res_ty = match uop with Opp -> TInt | Not -> TBool in
    c1 @@
    (match uop with
     | Opp -> neg t0 t0
     | Not -> seq t0 t0 zero), res_ty
  | Binop(bop, e1, e2) ->
    let (c1, _) = tr_expr env e1 in
    let (c2, _) = tr_expr env e2 in
    let op = match bop with
      | Add -> add
      | Sub -> sub
      | Mul -> mul
      | Div -> div
      | Rem -> rem
      | Lt  -> slt
      | Le  -> sle
      | Gt  -> sgt
      | Ge  -> sge
      | Eq  -> seq
      | Neq -> sne
      | And -> and_
      | Or  -> or_
    in
    let res_ty = match bop with
      | Add | Sub | Mul | Div | Rem -> TInt
      | _ -> TBool
    in
    (c1
    @@ push t0
    @@ c2
    @@ pop t1
    @@ op t0 t1 t0), res_ty
  | Call(f, args) ->
    let (_, return_types) = try Hashtbl.find fenv f.id with Not_found -> failwith ("Fonction inconnue: " ^ f.id) in
    let code_args = List.fold_right (fun arg code ->
      let (c, _) = tr_expr env arg in
      c @@ push t0 @@ code
    ) args nop in
    let (ret_ty, move_res) = match return_types with 
      | [t] -> t, move t0 v0 
      | [] -> TInt, nop 
      | _ -> TStruct "tuple", nop 
    in
    code_args
    @@ jal f.id
    @@ addi sp sp (4 * List.length args)
    @@ move_res, ret_ty
  | Print(args) ->
    let code = List.fold_left (fun acc arg ->
      match arg.edesc with
      | Call(f, _) ->
          let (_, return_types) = try Hashtbl.find fenv f.id with Not_found -> failwith ("Fonction inconnue: " ^ f.id) in
          if List.length return_types > 1 then
             let (c, _) = tr_expr env arg in
             (* Call puts values in v0, v1 *)
             (* We need to know types to print correctly, but tr_expr returns TStruct "tuple" *)
             (* For the project scope, assuming int for multi-return in Print is a reasonable fallback or we can look at return_types *)
             let print_code = List.fold_left2 (fun acc ty reg ->
                let p = match ty with
                  | TInt -> li v0 1 @@ move a0 reg @@ syscall
                  | TString -> li v0 4 @@ move a0 reg @@ syscall
                  | TBool -> 
                      let l_true = try Hashtbl.find strings "true" with Not_found -> let l = new_label() in Hashtbl.add strings "true" l; l in
                      let l_false = try Hashtbl.find strings "false" with Not_found -> let l = new_label() in Hashtbl.add strings "false" l; l in
                      let l_print_true = new_label() in
                      let l_end = new_label() in
                      bnez reg l_print_true
                      @@ la a0 l_false
                      @@ b l_end
                      @@ label l_print_true
                      @@ la a0 l_true
                      @@ label l_end
                      @@ li v0 4 @@ syscall
                  | TStruct _ -> li v0 1 @@ move a0 reg @@ syscall
                in acc @@ p
             ) nop return_types [v0; v1] (* Only supports 2 returns *)
             in
             acc @@ c @@ print_code
          else
             let (c, ty) = tr_expr env arg in
             let print_call = match ty with
                | TInt -> li v0 1 @@ syscall (* print_int *)
                | TString -> li v0 4 @@ syscall (* print_string *)
                | TBool ->
                    let l_true = try Hashtbl.find strings "true" with Not_found ->
                      let l = new_label() in Hashtbl.add strings "true" l; l in
                    let l_false = try Hashtbl.find strings "false" with Not_found ->
                      let l = new_label() in Hashtbl.add strings "false" l; l in
                    let l_print_true = new_label() in
                    let l_end = new_label() in
                    bnez a0 l_print_true
                    @@ la a0 l_false
                    @@ b l_end
                    @@ label l_print_true
                    @@ la a0 l_true
                    @@ label l_end
                    @@ li v0 4 @@ syscall
                | TStruct _ -> li v0 1 @@ syscall (* print address *)
              in
              acc @@ c @@ move a0 t0 @@ print_call
      | _ ->
          let (c, ty) = tr_expr env arg in
          let print_call = match ty with
            | TInt -> li v0 1 @@ syscall (* print_int *)
            | TString -> li v0 4 @@ syscall (* print_string *)
            | TBool ->
                let l_true = try Hashtbl.find strings "true" with Not_found ->
                  let l = new_label() in Hashtbl.add strings "true" l; l in
                let l_false = try Hashtbl.find strings "false" with Not_found ->
                  let l = new_label() in Hashtbl.add strings "false" l; l in
                let l_print_true = new_label() in
                let l_end = new_label() in
                bnez a0 l_print_true
                @@ la a0 l_false
                @@ b l_end
                @@ label l_print_true
                @@ la a0 l_true
                @@ label l_end
                @@ li v0 4 @@ syscall
            | TStruct _ -> li v0 1 @@ syscall (* print address *)
          in
          acc @@ c @@ move a0 t0 @@ print_call
    ) nop args in
    code, TInt


let rec tr_seq env fpoffset s =
  let size = List.fold_left (fun acc i -> 
    match i.idesc with 
    | Vars(ids, _, _) -> acc + (List.length ids * 4) 
    | _ -> acc
  ) 0 s in
  let code_alloc = if size = 0 then nop else addi sp sp (-size) in
  let code_free = if size = 0 then nop else addi sp sp size in
  
  let rec tr_seq_body env fpoffset = function
    | [] -> nop
    | i :: rest ->
        let (code, env', fpoffset') = tr_instr env fpoffset i in
        code @@ tr_seq_body env' fpoffset' rest
  in
  
  code_alloc @@ tr_seq_body env fpoffset s @@ code_free

and tr_instr env fpoffset i = match i.idesc with 
  | If(c, s1, s2) ->
    let then_label = new_label()
    and end_label = new_label()
    in
    let (cc, _) = tr_expr env c in
    let code = cc
    @@ bnez t0 then_label
    @@ tr_seq env fpoffset s2
    @@ b end_label
    @@ label then_label
    @@ tr_seq env fpoffset s1
    @@ label end_label
    in (code, env, fpoffset)

  | For(c, s) ->
    let test_label = new_label()
    and code_label = new_label()
    in
    let (cc, _) = tr_expr env c in
    let code = b test_label
    @@ label code_label
    @@ tr_seq env fpoffset s
    @@ label test_label
    @@ cc
    @@ bnez t0 code_label
    in (code, env, fpoffset)
  | Set(dsts, srcs) ->
    if List.length dsts = List.length srcs then
      let code_eval = List.fold_left (fun acc src ->
        let (c, _) = tr_expr env src in
        acc @@ c @@ push t0
      ) nop srcs in
      let code_assign = List.fold_right (fun dst acc ->
        let store_code = match dst.edesc with
          | Var(id) ->
            let (loc, _) = lookup id.id env in
            (match loc with
             | Local o -> sw t1 o "$fp"
             | Global l -> la t2 l @@ sw t1 0 t2)
          | Dot(e, id) ->
            let (cdst, ty_e) = tr_expr env e in
            let s_name = match ty_e with TStruct n -> n | _ -> failwith "Dot sur non-struct" in
            let (_, fields) = Hashtbl.find struct_layout s_name in
            let (offset, _) = Hashtbl.find fields id.id in
            push t1 (* save value to store *)
            @@ cdst    (* compute struct address into t0 *)
            @@ pop t2  (* restore value to store into t2 *)
            @@ sw t2 offset t0
          | _ -> failwith "Affectation complexe non supportée"
        in
        acc @@ pop t1 @@ store_code
      ) dsts nop in
      (code_eval @@ code_assign, env, fpoffset)
    else
       (match srcs with
       | [src] ->
         let (csrc, _) = tr_expr env src in
         (* Assume values in v0, v1 *)
         let code_assign = 
           match dsts with
           | [d1; d2] ->
             let store d reg = match d.edesc with
               | Var(id) ->
                 let (loc, _) = lookup id.id env in
                 (match loc with
                  | Local o -> sw reg o "$fp"
                  | Global l -> la t2 l @@ sw reg 0 t2)
               | _ -> failwith "Complex assignment in multi-return"
             in
             store d1 v0 @@ store d2 v1
           | _ -> failwith "Only 2 return values supported"
         in
         (csrc @@ code_assign, env, fpoffset)
       | _ -> failwith "Assignment mismatch")

  | Vars(ids, ty_opt, s) ->
    let types = match ty_opt with
      | Some t -> List.map (fun _ -> t) ids
      | None ->
        match s with
        | [{idesc=Set(_, srcs); _}] ->
           if List.length ids = List.length srcs then
             List.map (fun src -> let (_, t) = tr_expr env src in t) srcs
           else if List.length srcs = 1 then
             let src = List.hd srcs in
             match src.edesc with
             | Call(f, _) ->
                let (_, return_types) = try Hashtbl.find fenv f.id with Not_found -> failwith "Unknown function" in
                if List.length return_types = List.length ids then return_types
                else failwith "Mismatch in return values count"
             | _ -> failwith "Mismatch in assignment count"
           else failwith "Mismatch in assignment count"
        | _ -> failwith "Cannot infer type for Vars"
    in
    let (env', next_offset) =
      List.fold_left2 (fun (e, off) id ty ->
          ((id.id, (Local off, ty)) :: e, off - 4)
        ) (env, fpoffset) ids types
    in
    let code = tr_seq env' next_offset s in
    (code, env', next_offset)
  | Inc(e) ->
    let code = (match e.edesc with
     | Var(id) ->
       let (loc, _) = lookup id.id env in
       (match loc with
        | Local o -> lw t0 o "$fp" @@ addi t0 t0 1 @@ sw t0 o "$fp"
        | Global l -> la t1 l @@ lw t0 0 t1 @@ addi t0 t0 1 @@ sw t0 0 t1)
     | Dot(obj, id) ->
       let (c, ty) = tr_expr env obj in
       let s_name = match ty with TStruct n -> n | _ -> failwith "Dot sur non-struct" in
       let (_, fields) = Hashtbl.find struct_layout s_name in
       let (offset, _) = Hashtbl.find fields id.id in
       c
       @@ lw t1 offset t0
       @@ addi t1 t1 1
       @@ sw t1 offset t0
     | _ -> failwith "Inc sur non-variable")
    in (code, env, fpoffset)
  | Dec(e) ->
    let code = (match e.edesc with
     | Var(id) ->
       let (loc, _) = lookup id.id env in
       (match loc with
        | Local o -> lw t0 o "$fp" @@ addi t0 t0 (-1) @@ sw t0 o "$fp"
        | Global l -> la t1 l @@ lw t0 0 t1 @@ addi t0 t0 (-1) @@ sw t0 0 t1)
     | Dot(obj, id) ->
       let (c, ty) = tr_expr env obj in
       let s_name = match ty with TStruct n -> n | _ -> failwith "Dot sur non-struct" in
       let (_, fields) = Hashtbl.find struct_layout s_name in
       let (offset, _) = Hashtbl.find fields id.id in
       c
       @@ lw t1 offset t0
       @@ addi t1 t1 (-1)
       @@ sw t1 offset t0
     | _ -> failwith "Dec sur non-variable")
    in (code, env, fpoffset)
  | Block(s) -> (tr_seq env fpoffset s, env, fpoffset)
  | Expr(e) -> let (c, _) = tr_expr env e in (c, env, fpoffset)
  | Return(es) ->
    let code_eval = List.fold_left (fun acc e ->
      let (c, _) = tr_expr env e in
      acc @@ c @@ push t0
    ) nop es in
    let code_pop = match List.length es with
      | 0 -> nop
      | 1 -> pop v0
      | 2 -> pop v1 @@ pop v0
      | _ -> failwith "Max 2 returns supported"
    in
    (code_eval @@ code_pop @@ move sp "$fp" @@ pop "$fp" @@ pop ra @@ jr ra, env, fpoffset)

let tr_fun df =
  let n = List.length df.params in
  let env = List.mapi (fun i (id, ty) -> (id.id, (Local (8 + 4 * (n - 1 - i)), ty))) df.params in
  label df.fname.id
  @@ push ra
  @@ push "$fp"
  @@ move "$fp" "$sp"
  @@ tr_seq env (-4) df.body
  @@ move "$sp" "$fp"
  @@ pop "$fp"
  @@ pop ra
  @@ jr ra

let rec tr_ldecl = function
    Fun df::p -> tr_fun df @@ tr_ldecl p
  | _ :: p -> tr_ldecl p
  | [] -> nop

let tr_prog decls =
  List.iter (function
    | Fun df -> Hashtbl.add fenv df.fname.id (List.map snd df.params, df.return)
    | Struct s ->
      let size = List.length s.fields * 4 in
      let fields = Hashtbl.create 8 in
      List.iteri (fun i (id, ty) -> Hashtbl.add fields id.id (i * 4, ty)) s.fields;
      Hashtbl.add struct_layout s.sname.id (size, fields)
  ) decls;
  let text = tr_ldecl decls in
  let data = Hashtbl.fold (fun s l acc -> label l @@ asciiz (Printf.sprintf "\"%s\"" s) @@ acc) strings nop in
  let main_code =
    jal "main"
    @@ li v0 10
    @@ syscall
  in
  { text = main_code @@ text; data }
