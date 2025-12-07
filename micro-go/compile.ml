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
    (c2
    @@ push t0
    @@ c1
    @@ pop t1
    @@ op t0 t0 t1), res_ty
  | Call(f, args) ->
    let (_, return_types) = try Hashtbl.find fenv f.id with Not_found -> failwith ("Fonction inconnue: " ^ f.id) in
    let code_args = List.fold_right (fun arg code ->
      let (c, _) = tr_expr env arg in
      c @@ push t0 @@ code
    ) args nop in
    let ret_ty = match return_types with [t] -> t | [] -> TInt | _ -> failwith "Multi-return not supported" in
    code_args
    @@ jal f.id
    @@ addi sp sp (4 * List.length args), ret_ty
  | Print(args) ->
    let code = List.fold_left (fun acc arg ->
      let (c, ty) = tr_expr env arg in
      let print_call = match ty with
        | TInt -> li v0 1 @@ syscall (* print_int *)
        | TString -> li v0 4 @@ syscall (* print_string *)
        | TBool -> li v0 1 @@ syscall (* print_int 0/1 *)
        | _ -> nop (* TODO: struct printing *)
      in
      acc @@ c @@ move a0 t0 @@ print_call
    ) nop args in
    code, TInt


let rec tr_seq env fpoffset = function
  | []   -> nop
  | [i]  -> tr_instr env fpoffset i
  | i::s -> tr_instr env fpoffset i @@ tr_seq env fpoffset s

and tr_instr env fpoffset i = match i.idesc with 
  | If(c, s1, s2) ->
    let then_label = new_label()
    and end_label = new_label()
    in
    let (cc, _) = tr_expr env c in
    cc
    @@ bnez t0 then_label
    @@ tr_seq env fpoffset s2
    @@ b end_label
    @@ label then_label
    @@ tr_seq env fpoffset s1
    @@ label end_label

  | For(c, s) ->
    let test_label = new_label()
    and code_label = new_label()
    in
    let (cc, _) = tr_expr env c in
    b test_label
    @@ label code_label
    @@ tr_seq env fpoffset s
    @@ label test_label
    @@ cc
    @@ bnez t0 code_label
  | Set([dst], [src]) ->
    let (csrc, _) = tr_expr env src in
    csrc
    @@ (match dst.edesc with
        | Var(id) ->
          let (loc, _) = lookup id.id env in
          (match loc with
           | Local o -> sw t0 o "$fp"
           | Global l -> la t1 l @@ sw t0 0 t1)
        | Dot(e, id) ->
          let (cdst, ty_e) = tr_expr env e in
          let s_name = match ty_e with TStruct n -> n | _ -> failwith "Dot sur non-struct" in
          let (_, fields) = Hashtbl.find struct_layout s_name in
          let (offset, _) = Hashtbl.find fields id.id in
          push t0 (* save src value *)
          @@ cdst    (* compute struct address into t0 *)
          @@ pop t1  (* restore src value into t1 *)
          @@ sw t1 offset t0
        | _ -> failwith "Affectation complexe non supportée")
  | Set _ -> failwith "Affectation multiple non supportée"
  | Vars(ids, ty_opt, s) ->
    let ty = match ty_opt with Some t -> t | None -> TInt in
    let (env', next_offset, alloc_size) =
      List.fold_left (fun (e, off, sz) id ->
          ((id.id, (Local off, ty)) :: e, off - 4, sz + 4)
        ) (env, fpoffset, 0) ids
    in
    addi sp sp (-alloc_size)
    @@ tr_seq env' next_offset s
    @@ addi sp sp alloc_size
  | Inc(e) ->
    (match e.edesc with
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
  | Dec(e) ->
    (match e.edesc with
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
  | Block(s) -> tr_seq env fpoffset s
  | Expr(e) -> let (c, _) = tr_expr env e in c
  | Return([e]) -> let (c, _) = tr_expr env e in c @@ move sp "$fp" @@ pop "$fp" @@ pop ra @@ jr ra
  | Return([]) -> move sp "$fp" @@ pop "$fp" @@ pop ra @@ jr ra
  | Return _ -> failwith "Retours multiples non supportés"

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
