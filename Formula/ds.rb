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
      url "https://github.com/aminulbd/ds/releases/download/v0.1.6/ds-v0.1.6-aarch64-apple-darwin.tar.gz"
      sha256 "bf96117c5013109eb3eb6ede738422efe5912086e42470c0cc70892dde6bf713"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.6/ds-v0.1.6-x86_64-apple-darwin.tar.gz"
      sha256 "09b57630997ac348470fdee5373e6c6d3b3978ef8b5a631081fe115fd7d869f5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.6/ds-v0.1.6-aarch64-unknown-linux-musl.tar.gz"
      sha256 "9320b3c6a263f510355c85cf87bf07edfe004c3c369e9e852207dae74ac4b6ec"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.6/ds-v0.1.6-x86_64-unknown-linux-musl.tar.gz"
      sha256 "b5bcb1ec4592d32bd0dfbcce549fa54cd79b0eb94cc00409ab509edc585c7b9e"
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
