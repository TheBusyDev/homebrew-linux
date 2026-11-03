# How to contribute

First off, thanks for taking the time to contribute! ❤️

All types of contributions are encouraged and valued. See the
[Table of contents](#table-of-contents) for different ways to help and details
about how this project handles them. Please make sure to read the relevant
section before making your contribution. It will make it a lot easier for the
maintainers and smooth out the experience for all involved. The community looks
forward to your contributions. 🎉

## Table of contents

- [Dependencies](#dependencies)
- [Developing a new formula/cask/script](#developing-a-new-formulacaskscript)
- [Developing bash scripts](#developing-bash-scripts)
- [Opening a new pull request](#opening-a-new-pull-request)
- [Pull request criteria for auto-approving](#pull-request-criteria-for-auto-approving)

## Dependencies

🍻 All the dependencies are listed into [`.deps`](./.deps) file and can be
installed using **Homebrew**... For this purpose, you can simply execute the
script:

```bash
./scripts/install_deps.sh
```

## Developing a new formula/cask/script

New formulae should be placed into [`Formula`](./Formula/), while new casks
should be placed into [`Casks`](./Casks/) directory, as `*.rb` files.
Bash script are located under [`scripts`](./scripts/) directory, with `.sh`
extension. \
New formulae/casks/scripts should pass all the checks performed by:

```bash
./scripts/style.sh
```

If some of the offenses found by this command can be fixed automatically, try
running:

```bash
./scripts/style.sh --fix
```

All the other offenses must be fixed manually.

See
[Developing bash scripts](#developing-bash-scripts) section for other
mandatory requirements when developing/debugging bash scripts.

See
[Pull request criteria for auto-approving](#pull-request-criteria-for-auto-approving)
section for further optional (yet really appreciated) requirements.

> **⚠️ WARNING:** This test on style is performed when opening a new PR and must
  pass without errors for the PR to be evaluated bt maintainers.

## Developing bash scripts

### General guidelines

The bash scripts in [`scripts`](../scripts) directory must follow these
guidelines:

1. Each script must have `.sh` as its extension.
1. The scripts named `__my_script.sh` (two leading underscores) are meant to be
  **sourced in other scripts** (and should <ins>*not*</ins> be executed
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
    the root of the repository (e.g. `source ./scripts/__my_script.sh`).

    > **⚠️ WARNING:** Sourcing [`__env.sh`](../scripts/__env.sh) automatically
      changes the working directory to the <ins>*repository root*</ins>.

### Dry-runs

- When developing, it may be useful to execute
  [`scripts/bump.sh`](../scripts/bump.sh), without opening a dummy PR on the
  remote repository. Hence, **autobump dry-runs** can be easily enabled by
  defining a *custom pull request number* through the environment variable
  `BUMP_DRYRUN_PR_NUMBER`, e.g.:

    ```bash
    BUMP_DRYRUN_PR_NUMBER=52 ./scripts/bump.sh
    ```

    In the example above, pull request
    [#52](https://github.com/TheBusyDev/homebrew-linux/pull/52)
    will be used as a dummy pull request for bumping (and updating)
    formulae/casks, without pushing on the remote or creating a new PR.

- Similarly, we can check the **pull request approval script** (implemented in
  [`scripts/approve.sh`](../scripts/approve.sh)) without actually merging
  the PRs by setting the env variable `GH_APPROVE_DRYRUN`, e.g.:

    ```bash
    GH_APPROVE_DRYRUN=1 ./scripts/approve.sh "52:53" # or any colon-separated list of PR numbers.
    ```

    In the example above, we check if the pull requests
    [#52](https://github.com/TheBusyDev/homebrew-linux/pull/52) and
    [#53](https://github.com/TheBusyDev/homebrew-linux/pull/53) are marked as
    eligible for auto-approvals (but they will not be merged into the default
    branch).

- Similarly, it is possible to invoke the **branch clean-up script**
  [`scripts/clean_bump.sh`](../scripts/clean_bump.sh) without actually deleting
  any branch on the remote by setting the env variable `GH_DELETE_DRYRUN`,
  e.g.:

    ```bash
    GH_DELETE_DRYRUN=1 ./scripts/clean_bump.sh
    ```

## Opening a new pull request

When opening a new PR, keep in mind that the following tests are performed and
must complete successfully for the PR to be evaluated bt maintainers.

1. Check on the style of the tap, performed by
  [`scripts/style.sh`](./scripts/style.sh) (see
  [Developing a new formula/cask/script](#developing-a-new-formulacaskscript)
  section).

1. Automated tests checking the functionalities of bash scripts, as implemented
  in [`scripts/automated_tests.sh`](./scripts/automated_tests.sh).

## Pull request criteria for auto-approving

This section contains all the optional requirements for new formulae/casks,
enabling the auto-approving mechanism.

The script [`scripts/bump.sh`](./scripts/bump.sh) is meant to check for updates
periodically and to create new PRs. To enhance the maintainability of this tap,
we designed an auto-approve script [`scripts/approve.sh`](./scripts/approve.sh),
which checks the following requirements and, if they are met, it merges the PR
automatically using GitHub action bot.

In particular, the PR must modify only the following entries in the `*.rb` files
to be approved automatically:

1. <ins>version entry</ins>:

    ```diff
    -  version "1.1.05"
    +  version "1.1.18"
    ```

1. <ins>sha256 entry</ins>, either in the format:

    ```diff
    -  sha256 "3379c99890359dcff55aab7f7b3286f87c988d1da2fd616e6a9e305fb0a1de9e"
    +  sha256 "d86ff9de63d94c8b8f1f6b14d23c55af4b88e8207bf2893890892a6a97b1ad54"
    ```

    or in the following format, if the formula/cask is designed for both `arm64`
    and `x86_64` architectures:

    ```diff
    -  sha256 arm64_linux:  "cb4ce5183a29b1a13aeb6409d5430c896fa35aad21097be1f874fbb4cf1e7e62",
    -         x86_64_linux: "fcc1ccb435685adcc748287bbde524589569deedb6b4ad5560071583cbe00ae0"
    +  sha256 arm64_linux:  "e84bf20d112fdb73c29b85b317ba50d5a48bea05c0711509669c8466639e9eb6",
    +         x86_64_linux: "48f658052e54e020a1c1be7b37ac0f9ae39f07e8ccda805c63f053cfda72b2be"
    ```

You can check out the PR
[#84](https://github.com/TheBusyDev/homebrew-linux/pull/84/changes)
for an example of PR approved successfully.
