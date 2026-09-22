cask "avro" do
  arch arm: "apple-silicon", intel: "intel"

  version "1.5.3"
  sha256 arm:   "1c84a09c3d6dc2f6d0c83ba4b827f3b9a12655b2644317bd0765026ec0435132",
         intel: "0e2f0aa9c33dedcf5b9023ff89d10c450125623266812de305d735cfe951c361"

  url "https://github.com/AminulBD/iAvro/releases/download/v#{version}/Avro-Keyboard-#{arch}.zip"
  name "Avro Keyboard"
  desc "Bangla phonetic input method"
  homepage "https://avro.aminul.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :monterey

  # Installs into ~/Library/Input Methods rather than /Applications.
  input_method "Avro Keyboard.app"

  uninstall quit: "app.aminul.inputmethod.AvroKeyboard"

  zap trash: [
    "~/Library/Application Support/app.aminul.inputmethod.AvroKeyboard",
    "~/Library/Preferences/app.aminul.inputmethod.AvroKeyboard.plist",
  ]

  caveats <<~EOS
    Log out and back in so macOS picks up the new input method, then add it in
      System Settings > Keyboard > Input Sources > Edit… > + > Bangla > Avro Keyboard
  EOS
end
