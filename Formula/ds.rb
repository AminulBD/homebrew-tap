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
      url "https://github.com/aminulbd/ds/releases/download/v0.1.7/ds-v0.1.7-aarch64-apple-darwin.tar.gz"
      sha256 "eb0a87dccddfd24fe1ceeacb332103b13e704889b076afe4f9c48879c4b85d85"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.7/ds-v0.1.7-x86_64-apple-darwin.tar.gz"
      sha256 "84fb4523657ece6c9bdb21939c34a90475f97ba5df0245013391f844cf588982"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.7/ds-v0.1.7-aarch64-unknown-linux-musl.tar.gz"
      sha256 "11da7eb9bbb86fc2182b3e7b5fe9daeda78db9546420af64c4d375268d051a0a"
    end
    on_intel do
      url "https://github.com/aminulbd/ds/releases/download/v0.1.7/ds-v0.1.7-x86_64-unknown-linux-musl.tar.gz"
      sha256 "0b0f061700a114e38df7c0c0f95c03718b5df6563c7b69ddd886005b9ba0f1f4"
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
