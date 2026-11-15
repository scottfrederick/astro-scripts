{
  description = "Astro processing scripts (Siril / PlanetarySystemStacker helpers)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      # PlanetarySystemStacker isn't in nixpkgs, so it's packaged here.
      packages = forAllSystems (pkgs: rec {
        planetary-system-stacker = pkgs.callPackage ./nix/planetary-system-stacker.nix { };
        default = planetary-system-stacker;
      });

      # nix develop -> python3 with numpy, astropy and PSS's modules (for planet-stack),
      # the PlanetarySystemStacker command, and these scripts on PATH.
      devShells = forAllSystems (pkgs:
        let
          pss = self.packages.${pkgs.stdenv.hostPlatform.system}.planetary-system-stacker;
        in {
          default = pkgs.mkShell {
            packages = [
              (pkgs.python3.withPackages (ps: [ ps.numpy ps.astropy (ps.toPythonModule pss) ]))
              pss
              # pkgs.siril  # uncomment to use nixpkgs' siril-cli instead of the flatpak
            ];
            shellHook = ''
              export PATH="$(git rev-parse --show-toplevel 2>/dev/null || pwd):$PATH"
              echo "astro-scripts shell: python3 (numpy, astropy, PSS), PlanetarySystemStacker, scripts on PATH"
            '';
          };
        });
    };
}
