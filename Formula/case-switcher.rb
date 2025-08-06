class CaseSwitcher < Formula
  desc "Command-line utility that converts text between different case formats"
  homepage "https://github.com/Velrok/case-switcher"
  url "https://github.com/Velrok/case-switcher/archive/v0.1.7.tar.gz"
  sha256 "f7c6094600581c5300282a75ec24c08445abd99068031ed0ed20d8f326f6a402"
  license "MIT"

  depends_on "zig" => :build

  def install
    system "zig", "build", "--release=fast"
    bin.install "zig-out/bin/case_switcher" => "case-switcher"
  end

  test do
    assert_match "HelloWorld", shell_output("#{bin}/case-switcher hello_world")
  end
end