class Ds < Formula
  desc "Check domain availability over RDAP with a WHOIS fallback"
  homepage "https://github.com/aminulbd/ds"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  # Released versions install a prebuilt binary; `--HEAD` builds from source.
  head do
    url "https://github.com/aminulbd/ds.git", branch: "main"
    depends_on "rust" => :build
  end

  on_macos do
    on_arm do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.8/ds-v0.1.8-aarch64-apple-darwin.tar.gz"
      sha256 "f39344d82f7d2f1f691b5571925ea0b11df77f626dc1d4137c42c977fb881532"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.8/ds-v0.1.8-x86_64-apple-darwin.tar.gz"
      sha256 "93eb5946c79ad7274c5389e1d565648b743489e6b1017f1bd8fc0e887a58ff14"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.8/ds-v0.1.8-aarch64-unknown-linux-musl.tar.gz"
      sha256 "82856cfc8307e2ba43556421f260b3c34f2f3458ae759c719c9da7a331157634"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.8/ds-v0.1.8-x86_64-unknown-linux-musl.tar.gz"
      sha256 "01fb37c0c1cd68533cc8538339160fd0e0e7fa3ff5a4cbf0661a39a38c0d7687"
    end
  end

  def install
    if build.head?
      system "cargo", "install", *std_cargo_args
    else
      bin.install "ds"
    end
    man1.install "ds.1"
  end

  test do
    assert_match "ds #{version}", shell_output("#{bin}/ds --version")

    # Argument handling, without touching the network.
    output = shell_output("#{bin}/ds apple --tld @#{testpath}/missing.txt 2>&1", 2)
    assert_match "reading TLD list", output

    output = shell_output("#{bin}/ds 2>&1", 2)
    assert_match "required arguments were not provided", output
  end
end
