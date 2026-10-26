cask "paraview" do
  arch intel: "x86_64"
  os linux: "Linux"

  version "6.1.0,Python3.12"
  sha256 "bd1c3917d28b43334970a1957d94b97ab79bce555c4a694a35a1a36dfe4fe2d1"

  url "https://www.paraview.org/files/v#{version.major_minor}/ParaView-#{version.csv.first}-MPI-Linux-#{version.csv.second}-x86_64.tar.gz"
  name "ParaView"
  desc "Open source post-processing visualization engine"
  homepage "https://www.paraview.org/"

  livecheck do
    url "https://www.paraview.org/files/listing.txt"
    regex(%r{\./v\d+\.\d+/ParaView-(\d+(?:\.\d+)*)-MPI-Linux-(Python\d+(?:\.\d+)*)-x86_64\.tar\.gz})
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| "#{match[0]},#{match[1]}" }
    end
  end

  depends_on arch: :intel
  depends_on :linux

  rename "ParaView-#{version.csv.first}-MPI-Linux-#{version.csv.second}-x86_64",
         "ParaView-tmp"

  %w[
    collaboration_server
    hydra_pmi_proxy
    mpiexec
    ospray_mpi_worker
    vrpn_print_devices
    vrpn_server
  ].each do |bin|
    binary "bin/#{bin}", target: "pv_#{bin}"
  end

  binary "bin/pvbatch"
  binary "bin/pvdataserver"
  binary "bin/pvpython"
  binary "bin/pvrenderserver"
  binary "bin/pvserver"
  command_wrapper "paraview",
                  content: <<~SH
                    #!/bin/bash
                    export QT_QPA_PLATFORMTHEME=generic
                    export QT_QPA_PLATFORM=xcb
                    exec "#{staged_path}/bin/paraview" "$@"
                  SH
  artifact "paraview.desktop",
           target: "#{Dir.home}/.local/share/applications/paraview.desktop"
  artifact "share/icons/hicolor/96x96/apps/paraview.png",
           target: "#{Dir.home}/.local/share/icons/paraview.png"

  preflight_steps do
    move_contents "ParaView-tmp", "."
    remove "ParaView-tmp", recursive: true

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file "paraview.desktop", <<~EOS
      [Desktop Entry]
      Type=Application
      Name=ParaView
      Comment=Parallel visualization application
      Exec={{HOMEBREW_PREFIX}}/bin/paraview %f
      Icon=paraview
      StartupWMClass=paraview
      Categories=Qt;Science;DataVisualization;
    EOS
  end

  zap trash: "#{Dir.home}/.config/ParaView"
end
