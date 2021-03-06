{ lib, stdenv, python3, fetchpatch, acl, libb2, lz4, zstd, openssl, openssh, nixosTests }:

python3.pkgs.buildPythonApplication rec {
  pname = "borgbackup";
  version = "1.1.16";

  src = python3.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "0l1dqfwrd9l34rg30cmzmq5bs6yha6kg4vy313jq611jsqj94mmw";
  };

  patches = [
    # fix compatibility with sphinx 4
    (fetchpatch {
      url = "https://github.com/borgbackup/borg/commit/6a1f31bf2914d167e2f5051f1d531d5d4a19f54b.patch";
      includes = [ "docs/conf.py" ];
      sha256 = "0aa4kyb3j4apgwqcy1hzg6lxvpf60m2mijcj60vh101b42410hiz";
    })
  ];

  nativeBuildInputs = with python3.pkgs; [
    setuptools-scm
    # For building documentation:
    sphinx guzzle_sphinx_theme
  ];
  buildInputs = [
    libb2 lz4 zstd openssl
  ] ++ lib.optionals stdenv.isLinux [ acl ];
  propagatedBuildInputs = with python3.pkgs; [
    cython llfuse
  ];

  preConfigure = ''
    export BORG_OPENSSL_PREFIX="${openssl.dev}"
    export BORG_LZ4_PREFIX="${lz4.dev}"
    export BORG_LIBB2_PREFIX="${libb2}"
    export BORG_LIBZSTD_PREFIX="${zstd.dev}"
  '';

  makeWrapperArgs = [
    ''--prefix PATH ':' "${openssh}/bin"''
  ];

  postInstall = ''
    make -C docs singlehtml
    mkdir -p $out/share/doc/borg
    cp -R docs/_build/singlehtml $out/share/doc/borg/html

    make -C docs man
    mkdir -p $out/share/man
    cp -R docs/_build/man $out/share/man/man1

    mkdir -p $out/share/bash-completion/completions
    cp scripts/shell_completions/bash/borg $out/share/bash-completion/completions/

    mkdir -p $out/share/fish/vendor_completions.d
    cp scripts/shell_completions/fish/borg.fish $out/share/fish/vendor_completions.d/

    mkdir -p $out/share/zsh/site-functions
    cp scripts/shell_completions/zsh/_borg $out/share/zsh/site-functions/
  '';

  checkInputs = with python3.pkgs; [
    pytest
  ];

  checkPhase = ''
    HOME=$(mktemp -d) py.test --pyargs borg.testsuite
  '';

  # 64 failures, needs pytest-benchmark
  doCheck = false;

  passthru.tests = {
    inherit (nixosTests) borgbackup;
  };

  outputs = [ "out" "doc" ];

  meta = with lib; {
    description = "Deduplicating archiver with compression and encryption";
    homepage = "https://www.borgbackup.org";
    license = licenses.bsd3;
    platforms = platforms.unix; # Darwin and FreeBSD mentioned on homepage
    maintainers = with maintainers; [ flokli dotlambda globin ];
  };
}
