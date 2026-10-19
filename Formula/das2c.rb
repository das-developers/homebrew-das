class Das2c < Formula
  desc "Das2 and das3 stream utilities and static library for space physics data"
  homepage "https://github.com/das-developers/das2C"
  # Pre-release snapshot of master for testing the tap CI.  Becomes
  # .../archive/refs/tags/v3.0.0.tar.gz once that tag is pushed.
  url "https://github.com/das-developers/das2C/archive/5d9515cf9def443833b40b06c6db71219b1d33ec.tar.gz"
  version "3.0.0-pre"
  sha256 "50b73f6ec5373ea988eba39e650f4258f1f9a9e74b1319c6b49a0e5db3b42eeb"
  license "LGPL-2.1-only"
  head "https://github.com/das-developers/das2C.git", branch: "master"

  depends_on "fftw"
  depends_on "openssl@3"

  uses_from_macos "expat"
  uses_from_macos "zlib"

  # CDF and CSPICE are fetched from their publishers at build time and
  # statically linked into the programs.  Their libraries are not installed.
  # NAIF's package URLs carry no version, these hashes are for toolkit N0067.
  # Intel Macs aren't supported for now.
  on_macos do
    on_arm do
      resource "cspice" do
        url "https://naif.jpl.nasa.gov/pub/naif/toolkit/C/MacM1_OSX_clang_64bit/packages/cspice.tar.Z"
        version "N0067"
        sha256 "0deae048443e11ca4d093cac651d9785d4f2594631a183d85a3d58949f4d0aa9"
      end
    end
  end

  on_linux do
    on_intel do
      resource "cspice" do
        url "https://naif.jpl.nasa.gov/pub/naif/toolkit/C/PC_Linux_GCC_64bit/packages/cspice.tar.Z"
        version "N0067"
        sha256 "60a95b51a6472f1afe7e40d77ebdee43c12bb5b8823676ccc74692ddfede06ce"
      end
    end
  end

  resource "cdf" do
    url "https://spdf.gsfc.nasa.gov/pub/software/cdf/dist/cdf39_1/linux/cdf39_1-dist-cdf.tar.gz"
    sha256 "f9574315a028e8f71257fd55c375639c95fea607a5df70fb6629dc1e22adc68b"
  end

  def install
    cdf_dir = buildpath/"deps/cdf"
    resource("cdf").stage(cdf_dir)
    cdf_args = if OS.mac?
      ["OS=macosx", "ENV=#{Hardware::CPU.arm? ? "arm64" : "x86_64"}"]
    else
      ["OS=linux", "ENV=gnu"]
    end
    cd cdf_dir do
      system "make", *cdf_args, "CURSES=no", "FORTRAN=no", "all"
    end

    cspice_dir = buildpath/"deps/cspice"
    resource("cspice").stage(cspice_dir)

    args = %W[
      PREFIX=#{prefix}
      SPICE=yes
      CDF=yes
      CDF_INC=#{cdf_dir}/src/include
      CDF_LIB=#{cdf_dir}/src/lib/libcdf.a
      CSPICE_INC=#{cspice_dir}/include
      CSPICE_LIB=#{cspice_dir}/lib/cspice.a
      FFTW_DIR=#{formula_opt_prefix("fftw")}
      OPENSSL_DIR=#{formula_opt_prefix("openssl@3")}
    ]
    # Keep -Werror out of user installs, a newer compiler shouldn't break them
    args << "WARNINGS=-Wall -Wno-deprecated-declarations"

    system "make", *args
    system "make", *args, "install", "dev_install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <das3/core.h>

      int main(int argc, char** argv) {
        das_init(argv[0], DASERR_DIS_EXIT, 0, DASLOG_INFO, NULL);
        das_time dt;
        if (!dt_parsetime("2026-10-18T12:00", &dt)) return 1;
        printf("%s %d\\n", das_version(), dt.yday);
        return 0;
      }
    C
    # On Linux expat and zlib are formula dependencies too, so take the
    # search paths from whatever this platform's dependencies are.
    dep_flags = deps.map(&:to_formula).flat_map do |f|
      flags = ["-I#{f.opt_include}", "-L#{f.opt_lib}"]
      flags << "-Wl,-rpath,#{f.opt_lib}" if OS.linux?
      flags
    end
    system ENV.cc, "-std=c99", "test.c", "-I#{include}", *dep_flags,
           "-L#{lib}", "-ldas3", "-lfftw3", "-lexpat", "-lssl", "-lcrypto",
           "-lz", "-lm", "-lpthread", "-o", "test"
    assert_match "291", shell_output("./test")

    assert_match "das3_info", shell_output("#{bin}/das3_info --help 2>&1")
  end
end
