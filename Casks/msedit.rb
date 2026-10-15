# Documentation: https://docs.brew.sh/Cask-Cookbook
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
cask "msedit" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version "2.0.0"
  sha256 arm64_linux:  "b39f0b128d29d4c00f32a416c515f2c7758e0ec8d7457ee10b948e7b76636da4",
         x86_64_linux: "7854d477e73e7b94cd02f35959eea778a4d8408f6ffc657644ae1a715124786c"

  url "https://github.com/microsoft/edit/releases/download/v#{version}/edit-#{version}-#{arch}-linux-gnu.tar.gz"
  name "Microsoft Edit"
  name "MSEdit"
  desc "A simple editor for simple needs."
  homepage "https://github.com/microsoft/edit"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :linux
  depends_on formula: "icu4c"

  artifact "msedit.desktop",
           target: "#{Dir.home}/.local/share/applications/msedit.desktop"

  command_wrapper "msedit",
                  content: <<~SH
                    #!/bin/bash
                    export LD_LIBRARY_PATH="#{HOMEBREW_PREFIX}/opt/icu4c/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                    exec "#{staged_path}/edit" "$@"
                  SH

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file "msedit.desktop", <<~EOS
      [Desktop Entry]
      Type=Application
      Name=Microsoft Edit
      GenericName=Text Editor
      Comment=A simple editor for simple needs
      Icon=msedit
      Exec={{HOMEBREW_PREFIX}}/bin/msedit %F
      Terminal=true
      Categories=Utility;TextEditor;
      MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
      Keywords=text;editor
      X-Desktop-File-Install-Version=0.28
    EOS
  end

  caveats do
    <<~EOS
      Try MS Edit by calling:
      >>> msedit
    EOS
  end
end
