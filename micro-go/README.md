# Compilateur Micro-Go

Ce projet est un compilateur pour le langage **Micro-Go**, un sous-ensemble du langage Go, réalisé dans le cadre du cours de compilation. Le compilateur est écrit en OCaml et génère du code assembleur MIPS.

## Auteurs

Projet réalisé par Legal Arthur et Mombellet Guillaume.

## Fonctionnalités implémentées

Le projet couvre l'ensemble des phases de compilation :

### 1. Analyse Lexicale (`mgolexer.mll`)
- Reconnaissance de tous les lexèmes du langage (mots-clés, identifiants, littéraux entiers et chaînes, opérateurs).
- Gestion des commentaires (`//` et `/* ... */`).
- **Bonus** : Implémentation de l'insertion automatique des points-virgules selon les règles du langage Go (détection des fins de ligne après certains tokens).

### 2. Analyse Syntaxique (`mgoparser.mly`)
- Grammaire complète définie avec Menhir.
- Construction de l'Arbre de Syntaxe Abstraite (AST) défini dans `mgoast.ml`.
- Gestion des priorités des opérateurs.

### 3. Analyse Sémantique / Typage (`typechecker.ml`)
- Vérification de la bonne formation des types.
- Gestion des environnements pour les variables, les fonctions et les structures.
- Vérification des types des expressions et des instructions.
- Gestion spécifique de la valeur `nil` et des comparaisons de pointeurs.
- Vérification des duplicats (champs de structure, noms de fonctions/structures).

### 4. Génération de Code (`compile.ml`)
- Traduction de l'AST en instructions MIPS.
- Gestion de la pile pour les calculs intermédiaires et les variables locales.
- Allocation dynamique de mémoire pour les structures (via l'appel système `sbrk`).
- Gestion des appels de fonctions et du passage de paramètres.
- Implémentation des fonctions primitives comme `fmt.Print`.

## Structure du projet

Le code source se trouve dans le dossier `micro-go/` :

- `mgoast.ml` : Définition de l'arbre de syntaxe abstraite.
- `mgolexer.mll` : Spécification de l'analyseur lexical (ocamllex).
- `mgoparser.mly` : Spécification de la grammaire (menhir).
- `typechecker.ml` : Logique de vérification de types.
- `compile.ml` : Logique de génération de code assembleur.
- `mgoc.ml` : Point d'entrée du compilateur.

## Tests

Un ensemble de tests est fourni dans le dossier `tests/`. Ces fichiers couvrent différents aspects du langage (arithmétique, structures, boucles, etc.).

Exemple de test :
- `arith.go` : Tests des opérations arithmétiques.
- `point.go` : Tests sur les structures et pointeurs.
- `shadow.go` : Tests sur la portée des variables.

Des tests ont été ajouté par rapport au squelette initial pour couvrir un maximum de cas limites.


