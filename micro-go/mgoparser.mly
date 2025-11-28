%{

  open Lexing
  open Mgoast

  exception Error

%} 

%token <int64> INT
%token <string> IDENT
%token <string> STRING
%token PACKAGE IMPORT TYPE STRUCT
%token LPAR RPAR BEGIN END SEMI STAR
%token IF ELSE RETURN
%token FOR FUNC VAR TRUE FALSE NIL
%token EQ NEQ LT GT LE GE ASSIGN PLUS MINUS MULT DIV PERCENT
%token DOT COMMA NOT AND OR SLASH COLONASSIGN INCR DECR
%token EOF
%right ASSIGN COLONASSIGN
%left OR
%left AND
%nonassoc EQ NEQ LT GT LE GE /* == != < > <= >= */
%left PLUS MINUS
%left MULT DIV PERCENT
%right NOT UMINUS

%start prog
%type <Mgoast.program> prog

%%

let mk_expr d sp ep =
  { edesc = d; eloc = (sp,ep) }

let mk_instr d sp ep =
  { idesc = d; iloc = (sp,ep) }

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
    ret=return_type body=bloc {Fun { fname; params = List.flatten params; return = ret; body }}
;

bloc:
  BEGIN s=seq END       { s }
;

seq:
  |                     { [] }
  | i=instr SEMI s=seq  { i :: s }
;


param:
  ids=separated_nonempty_list(COMMA,ident) t=type { List.map (fun id -> (id,t)) ids }
;

return_type:
|                                          { [] }
| t=type                                   { [t] }
| LPAR ts=separated_list(COMMA,type) RPAR  { ts }
;

type:
  | STAR name=IDENT       { TStruct name }
  | id=IDENT              {
      match id with
      | "int"    -> TInt
      | "bool"   -> TBool
      | "string" -> TString
      | _        -> parse_error "unknown type"
    }

;

varstyp:
  |  x=ident t=type               {[(x,t)]}
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
| mod_=ident DOT meth=ident LPAR 
    args=separated_list(COMMA,expr) RPAR  
      { if mod_.id = "fmt" && meth.id = "Print" 
        then Print args
        else parse_error "module unknown"}
| MINUS e=expr %prec UMINUS               { Unop (Opp,e)}
| NOT e=expr                              { Unop (Not, e) }
| lhs=expr PLUS rhs=expr                  { Binop (Add, lhs, rhs) }
| lhs=expr MINUS rhs=expr                 { Binop (Sub, lhs, rhs) }
| lhs=expr MULT rhs=expr                  { Binop (Mul, lhs, rhs) }
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
  t=option(type) 
  e=option(ASSIGN separated_nonempty_list(COMMA,expr))       
                                            { Vars(ids, t, e)}
| RETURN es=separated_list(COMMA,expr)      { Return(es) }
| FOR b=bloc {
    let loc = Parsing.rhs_start_pos 1 in        (* donne la localisation de la boucle FOR. Normalement ça ne devrait
                                                jamais causer d'erreur mais apparement c'est plus propre *)
    let e = { edesc = Bool true; eloc = loc } in
    For (e, b)
  }
| FOR e=expr b=bloc                         { For(e, b) }
| FOR i=option(instr_simple) SEMI e=expr 
    SEMI i2=option(instr_simple) b=bloc     { For(e, b) }
;

instr_simple:
| e=expr                                    { Expr e }
| e=expr INCR                               { Inc e }
| e=expr DECR                               { Dec e }
| es=separated_nonempty_list(COMMA,expr)
    ASSIGN es2=separated_nonempty_list(COMMA,expr)    { Set (es,es2) }
| es=separated_nonempty_list(COMMA,Var(ident))
    COLONASSIGN es2=separated_nonempty_list(COMMA,expr)    { Set (es,es2) }
;

instr_if:
| IF e=expr b=bloc                          { If(e, b, []) }
| IF e=expr b=bloc ELSE b2=bloc             { If(e, b, b2) }
| IF e=expr b=bloc ELSE 
  i=[mk_instr d sp ep]                      { If(e, b, i) }