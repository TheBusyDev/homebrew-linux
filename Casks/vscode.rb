cask "vscode" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.143.1,e646868227c3e3a9e3f24277c8c7220be42c0be7"
  sha256 arm64_linux:  "e84bf20d112fdb73c29b85b317ba50d5a48bea05c0711509669c8466639e9eb6",
         x86_64_linux: "48f658052e54e020a1c1be7b37ac0f9ae39f07e8ccda805c63f053cfda72b2be"

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
