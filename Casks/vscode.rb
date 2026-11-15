cask "vscode" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.146.0,69047191fc427f2f92828279aae1d90d8eeda7ab"
  sha256 arm64_linux:  "99e503307fc9569a09e46dd39a0b41c8d13af7a0701eee3c6ec8255763bf23fc",
         x86_64_linux: "cbdb7bde3d358c7297cf1d9d6adc16dfb1d0179501fb2c152df48593e39e3600"

  url "https://update.code.visualstudio.com/commit:#{version.csv.second}/linux-#{arch}/stable"
  name "Microsoft Visual Studio Code"
  name "VSCode"
  desc "Editing redefined - Open-source code editor"
  homepage "https://code.visualstudio.com/"

  livecheck do
    url "https://update.code.visualstudio.com/api/update/linux-#{arch}/stable/latest"
    strategy :json do |json|
      prod_version = json["productVersion"]
      build_id = json["version"]
      next if prod_version.blank? || build_id.blank?

      "#{prod_version},#{build_id}"
    end
  end

  depends_on :linux

  rename "VSCode-linux-#{arch}", "VSCode-tmp"

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
    move_contents "VSCode-tmp", "."
    remove "VSCode-tmp", recursive: true

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
