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
      url "https://github.com/aminulbd/ds/releases/download/v0.1.9/ds-v0.1.9-aarch64-apple-darwin.tar.gz"
      sha256 "7be95f1c78f946a45cb0a6746168e0708eef44f9a6d0513f7d3fc88e2818c103"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.9/ds-v0.1.9-x86_64-apple-darwin.tar.gz"
      sha256 "6d63ec1ecaf701143998ce3328e52d89fb4245b8d833e2798ef8026dd2d8ce73"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.9/ds-v0.1.9-aarch64-unknown-linux-musl.tar.gz"
      sha256 "29b510c5a00abf5d9ddc528634faa734c51c8e8078c0afb0c624132b87951da0"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.9/ds-v0.1.9-x86_64-unknown-linux-musl.tar.gz"
      sha256 "c855b72ccbea67d3cde4a68f873b389f8d1a099abc89bf3190b7a50f4c45f0cd"
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
