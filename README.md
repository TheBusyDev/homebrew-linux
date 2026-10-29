# Homebrew Linux, a tap designed for Homebrew + Linux users! 🍻

This is a **Homebrew tap**, designed for all the Linux users out there! 🐧 \
For those who do not know yet, Homebrew is the *Package Manager for Everywhere*,
originally developed for MacOS and now supporting Linux:
check out this fantastic project on their official website <https://brew.sh/>. 🤓

## Table of contents

- [Dependencies](#dependencies)
- [How to use this tap](#how-to-use-this-tap)
- [Objectives](#objectives)
- [What is not planned](#what-is-not-planned)
- [What is still missing](#what-is-still-missing-todo-list)

## Dependencies

🍺 Clearly, **Homebrew** must be installed to use this tap:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

More detailed information may be found on
[Homebrew official website](https://brew.sh/).

## How to use this tap

✅ Once **Homebrew** is installed, you have to trust this tap:

```bash
brew tap thebusydev/linux
brew trust thebusydev/linux
```

🧑‍💻 Now you can install and enjoy custom Linux formulae/casks, e.g.:

```bash
brew install thebusydev/linux/hello    # Just a dummy hello-world formula.
brew install thebusydev/linux/firefox  # Firefox, the popular web browser by Mozilla.
brew install thebusydev/linux/msedit   # Microsoft Edit, a TUI text editor.
brew install thebusydev/linux/paraview # ParaView, a tool for data visualization.
brew install thebusydev/linux/ventoy   # Ventoy, used to create bootable images.
brew install thebusydev/linux/vscode   # VSCode, Microsoft IDE.
brew install thebusydev/linux/vscodium # VSCodium, the completely open-source alternative to VSCode.
```

> **⚠️ WARNING:** Do not forget to use the full name to install formulae/casks
  from this tap (i.e. `thebusydev/linux/<formula_or_cask_name>`), in order to
  avoid conflicts with other formulae/casks from Homebrew official repo.

Use this command to explore the updated list of formulae and casks:

```bash
brew tap-info thebusydev/linux --json | jq -r '.[]|(.formula_names[],.cask_tokens[])'
```

## Objectives

- **Why are we bringing Homebrew formulae/casks to Linux?** \
  Below few use cases:
  1. Concerning **immutable distros**
     (e.g. *Fedora Silverblue*, *Fedora Kinoite*, *bazzite*, *bluefin*),
     layering new packages is extremely time-consuming and inefficient. Yet,
     [`toolbox`](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/building_running_and_managing_containers/using-toolbx-for-development-and-troubleshooting)
     and [`distrobox`](https://distrobox.it/)
     are great tools for containerized software, but they
     may appear unpractical for every-day use.
     [*Flatpak*](https://flatpak.org/) apps are easy-to-use, but not all
     the applications are designed to easily run under an isolated environment
     (think about IDEs like
     [VS Code](https://github.com/flathub/com.visualstudio.code?tab=readme-ov-file#usage)). \
     And here **Homebrew** comes to play: a <ins>*lightweight software manager*</ins>,
     capable of handling updates and dependencies seamlessly, which lets
     you run software directly on your machine, without any intermediate container! ☘️

  1. Homebrew has the great option to be installed
     <ins>*without root privileges*</ins>.
     Meaning that, you can install it in your `$HOME` directory and easily port
     your setup everywhere (even if you are not granted root privileges, e.g.
     on clusters or servers). 🖥️

- **Who is this project for?** \
  For **immutable distros users** mainly...
  I use *Fedora Kinoite* as my daily driver...
  And even if I really appreciate immutable distros for their security and yet
  maintainability, installing new software may appear quite cumbersome. 😵‍💫

## What is <ins>not</ins> planned

🍎 I am not planning to include any software for MacOS... Homebrew official
repository is already really complete for MacOS users.

## What is still missing (TODO list)

🍾 For a matter of simplicity, **bottle** builds and releases are not included
yet... But any contribution is welcome!
