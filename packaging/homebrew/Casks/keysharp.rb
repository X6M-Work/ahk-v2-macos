cask "keysharp" do
  arch arm: "osx-arm64", intel: "osx-x64"

  version "0.2.0-alpha"
  sha256 :no_check

  url "https://github.com/X6M-Work/ahk-v2-macos/releases/download/v#{version}/Keysharp-#{arch}.dmg"
  name "Keysharp (AHK v2 for macOS)"
  desc "AutoHotkey v2-compatible scripting runtime and live C# transpiler for macOS"
  homepage "https://github.com/X6M-Work/ahk-v2-macos"

  depends_on macos: ">= :sequoia"

  app "Keysharp.app"
  app "Keyview.app"
  binary "#{appdir}/Keysharp.app/Contents/MacOS/Keysharp", target: "keysharp"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Keysharp.app", "#{appdir}/Keyview.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/Keysharp",
    "~/Library/Preferences/org.keysharp.Keysharp.plist",
    "~/Library/Preferences/org.keysharp.Keyview.plist",
  ]
end
