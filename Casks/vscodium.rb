cask "vscodium" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.140.06880"
  sha256 arm64_linux:  "a57be0d528adf7d6508318e37dbd982d695bf91501e324c37e97e11d5b375811",
         x86_64_linux: "61223b74f9e40834117311ec4177cb386d09b84c1aae4f9e674c96580569cef3"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium-linux-#{arch}-#{version}.tar.gz"
  name "VSCodium"
  desc "Editing evolved - Free/Libre Open Source Software Binaries of VS Code"
  homepage "https://vscodium.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :linux

  binary "bin/codium"
  binary "bin/codium-tunnel"
  bash_completion "resources/completions/bash/codium"
  zsh_completion  "resources/completions/zsh/_codium"
  artifact "vscodium.desktop",
           target: "#{Dir.home}/.local/share/applications/vscodium.desktop"
  artifact "vscodium-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/vscodium-url-handler.desktop"
  artifact "resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/vscodium.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file "vscodium.desktop", <<~EOS
      [Desktop Entry]
      Name=VSCodium
      Comment=Code Editing. Evolved.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/codium %F
      Icon=vscodium
      Type=Application
      StartupNotify=false
      StartupWMClass=codium
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-codium-workspace;
      Actions=new-empty-window;
      Keywords=vscodium;codium;vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/codium --new-window %F
      Icon=vscodium
    EOS

    write_file "vscodium-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=VSCodium - URL Handler
      Comment=Code Editing. Evolved.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/codium --open-url %U
      Icon=vscodium
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscodium;
      Keywords=vscodium;codium;vscode;
    EOS
  end

  zap trash: [
    "#{Dir.home}/.config/VSCodium",
    "#{Dir.home}/.vscode-oss",
    "#{Dir.home}/.vscode-oss-shared",
  ]
end
