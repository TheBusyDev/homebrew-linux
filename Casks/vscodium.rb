cask "vscodium" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.135.06055"
  sha256 arm64_linux: "9765cea4f707ff7dc83a40be408a7318a59abb6996b359631639d9aab2f48a90"
  sha256 x86_64_linux: "c09d8ac8dd7f52b09ee159ee24b440541dfd8f937a0f6f88cc428c78e48ee1f2"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium-#{os}-#{arch}-#{version}.tar.gz"
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
      Comment=Editing evolved.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/codium %F
      Icon=vscodium
      Type=Application
      StartupNotify=false
      StartupWMClass=VSCodium
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
      Comment=Editing evolved.
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
    "#{Dir.home}/.vscode-oss",
    "#{Dir.home}/.vscode-oss-shared",
    "#{Dir.home}/.config/VSCodium"
  ]
end
