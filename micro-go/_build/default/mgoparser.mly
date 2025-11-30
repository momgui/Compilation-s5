%{

  open Lexing
  open Mgoast

  exception Error

  let mk_expr d sp ep =
    { edesc = d; eloc = (sp,ep) }

  let mk_instr d sp ep =
    { idesc = d; iloc = (sp,ep) }

%} 

%token <int64> INT
%token <string> IDENT
%token <string> STRING
%token PACKAGE IMPORT TYPE STRUCT
%token LPAR RPAR BEGIN END SEMI
%token IF ELSE RETURN
%token FOR FUNC VAR TRUE FALSE NIL
%token EQ NEQ LT GT LE GE ASSIGN PLUS MINUS STAR DIV PERCENT
%token DOT COMMA NOT AND OR COLONASSIGN INCR DECR
%token EOF
%right ASSIGN COLONASSIGN
%left OR
%left AND
%nonassoc EQ NEQ LT GT LE GE /* == != < > <= >= */
%left PLUS MINUS
%left STAR DIV PERCENT
%right NOT UMINUS


%start prog
%type <Mgoast.program> prog

%%

prog:
| PACKAGE main=IDENT SEMI decls=list(decl) EOF
    { if main="main" then (false, decls) else raise Error}
| PACKAGE main=IDENT SEMI IMPORT fmt=STRING SEMI decls=list(decl) EOF
    { if main="main" && fmt="fmt" then (true, decls) else raise Error} 
;

ident:
  id = IDENT { { loc = $startpos, $endpos; id = id } }
;

decl:
  | TYPE id=ident STRUCT BEGIN fl=loption(fields) END SEMI
    { Struct { sname = id; fields = List.flatten fl; } }
  | FUNC fname=ident LPAR params=separated_list(COMMA,param) RPAR 
    ret=return_type body=bloc SEMI? {Fun { fname; params = List.flatten params; return = ret; body }}
;

bloc:
  BEGIN s=seq END       { s }
;

