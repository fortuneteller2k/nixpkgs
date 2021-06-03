{ lib, stdenv, fetchFromGitHub, autoreconfHook, libtool, pkg-config, libusb1, readline }:

stdenv.mkDerivation rec {
  pname = "libirecovery";
  version = "unstable-2021-05-26";

  src = fetchFromGitHub {
    owner = "libimobiledevice";
    repo = pname;
    rev = "47934949e0015165a4562b08e824adb3f664c0ea";
    sha256 = "0p9ncqnz5kb7qisw00ynvasw1hax5qx241h9nwppi2g544i9lbnr";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    libtool
    pkg-config
  ];

  buildInputs = [
    libusb1
    readline
  ];

  # Packager note: Not clear whether this needs a NixOS configuration,
  # as only the `idevicerestore` binary was tested so far (which worked
  # without further configuration).
  configureFlags = [
    "--with-udevrulesdir=${placeholder "out"}/lib/udev/rules.d"
    ''--with-udevrule="OWNER=\"root\", GROUP=\"myusergroup\", MODE=\"0660\""''
  ];

  meta = with lib; {
    homepage = "https://github.com/libimobiledevice/libirecovery";
    description = "Library and utility to talk to iBoot/iBSS via USB on Mac OS X, Windows, and Linux";
    longDescription = ''
      libirecovery is a cross-platform library which implements communication to
      iBoot/iBSS found on Apple's iOS devices via USB. A command-line utility is also
      provided.
    '';
    license = licenses.lgpl21;
    # Upstream description says it works on more platforms, but packager hasn't tried that yet
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ nh2 ];
  };
}
