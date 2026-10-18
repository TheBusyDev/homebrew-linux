cask "vscode" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.142.0,6d62b1d5dace93a33b3a6d3eca1317bd5e15bcb1"
  sha256 arm64_linux:  "cb4ce5183a29b1a13aeb6409d5430c896fa35aad21097be1f874fbb4cf1e7e62",
         x86_64_linux: "fcc1ccb435685adcc748287bbde524589569deedb6b4ad5560071583cbe00ae0"

  url "https://update.code.visualstudio.com/commit:#{version.csv.second}/linux-#{arch}/stable"
  name "Microsoft Visual Studio Code"
  name "VSCode"
  desc "Editing redefined. Open-source code editor"
  homepage "https://code.visualstudio.com/"

  livecheck do
    url "https://update.code.visualstudio.com/api/update/linux-#{arch}/stable/latest"
    strategy :json do |json|
      version = json["productVersion"]
      build = json["version"]
      next if version.blank? || build.blank?

      "#{version},#{build}"
    end
  end

  depends_on :linux

  binary "bin/code"
  binary "bin/code-tunnel"
  bash_completion "resources/completions/bash/code"
  zsh_completion  "resources/completions/zsh/_code"
  artifact "vscode.desktop",
           target: "#{Dir.home}/.local/share/applications/vscode.desktop"
  artifact "vscode-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/vscode-url-handler.desktop"
  artifact "resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/vscode.png"

  preflight_steps do
    move_contents "VSCode-linux-{{arch}}", "."
    remove "VSCode-linux-{{arch}}", recursive: true

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file "vscode.desktop", <<~EOS
      [Desktop Entry]
      Name=Visual Studio Code
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code %F
      Icon=vscode
      Type=Application
      StartupNotify=false
      StartupWMClass=Code
      Categories=TextEditor;Development;IDE;
      MimeType=application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/code --new-window %F
      Icon=vscode
    EOS

    write_file "vscode-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=Visual Studio Code - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code --open-url %U
      Icon=vscode
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscode;
      Keywords=vscode;
    EOS
  end

  zap trash: [
    "#{Dir.home}/.config/Code",
    "#{Dir.home}/.copilot",
    "#{Dir.home}/.vscode",
    "#{Dir.home}/.vscode-shared",
  ]
end