seq:
  |                       { [] }
  | i=instr SEMI s=seq    { i :: s }
  | i=instr               { [i] }  (* permet d'omettre le ; avant } *)
;


param:
  ids=separated_nonempty_list(COMMA,ident) t=typ { List.map (fun id -> (id,t)) ids }
;

return_type:
|                                          { [] }
| t=typ                                    { [t] }
| LPAR ts=separated_list(COMMA,typ) RPAR   { ts }
;

typ:
  | STAR name=IDENT       { TStruct name }
  | id=IDENT              {
      match id with
      | "int"    -> TInt
      | "bool"   -> TBool
      | "string" -> TString
      | _        -> failwith "unknown type"
    }

;

varstyp:
  | ids=separated_nonempty_list(COMMA,ident) t=typ  
      { List.map (fun id -> (id, t)) ids }
;

fields:
| xt=varstyp SEMI?              { [xt]      }
| xt=varstyp SEMI xtl = fields  { xt :: xtl }
;

expr:
| e = expr_desc { mk_expr e $startpos $endpos}
;

expr_desc:
| n=INT                                   { Int n }
| TRUE                                    { Bool true }
| FALSE                                   { Bool false }
| s=STRING                                { String s }
| NIL                                     { Nil }
| id=ident                                { Var id }
| LPAR e1=expr RPAR                       { e1.edesc }
| e=expr DOT id=ident                     { Dot(e,id) }
| fn=ident LPAR 
    args=separated_list(COMMA,expr) RPAR  
      {match fn.id,args with
       | "new", [{edesc= Var ty;_ }] -> New ty.id
       | _                          -> Call(fn,args) }
| e=expr DOT meth=ident LPAR 
    args=separated_list(COMMA,expr) RPAR  
      { match e.edesc with
        | Var mod_ when mod_.id = "fmt" && meth.id = "Print" -> Print args
        | _ -> failwith "method calls not supported"
      }
| MINUS e=expr %prec UMINUS               { Unop (Opp,e)}
| NOT e=expr                              { Unop (Not, e) }
| lhs=expr PLUS rhs=expr                  { Binop (Add, lhs, rhs) }
| lhs=expr MINUS rhs=expr                 { Binop (Sub, lhs, rhs) }
| lhs=expr STAR rhs=expr                  { Binop (Mul, lhs, rhs) }
| lhs=expr DIV rhs=expr                   { Binop (Div, lhs, rhs) }
| lhs=expr PERCENT rhs=expr               { Binop (Rem, lhs, rhs) }
| lhs=expr EQ rhs=expr                    { Binop (Eq, lhs, rhs) }
| lhs=expr NEQ rhs=expr                   { Binop (Neq, lhs, rhs) }
| lhs=expr LT rhs=expr                    { Binop (Lt, lhs, rhs) }
| lhs=expr LE rhs=expr                    { Binop (Le, lhs, rhs) }
| lhs=expr GT rhs=expr                    { Binop (Gt, lhs, rhs) }
| lhs=expr GE rhs=expr                    { Binop (Ge, lhs, rhs) }
| lhs=expr AND rhs=expr                   { Binop (And, lhs, rhs) }
| lhs=expr OR rhs=expr                    { Binop (Or, lhs, rhs) }
;

instr:
 i = instr_desc {mk_instr i $startpos $endpos }
;

instr_desc:
| i=instr_simple                            { i }
| i=instr_if                                { i }
| b=bloc                                    { Block b }
| VAR ids=separated_nonempty_list(COMMA,ident) 
  t=option(typ) 
  init=option(preceded(ASSIGN, separated_nonempty_list(COMMA,expr)))       
    { 
      (* var x,y type = e1,e2  devient Vars([x,y], type, [Set([x],[e1]); Set([y],[e2])]) 
         ou juste une déclaration de base genre var x,y type *)
      match init with
      | None -> Vars(ids, t, [])
      | Some es -> 
          let lhs = List.map (fun id -> { edesc = Var id; eloc = id.loc }) ids in
          let set_instr = mk_instr (Set(lhs, es)) $startpos $endpos in
          Vars(ids, t, [set_instr])
    }
| RETURN es=separated_list(COMMA,expr)      { Return(es) }
| FOR b=bloc                                {
    let e = { edesc = Bool true; eloc = ($startpos, $endpos) } in
    For (e, b)
  }
| FOR e=expr b=bloc                         { For(e, b) }
| FOR i1=instr_simple SEMI e=expr 
    SEMI i2=instr_simple b=bloc     
    { 
      (* for i1; e; i2 b  équivaut à  { i1; for e { b; i2 } } *)
      let i1_instr = mk_instr i1 $startpos(i1) $endpos(i1) in
      let i2_instr = mk_instr i2 $startpos(i2) $endpos(i2) in
      let inner_body = b @ [i2_instr] in
      let for_instr = mk_instr (For(e, inner_body)) $startpos $endpos in
      Block [i1_instr; for_instr]
    }
| FOR i1=instr_simple SEMI e=expr SEMI b=bloc     
    { 
      (* for i1; e; b  (sans i2) *)
      let i1_instr = mk_instr i1 $startpos(i1) $endpos(i1) in
      let for_instr = mk_instr (For(e, b)) $startpos $endpos in
      Block [i1_instr; for_instr]
    }
| FOR SEMI e=expr SEMI i2=instr_simple b=bloc     
    { 
      (* for ; e; i2 b  (sans i1) *)
      let i2_instr = mk_instr i2 $startpos(i2) $endpos(i2) in
      let inner_body = b @ [i2_instr] in
      For(e, inner_body)
    }
| FOR SEMI e=expr SEMI b=bloc     
    { 
      (* for ; e; b  (ni i1 ni i2, équivalent à for e b) *)
      For(e, b)
    }
;

instr_simple:
| e=expr                                    { Expr e }
| e=expr INCR                               { Inc e }
| e=expr DECR                               { Dec e }
| es=separated_nonempty_list(COMMA,expr)
    ASSIGN es2=separated_nonempty_list(COMMA,expr)    { Set (es,es2) }
| es=separated_nonempty_list(COMMA,expr)
    COLONASSIGN es2=separated_nonempty_list(COMMA,expr)    
      { 
        (* x := e est équivalent à var x = e, donc c'est une déclaration *)
        (* On vérifie que les expressions à gauche sont des variables *)
        let ids = List.map (fun e -> 
          match e.edesc with 
          | Var id -> id 
          | _ -> failwith "expected variable in :=") es in
        let set_instr = Set(es, es2) in
        (* On retourne Vars avec l'initialisation *)
        Vars(ids, None, [mk_instr set_instr $startpos $endpos])
      }
;

instr_if:
| IF e=expr b=bloc                          { If(e, b, []) }
| IF e=expr b=bloc ELSE b2=bloc             { If(e, b, b2) }
| IF e=expr b=bloc ELSE 
    i=instr_if                              { If(e, b, [mk_instr i $startpos(i) $endpos(i)]) } 