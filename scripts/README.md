# Coding conventions

## Guidelines

The bash scripts in [`scripts`](../scripts) directory <u>*must*</u> follow
these guidelines:

1. Each script must have `.sh` as its **extension**.
1. The scripts named `__my_script.sh` (two leading underscores) are meant to be
   **sourced in other scripts** (and should <u>*not*</u> be executed
   standalone). These type of scripts must implement include guards:

   ```bash
   [[ -v __MY_SCRIPT_SH ]] && return 0
   readonly __MY_SCRIPT_SH=1
   ```

1. The scripts named `_my_script.sh` (one leading underscore) are meant for
   **internal use only** (i.e. they should be executed by other scripts in
   [`scripts`](../scripts) directory).
1. Functions named `_my_fun` (one leading underscore) are meant for
   **internal use only** (i.e. they should be called only within the script
   defining them).
1. **All the environment/global variables** must be defined within
   [`__env.sh`](../scripts/__env.sh) script (and keep away from
   *name clashing*!).
1. **All the scripts** must source [`__env.sh`](../scripts/__env.sh) by
   executing in their very first line:

   ```bash
   source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh
   ```

   After that, the other scripts may be sourced using their relative path w.r.t.
   the root of the repository.

   > **⚠️ WARNING:** Sourcing [`__env.sh`](../scripts/__env.sh) automatically
      changes the working directory to the <u>*repository root*</u>.

## Dry-runs

- When developing, it may be useful to execute
   [`scripts/bump.sh`](../scripts/bump.sh), without opening a dummy PR on the
   remote repository. Hence, **autobump dry-runs** can be easily enabled by
   defining a *custom pull request number* through the environment variable
   `BUMP_DRYRUN_PR_NUMBER`, e.g.:

   ```bash
   BUMP_DRYRUN_PR_NUMBER=52 ./scripts/bump.sh
   ```

   In the example above, #52 pull request will be used as a dummy pull request
   for bumping (and updating) formulae/casks, without pushing on the remote or
   creating a new PR.

- Similarly, we can check the **pull request approval** (implemented in
   [`scripts/approve.sh`](../scripts/approve.sh)) without actually merging
   the PRs by setting the env variable `GH_APPROVE_DRYRUN`, e.g.:

   ```bash
   GH_APPROVE_DRYRUN=1 ./scripts/approve.sh "52:53" # or any colon-separated list of PR numbers.
   ```

   In the example above, we check if the pull requests #52 and #53 are eligible
   for auto-approvals (without merging them into the default branch).

- Similarly, it is possible to invoke the **branch clean-up script**
   [`scripts/clean_bump.sh`](../scripts/clean_bump.sh) without actually deleting
   any branch on the remote by setting the env variable `GH_DELETE_DRYRUN`,
   e.g.:

   ```bash
   GH_DELETE_DRYRUN=1 ./scripts/clean_bump.sh
   ```

## Automated tests

Some automated tests for bash scripts can be found in
[`scripts/automated_tests.sh`](../scripts/automated_tests.sh)!
