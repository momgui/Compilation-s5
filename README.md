# micro-go

Compilateur pour un sous-ensemble du langage **Go**, écrit en **OCaml**.
Projet du cours de compilation (S5) de la Licence Math-Info de l'Université Paris-Saclay.

## Objectif

Implémenter les étapes classiques d'un compilateur :

1. **Analyse lexicale** (`mgolexer.mll`, via `ocamllex`)
2. **Analyse syntaxique** (`mgoparser.mly`, via `Menhir`) → construction de l'AST (`mgoast.ml`)
3. **Analyse sémantique / typage** (`typechecker.ml`)
4. **Production de code** — à venir

## Sous-ensemble de Go supporté

- Déclarations de variables typées
- Types de base : `int`, `bool`, `string`, structures
- Fonctions et signatures multi-retour
- Contrôle de flux : `if`, `for`
- Expressions arithmétiques et logiques

## Structure

```
micro-go/
├── mgoast.ml         # Types de l'arbre syntaxique abstrait
├── mgolexer.mll      # Analyseur lexical (ocamllex)
├── mgoparser.mly     # Grammaire (Menhir)
├── typechecker.ml    # Vérification de types
├── mgoc.ml           # Point d'entrée du compilateur
├── dune / dune-project
├── Makefile
└── tests/            # Programmes Go de test
```

## Compilation & utilisation

Prérequis : OCaml ≥ 4.14, `dune`, `menhir`.

```bash
cd micro-go
make
./mgoc.exe tests/hello.go
```

## Statut

Projet cours en cours de développement — le lexer, le parser et une partie du typage sont fonctionnels. La génération de code n'est pas encore implémentée.

## Auteurs

- Guillaume Mombellet
- Arthur

Sous le cadre du cours de compilation, Licence Math-Info, Université Paris-Saclay.
