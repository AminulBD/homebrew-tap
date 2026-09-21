cask "avro" do
  arch arm: "apple-silicon", intel: "intel"

  version "1.5.1"
  sha256 arm:   "c20928cd67a905da40b333df1a4042808c7a23706e832c6cae81c2adaae5e5dd",
         intel: "9a55a053d1541331115f3491d6075cce31122661bf09fca7a23cf6c0aa0e07b2"

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
