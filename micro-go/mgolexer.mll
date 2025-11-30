{

  open Lexing
  open Mgoparser
  open Printf  

  exception Error of string

  (* Pour l'insertion automatique des points-virgules *)
  let pending_semi = ref false

  (* Tokens après lesquels on insère un ; automatiquement si suivi d'une nouvelle ligne *)
  let insert_semi_after = function
    | IDENT _ | INT _ | STRING _ 
    | TRUE | FALSE | NIL | RETURN
    | RPAR | END | INCR | DECR -> true
    | _ -> false

  (* Wrapper pour mettre à jour pending_semi après chaque token *)
  let emit tok =
    pending_semi := insert_semi_after tok;
    tok

  let keyword_or_ident =
    let h = Hashtbl.create 17 in
    List.iter (fun (s, k) -> Hashtbl.add h s k)
      [ "package",    PACKAGE;
        "import",     IMPORT;
        "type",       TYPE;      
        "struct",     STRUCT;
        "if",         IF;
        "else",       ELSE;
        "for",        FOR;
        "func",       FUNC;
        "return",     RETURN;
        "var",        VAR;
        "true",       TRUE;
        "false",      FALSE;
        "nil",        NIL;
      ];
    fun s ->
      try Hashtbl.find h s
      with Not_found -> IDENT s


  let decode_string s =
    let b = Buffer.create (String.length s) in
    let i = ref 0 in
    let len = String.length s in
    while !i < len do
      match s.[!i] with
      | '\\' -> if !i + 1 >= len then raise (Error "untermined escape in string");
        begin match s.[!i +1] with
        | 'n' -> Buffer.add_char b '\n'; i := !i + 2
        | 't' -> Buffer.add_char b '\t'; i := !i + 2
        | '"' -> Buffer.add_char b '"'; i := !i + 2
        | '\\'-> Buffer.add_char b '\\'; i := !i + 2
        | c -> raise (Error (sprintf "invalid escape sequence \\%c" c))
        end
      | c -> let code = Char.code c in
        if code < 32 || code > 126 then
        raise (Error (sprintf "invalid char in string (code %d)" code));
        Buffer.add_char b c;
        i := !i + 1
      done;
      Buffer.contents b
}

let digit = ['0'-'9']
let hexa = ['0'-'9' 'a'-'f' 'A'-'F']
let number = "0x" hexa+ | "0X" hexa+ | digit+
let alpha = ['a'-'z' 'A'-'Z' '_']
let ident = alpha (alpha | digit)*
let char =
  [^ '"' '\\'] 
  | "\\\""
  | "\\\\" 
  | "\\n"
  | "\\t"


rule token = parse
  | ['\n']              { new_line lexbuf; 
                          if !pending_semi then begin
                            pending_semi := false;
                            SEMI
                          end else
                            token lexbuf }
  | [' ' '\t' '\r']+    { token lexbuf }

  | "/*"                { comment lexbuf; token lexbuf }
  | "//" [^ '\n']* '\n' { new_line lexbuf;
                          if !pending_semi then begin
                            pending_semi := false;
                            SEMI
                          end else
                            token lexbuf }
  | "//" [^ '\n']* eof  { if !pending_semi then begin
                            pending_semi := false;
                            SEMI
                          end else
                            EOF }

  | number as n         { emit (try INT(Int64.of_string n) 
                              with _ -> raise (Error "literal constant too large")) }

  | '"' (char* as s) '"' { emit (STRING(decode_string(s))) }

  | ident as id         { emit (keyword_or_ident id) }

  | ";"  { emit SEMI }
  | "("  { emit LPAR }
  | ")"  { emit RPAR }
  | "{"  { emit BEGIN }
  | "}"  { emit END }
  | "*"  { emit STAR }

  | "==" { emit EQ }
  | "!=" { emit NEQ }
  | "<=" { emit LE }
  | ">=" { emit GE }
  | "<"  { emit LT }
  | ">"  { emit GT }

  | "+"  { emit PLUS }
  | "-"  { emit MINUS }
  | "%"  { emit PERCENT }

  | "&&" { emit AND }
  | "||" { emit OR }

  | "="  { emit ASSIGN }
  | ":=" { emit COLONASSIGN }
  | "++" { emit INCR }
  | "--" { emit DECR }
  | "/"  { emit DIV }

  | ","  { emit COMMA }
  | "."  { emit DOT }
  | "!"  { emit NOT }



  | _    { raise (Error ("unknown character : " ^ lexeme lexbuf)) }
  | eof  { EOF }

and comment = parse
  | '\n' { new_line lexbuf; comment lexbuf }
  | "*/" { () }
  | _    { comment lexbuf }
  | eof  { raise (Error "unterminated comment") }
