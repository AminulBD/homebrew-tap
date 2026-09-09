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
      url "https://github.com/aminulbd/ds/releases/download/v0.1.10/ds-v0.1.10-aarch64-apple-darwin.tar.gz"
      sha256 "a9928ab0c19106fb80fa11ae3603c3141d9891137a7d1cf343c0948bc93b5b60"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.10/ds-v0.1.10-x86_64-apple-darwin.tar.gz"
      sha256 "30138f9982cd294d14902ce3e391ee2a0503347daa670e09dae1e07100f7799f"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.10/ds-v0.1.10-aarch64-unknown-linux-musl.tar.gz"
      sha256 "efa8c4e458f524cee67cf8ada664fda5d5e26284a3ef815f19dd384f11e6a76b"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.10/ds-v0.1.10-x86_64-unknown-linux-musl.tar.gz"
      sha256 "3ea3200131a53cef0e5436d4de1570ccc7ff65659972e27450f93507e2105539"
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
