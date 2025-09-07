{
  description = "CwC is an extensible Wayland compositor with dynamic window management based on wlroots.";

  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }@inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      version = let
        contents = builtins.readFile ./meson.build;
        match = builtins.match ".*'-DCWC_VERSION=\"v(.*)\"',.*" contents;
      in
        if match != null then
          builtins.head match
        else
          "0.0.0";

      nativeBuildInputs = with pkgs; [
        meson
        ninja
        pkg-config
        git
        cmake
        gnumake
        luajitPackages.ldoc
        boost
        wayland-scanner
        python3
      ];

      buildInputs = with pkgs; [
        wayland
        wayland-protocols
        wlroots_0_19
        hyprcursor
        cairo
        libxkbcommon
        libinput
        xxHash
        gobject-introspection
        pango
        (luajit.withPackages (luapkgs: with luapkgs; [
          lgi
        ]))
        xorg.xcbutilwm
        libdrm
      ];
    in rec {
      devShells.${system}.default = pkgs.mkShell {
        inherit nativeBuildInputs buildInputs;
      };

      packages.${system}.default = pkgs.stdenv.mkDerivation rec {
        pname = "cwc";
        inherit version nativeBuildInputs buildInputs;
        name = "${pname}-${version}";
        src = ./.;
        meta = with pkgs; {
          homepage = "https://github.com/Cudiph/cwcwm";
          license = lib.licenses.gpl3;
          mainProgram = "cwc";
        };

        buildDir = "build";
        mesonFlags = with pkgs; [
          (lib.mesonBool "plugins" true)
          (lib.mesonBool "tests" true)
        ];

        configurePhase = ''
          mkdir -p "${buildDir}"
          meson setup "${buildDir}" ${builtins.toString mesonFlags} --prefix=$out --buildtype=release --backend=ninja
        '';

        buildPhase = ''
          ninja -C "${buildDir}"
          pushd docs
          ldoc .
          popd
        '';

        installPhase = ''
          ninja -C "${buildDir}" install
        '';
      };

      defaultPackage = packages.${system}.default;
    });
}
