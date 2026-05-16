{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
, stdenv
, darwin
}:
rustPlatform.buildRustPackage rec {
  pname = "cratedocs-mcp";
  version = "unstable-2025-03-13";

  src = fetchFromGitHub {
    owner = "lnay";
    repo = "cratedocs-mcp";
    rev = "ec7ac7b695ee200c35a48b4ddda62794ebb11a2b";
    hash = "sha256-ae8k/bi/S40QLw+D8Oy5IAKUZmQWVZSWA1u1jNbV36s=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "mcp-core-1.0.7" = "sha256-I2lxsv71i/LLZN3r/7mwNc6nZRd1xtQNVUm/g08nhn0=";
    };
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ]
    ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Security ];

  meta = with lib; {
    description = "Rust documentation MCP server for LLM crate assistance";
    homepage = "https://github.com/lnay/cratedocs-mcp";
    license = licenses.mit;
    mainProgram = "cratedocs";
  };
}
