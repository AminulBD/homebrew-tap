cask "avro" do
  arch arm: "apple-silicon", intel: "intel"

  version "1.5.4"
  sha256 arm:   "63a922854221ae79e0662e46ffedc8eb5e8ddcf29da5061abf70cdc0c7e79edd",
         intel: "c131f14cf11e08e0fc91c3664f7d286e1d8fddddc8252d041c258c8a57b24552"

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
