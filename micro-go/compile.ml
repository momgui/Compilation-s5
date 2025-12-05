open Mgoast
open Mips

let new_label =
  let cpt = ref (-1) in
  fun () -> incr cpt; Printf.sprintf "_label_%i" !cpt

let strings = Hashtbl.create 16

type loc = Local of int | Global of string
type env = (string * loc) list

let lookup id env =
  try List.assoc id env
  with Not_found -> failwith ("Variable non trouvée: " ^ id)

(* le résultat de l'expression est dans le registre $t0,
   la pile est utilisée pour les valeurs intermédiaires *)
let rec tr_expr env e = match e.edesc with
  | Int(n)  -> li t0 (Int64.to_int n)
  | Bool(b) -> li t0 (if b then 1 else 0)
  | String(s) ->
    let l = try Hashtbl.find strings s with Not_found ->
      let l = new_label() in
      Hashtbl.add strings s l;
      l
    in
    la t0 l
  | Nil -> li t0 0
  | Var(id) ->
    (match lookup id.id env with
     | Local o -> lw t0 o "$fp"
     | Global l -> la t0 l @@ lw t0 0 t0)
  | Unop(uop, e1) ->
    tr_expr env e1 @@
    (match uop with
     | Opp -> neg t0 t0
     | Not -> seq t0 t0 zero)
  | Binop(bop, e1, e2) ->
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
    tr_expr env e2
    @@ push t0
    @@ tr_expr env e1
    @@ pop t1
    @@ op t0 t0 t1
  | _ -> failwith "A compléter"


let rec tr_seq env fpoffset = function
  | []   -> nop
  | [i]  -> tr_instr env fpoffset i
  | i::s -> tr_instr env fpoffset i @@ tr_seq env fpoffset s

and tr_instr env fpoffset i = match i.idesc with 
  | If(c, s1, s2) ->
    let then_label = new_label()
    and end_label = new_label()
    in
    tr_expr env c
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
    b test_label
    @@ label code_label
    @@ tr_seq env fpoffset s
    @@ label test_label
    @@ tr_expr env c
    @@ bnez t0 code_label
  | Set([dst], [src]) ->
    tr_expr env src
    @@ (match dst.edesc with
        | Var(id) ->
          (match lookup id.id env with
           | Local o -> sw t0 o "$fp"
           | Global l -> la t1 l @@ sw t0 0 t1)
        | _ -> failwith "Affectation complexe non supportée")
  | Vars(ids, _, s) ->
    let (env', next_offset, alloc_size) =
      List.fold_left (fun (e, off, sz) id ->
          ((id.id, Local off) :: e, off - 4, sz + 4)
        ) (env, fpoffset, 0) ids
    in
    addi sp sp (-alloc_size)
    @@ tr_seq env' next_offset s
    @@ addi sp sp alloc_size
  | Inc(e) ->
    (match e.edesc with
     | Var(id) ->
       (match lookup id.id env with
        | Local o -> lw t0 o "$fp" @@ addi t0 t0 1 @@ sw t0 o "$fp"
        | Global l -> la t1 l @@ lw t0 0 t1 @@ addi t0 t0 1 @@ sw t0 0 t1)
     | _ -> failwith "Inc sur non-variable")
  | Dec(e) ->
    (match e.edesc with
     | Var(id) ->
       (match lookup id.id env with
        | Local o -> lw t0 o "$fp" @@ addi t0 t0 (-1) @@ sw t0 o "$fp"
        | Global l -> la t1 l @@ lw t0 0 t1 @@ addi t0 t0 (-1) @@ sw t0 0 t1)
     | _ -> failwith "Dec sur non-variable")
  | _ -> failwith "A compléter"

let tr_fun df =
  let env = List.mapi (fun i (id, _) -> (id.id, Local (4 + 4 * i))) df.params in
  label df.fname.id
  @@ push "$fp"
  @@ move "$fp" "$sp"
  @@ tr_seq env (-4) df.body
  @@ move "$sp" "$fp"
  @@ pop "$fp"
  @@ jr ra

let rec tr_ldecl = function
    Fun df::p -> tr_fun df @@ tr_ldecl p
  | _ :: p -> tr_ldecl p
  | [] -> nop

let tr_prog p =
  let text = tr_ldecl p in
  let data = Hashtbl.fold (fun s l acc -> label l @@ asciiz (Printf.sprintf "\"%s\"" s) @@ acc) strings nop in
  { text; data }
