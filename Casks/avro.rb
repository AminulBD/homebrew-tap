cask "avro" do
  arch arm: "apple-silicon", intel: "intel"

  version "1.5.2"
  sha256 arm:   "1f6db0ab072007525e00b6f1dd0fe50b111c2cfebe5a8d5f5c390f9d0e5cccb1",
         intel: "ad245090f4ae119f4805be3aa236f8ceb91c324e58480450c08d813a5041b6d6"

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
