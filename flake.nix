{
  description = "A flake for building a suite of performance and security tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        lib = pkgs.lib;

        # Source definitions for the multi-part oatpp build
        oatppSrc = pkgs.fetchFromGitHub {
          owner = "oatpp"; repo = "oatpp"; rev = "06ce4516c47dcd856406a5af3fdb31e30d614ec0"; sha256 = "sha256-H0MA0lROwnzXOCAiZP+/IlH9jS9K+w9xKttACU+PV/c=";
        };
        oatppWebsocketSrc = pkgs.fetchFromGitHub {
          owner = "oatpp"; repo = "oatpp-websocket"; rev = "e5b67adfd3105627ef700ac49308565c93c491f9"; sha256 = "sha256-yU+GijUTv3f3uuUCb/rvMFyA6JyFz6lOoL0VFWmeJJc=";
        };

        # ======================================================================
        # Custom-built Packages (from Dockerfile's BUILD stages)
        # ======================================================================
        nghttp2-custom = pkgs.stdenv.mkDerivation {
          pname = "nghttp2-custom";
          version = "1.64.0";
          src = pkgs.fetchFromGitHub {
            owner = "nghttp2"; repo = "nghttp2"; rev = "v1.64.0";
            sha256 = "sha256-+1WV+a/GTHA7aB4nvDo3hegImGvJBChmvS+2TFkaKIA="; fetchSubmodules = true;
          };
          nativeBuildInputs = [ pkgs.autoconf pkgs.automake pkgs.libtool pkgs.pkg-config ];
          buildInputs = [ pkgs.zlib pkgs.libev pkgs.jemalloc pkgs.c-ares pkgs.openssl pkgs.systemd pkgs.libevent pkgs.jansson pkgs.libxml2 pkgs.python3 pkgs.brotli ];
          preConfigure = "autoreconf -i";
          configureFlags = [ "--enable-app" "--disable-examples" "--disable-hpack-tools" "--disable-python-bindings" "--disable-static" "--disable-failmalloc" "--disable-threads" ];
          enableParallelBuilding = true;
        };

        packetdrill = pkgs.stdenv.mkDerivation {
          pname = "packetdrill";
          version = "2025-07-09";
          src = pkgs.fetchFromGitHub {
            owner = "google"; repo = "packetdrill"; rev = "2ecffa6df3f0fd5b0bd23d2361178d2613f3786b";
            sha256 = "sha256-8aGlnQqKZ3WidvAOWZmEL74OUj2fRCONJiZbAiPYxO4=";
          };
          nativeBuildInputs = [ pkgs.bison pkgs.flex ];
          buildInputs = [ pkgs.glibc.static ];
          sourceRoot = "source/gtests/net/packetdrill";
          postPatch = ''
            substituteInPlace Makefile.common --replace "-Werror" ""
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp packetdrill $out/bin/
          '';
          enableParallelBuilding = true;
        };

        quicly = pkgs.stdenv.mkDerivation {
          pname = "quicly-cli";
          version = "2024-05-15";
          src = pkgs.fetchFromGitHub {
            owner = "h2o"; repo = "quicly"; rev = "e5af5a91b4d53528e725e686cd6e3e18aec94e92";
            sha256 = "sha256-rqGmPPdmFvqSC8FgvDgiqu3RPISXHnhhtfGk1+jCZzk="; fetchSubmodules = true;
          };
          nativeBuildInputs = [ pkgs.cmake pkgs.perl ];
          buildInputs = [ pkgs.openssl ];
          cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ];
          buildPhase = "make cli -j2";
          installPhase = ''
            mkdir -p $out/bin
            cp cli $out/bin/quicly-cli
          '';
        };

        oatpp-benchmark = pkgs.stdenv.mkDerivation {
          pname = "oatpp-benchmark-project";
          version = "1.0.0";
          src = pkgs.fetchFromGitHub {
            owner = "oatpp"; repo = "benchmark-websocket"; rev = "d30f971d6e943ea157e20da89dcfe153a026fec2";
            sha256 = "sha256-GS7ADMhuC4Xc+OY8d1SuadkgdEy+y7c4RwOHUibFyAY=";
          };
          nativeBuildInputs = [ pkgs.cmake pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
          dontUseCmakeConfigure = true;
          buildPhase = ''
            export CMAKE_INSTALL_PREFIX=$out
            export PKG_CONFIG_PATH=$out/lib/pkgconfig

            # Build oatpp
            cp -r ${oatppSrc} oatpp-src
            chmod -R u+w oatpp-src
            cd oatpp-src
            mkdir build && cd build
            cmake .. -DCMAKE_BUILD_TYPE=Release -DOATPP_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$out
            make -j$(nproc) && make install
            cd ../..

            # Build oatpp-websocket
            cp -r ${oatppWebsocketSrc} oatpp-websocket-src
            chmod -R u+w oatpp-websocket-src
            cd oatpp-websocket-src
            mkdir build && cd build
            cmake .. -DCMAKE_BUILD_TYPE=Release -DOATPP_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$out
            make -j$(nproc) && make install
            cd ../..

            # Build benchmark applications
            cp -r $src benchmark-src
            chmod -R u+w benchmark-src
            cd benchmark-src

            cd server
            mkdir build && cd build
            cmake .. -DCMAKE_BUILD_TYPE=Release && make -j$(nproc)
            cd ../..

            cd client
            mkdir build && cd build
            cmake .. -DCMAKE_BUILD_TYPE=Release && make -j$(nproc)
            cd ../..
          '';
          installPhase = ''
            mkdir -p $out
            cp -r server $out/
            cp -r client $out/
          '';
        };

        # Build goloris from source using go directly
        goloris = pkgs.stdenv.mkDerivation {
          pname = "goloris";
          version = "unstable";
          src = pkgs.fetchFromGitHub {
            owner = "valyala";
            repo = "goloris";
            rev = "a59fafb2dd6c401d7cb50964dde3ffafbd456451";
            sha256 = "sha256-XRVWF/En1LUR2TgmM6gVls/7Gj58PalwX+d3C24aR+E=";
          };
          nativeBuildInputs = [ pkgs.go ];
          buildPhase = ''
            export HOME=$TMPDIR
            export GOCACHE=$TMPDIR/go-cache
            export GOPATH=$TMPDIR/go
            export GO111MODULE=off
            go build -o goloris
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp goloris $out/bin/
          '';
        };

        pandora = pkgs.buildGoModule {
          pname = "pandora";
          version = "0.6.2";
          src = pkgs.fetchFromGitHub {
            owner = "yandex";
            repo = "pandora";
            rev = "v0.6.2";
            sha256 = "sha256-r0b7kqWcV3y8o93uKuZz9m2e5QCzyZRhGoyEzoZPdW8=";
          };
          vendorHash = "sha256-XCZT/vJKgVOewe9MF7jZJgjlvqCYFB6JPCSlc24mQCc=";
        };

        ethr = pkgs.stdenv.mkDerivation {
          pname = "ethr";
          version = "1.0.0";
          src = pkgs.fetchurl { url = "https://github.com/microsoft/ethr/releases/download/v1.0.0/ethr_linux.zip"; sha256 = "sha256-eB9IKUtmI+8i/ZW0MuHJwROsxMRc0iPVONouaXZ4NyE="; };
          nativeBuildInputs = [ pkgs.unzip ];
          unpackPhase = ''
            mkdir ethr-src
            cd ethr-src
            unzip $src
          '';
          installPhase = ''
            mkdir -p $out/bin
            install -m755 ethr $out/bin/ethr
          '';
        };

        # ** THIS IS THE FIX **
        # Manually fetch rustbuster binary to avoid issues with nixpkgs channels
        rustbuster-bin = pkgs.stdenv.mkDerivation {
          pname = "rustbuster-bin";
          version = "3.0.3";
          src = pkgs.fetchurl {
            url = "https://github.com/phra/rustbuster/releases/download/v3.0.3/rustbuster-v3.0.3-x86_64-unknown-linux-gnu";
            sha256 = "sha256-P3kAKb/kNQvZlBU0Zcgb7txU1hwdre2hJBCL+HVFlXQ=";
          };
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/rustbuster
            chmod +x $out/bin/rustbuster
          '';
        };

        # ======================================================================
        # Final Docker Image
        # ======================================================================
        dockerImage = pkgs.dockerTools.buildImage {
          name = "performance-tools";
          tag = "latest";

          # Use current date/time for the image
          created = "now";

          copyToRoot = [
            # Base system
            pkgs.bashInteractive
            pkgs.coreutils

            # Tools
            nghttp2-custom goloris pandora ethr rustbuster-bin # <-- Using the fixed rustbuster
            pkgs.oha pkgs.drill pkgs.bombardier pkgs.hey pkgs.feroxbuster
            pkgs.git pkgs.nmap pkgs.curl pkgs.wget pkgs.apacheHttpd pkgs.strace pkgs.iperf3
            pkgs.tree pkgs.httpstat pkgs.trivy

            # Runtime libraries with explicit outputs
            pkgs.jemalloc.out pkgs.libev.out pkgs.openssl.bin pkgs.openssl.out pkgs.python3 pkgs.cacert
          ];

          extraCommands = ''
            # Create directories and copy special artifacts
            mkdir -p benchmark-websocket
            cp -r ${oatpp-benchmark}/server benchmark-websocket/
            cp -r ${oatpp-benchmark}/client benchmark-websocket/
            mkdir -p packedrill  # Typo from original Dockerfile
            cp ${packetdrill}/bin/packetdrill packedrill/
            mkdir -p quicly
            cp ${quicly}/bin/quicly-cli quicly/
          '';

          config = {
            Cmd = [ "${pkgs.bashInteractive}/bin/bash" ];
            WorkingDir = "/";
            Env = [
              "PATH=/bin:/usr/bin:/usr/local/bin:/usr/sbin:/sbin"
              "DEBIAN_FRONTEND=noninteractive"
            ];
          };
        };
      in
      {
        packages = {
          inherit nghttp2-custom packetdrill quicly oatpp-benchmark goloris pandora ethr rustbuster-bin;
        };
        dockerImages = {
          default = dockerImage;
        };
        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues self.packages.${system};
        };
      });
}
