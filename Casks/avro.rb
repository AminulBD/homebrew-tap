cask "avro" do
  arch arm: "apple-silicon", intel: "intel"

  version "1.5.6"
  sha256 arm:   "937bc80a705ea0d1848183f9b6a475e37ca648b8fd2cbb470617049e126fe8b4",
         intel: "1c96561e26944191a008980d0c8d9d9e4448eb3ae6079176d8190e23da1960ab"

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
