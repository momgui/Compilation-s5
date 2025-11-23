{

  open Lexing
  open Mgoparser
  open Printf  

  exception Error of string

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
let number = digit+
let alpha = ['a'-'z' 'A'-'Z' '_']
let ident = alpha (alpha | digit)*
let str_char =
  [^ '"' '\\'] 
  | "\\\""
  | "\\\\" 
  | "\\n"
  | "\\t"

  
rule token = parse
  | ['\n']            { new_line lexbuf; token lexbuf }
  | [' ' '\t' '\r']+  { token lexbuf }

  | "/*"                { comment lexbuf; token lexbuf }
  | "//" [^ '\n']* '\n' { new_line lexbuf; token lexbuf }
  | "//" [^ '\n']* eof  { EOF }

  | number as n  { try INT(Int64.of_string n) 
                   with _ -> raise (Error "literal constant too large") }
  | ident as id  { keyword_or_ident id }

  | ";"  { SEMI }
  | "("  { LPAR }
  | ")"  { RPAR }
  | "{"  { BEGIN }
  | "}"  { END }
  | "*"  { STAR }

  | _    { raise (Error ("unknown character : " ^ lexeme lexbuf)) }
  | eof  { EOF }

and comment = parse
  | '\n' { new_line lexbuf; comment lexbuf }
  | "*/" { () }
  | _    { comment lexbuf }
  | eof  { raise (Error "unterminated comment") }
