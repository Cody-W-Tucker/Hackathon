{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          venvDir = ".venv";
          packages = with pkgs; [ python311 ] ++
            (with pkgs.python311Packages; [
              pip
              venvShellHook
              jupyter
              notebook
              ipykernel
            ]);
          shellHook = ''
            export JOURNAL_PATH=~/Documents/Personal
            SYMLINK_JOURNAL_PATH="$PWD/data"
          
            # Function to create symlinks
            create_symlink() {
              ln -sfn "$1" "$2" && echo "Created symlink: $2 -> $1" || echo "Failed to create symlink: $2 -> $1" >&2
            }
          
            # Create symlinks
            create_symlink "$JOURNAL_PATH" "$SYMLINK_JOURNAL_PATH"
          
            # Activate the virtual environment
            source .venv/bin/activate
          
            # Verify pip installation
            if ! command -v pip &> /dev/null; then
              echo "pip could not be found"
              exit 1
            fi
          
            # Cleanup function to remove symlinks
            cleanup() {
              echo "Cleaning up..."
              rm -f "$SYMLINK_JOURNAL_PATH"
            }
          
            # Set trap for cleanup on exit
            trap cleanup EXIT
            echo "Trap set for cleanup on EXIT"
          '';
        };
      });
    };
}
