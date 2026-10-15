# Coding conventions

The bash scripts in this directory <u>*must*</u> follow these guidelines:

1. Each script must have `*.sh` as its **extension**.
1. The scripts named `__*.sh` (two leading underscores) are meant to be
   **sourced in other scripts** (and should <u>*not*</u> be executed
   standalone).
1. The scripts named `_*.sh` (one leading underscore) are meant for
   **internal use only** (i.e. they should be executed by other scripts in this
   directory).
