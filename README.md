# COBOL Blockchain

A fully functional blockchain implementation in COBOL with Proof-of-Work mining, demonstrating that even legacy languages can implement modern distributed ledger technology.

![COBOL + Blockchain](https://img.shields.io/badge/COBOL-Blockchain-blue)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

## Overview

This project implements a complete blockchain system using **GnuCOBOL** (COBOL compiler) with SHA-256 cryptographic hashing powered by OpenSSL. It features:

- **Proof-of-Work Mining** with configurable difficulty
- **SHA-256 Cryptographic Hashing** via C wrapper
- **Sequential File-Based Ledger** for persistence
- **Chain Validation** to ensure integrity
- **Interactive Menu Interface** for ease of use
- **Block Structure** with timestamps, hashes, nonces, and transaction data

## Features

### Core Blockchain Features
- **Genesis Block Creation**: Automatically creates the first block in the chain
- **Block Mining**: Proof-of-Work algorithm finds valid nonces
- **Chain Linking**: Each block references the previous block's hash
- **Data Storage**: Sequential file-based persistence
- **Validation**: Verify entire chain integrity

### Technical Features
- **GnuCOBOL**: Modern COBOL compiler for Linux/Unix
- **OpenSSL Integration**: Industry-standard SHA-256 hashing
- **C Interoperability**: COBOL calls C functions for cryptography
- **Fixed-Width Records**: Each block is ~416 bytes
- **Configurable Difficulty**: 2-6 leading zeros (easy to very hard)

## Requirements

### System Requirements
- Linux/Unix operating system (tested on Ubuntu 24.04)
- GnuCOBOL 3.x or higher
- GCC (GNU Compiler Collection)
- OpenSSL libraries (libssl, libcrypto)
- Make

### Installation

On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y gnucobol libssl-dev build-essential
```

On Fedora/RHEL:
```bash
sudo dnf install gnucobol openssl-devel gcc make
```

## Building the Project

### Quick Start
```bash
# Clone the repository
git clone https://github.com/nicolasestrem/blockchain-cobol.git
cd blockchain-cobol

# Build the project
make

# Run the blockchain
make run
```

### Build Targets

- `make all` - Build the complete blockchain system (default)
- `make blockchain-static` - Build with static linking (simpler, recommended)
- `make run` - Build and run the blockchain
- `make test` - Run the test suite
- `make test-hash` - Test SHA-256 implementation only
- `make clean` - Remove build artifacts
- `make clean-all` - Remove build artifacts and blockchain data
- `make help` - Display all available targets

## Usage

### Running the Blockchain

```bash
./build/blockchain
```

### Menu Options

```
╔════════════════════════════════════════╗
║   COBOL BLOCKCHAIN MENU                ║
╠════════════════════════════════════════╣
║  1. Add New Block                      ║
║  2. Display Blockchain                 ║
║  3. Validate Chain                     ║
║  4. Set Mining Difficulty              ║
║  9. Exit                               ║
╚════════════════════════════════════════╝
```

### Example Session

1. **First Run**: Automatically creates genesis block
   ```
   ===== COBOL BLOCKCHAIN SYSTEM =====
   Initializing blockchain...
   Creating new blockchain...
   Mining genesis block...
   Genesis block mined successfully!
   Nonce: 000000000000000818
   Hash: 00029950da1970583c84d522fe3bf8dc
   ```

2. **Add a Transaction**: Select option 1
   ```
   Enter transaction data (max 256 chars):
   Alice sends 10 BTC to Bob

   Mining block 00000001...
   Block added successfully!
   Nonce: 000000000000006209
   Hash: 00012bfb138f212392b16daf69a85c81
   ```

3. **Display Chain**: Select option 2
   ```
   Block #       0
     Timestamp: 2026011414250559+010
     Prev Hash: 00000000000000000000000000000000...
     Data: Genesis Block - COBOL Blockchain
     Nonce:                818
     Hash: 00029950da1970583c84d522fe3bf8dc...

   Block #       1
     Timestamp: 2026011414250559+010
     Prev Hash: 00029950da1970583c84d522fe3bf8dc...
     Data: Alice sends 10 BTC to Bob
     Nonce:               6209
     Hash: 00012bfb138f212392b16daf69a85c81...
   ```

4. **Validate Chain**: Select option 3
   ```
   ✓ BLOCKCHAIN IS VALID
     Total Blocks Validated: 00000002
   ```

### Mining Difficulty Guide

- **Difficulty 2** (Very Easy): ~0.1 seconds per block
- **Difficulty 3** (Easy): ~1 second per block (default)
- **Difficulty 4** (Medium): ~15 seconds per block
- **Difficulty 5** (Hard): ~4 minutes per block
- **Difficulty 6** (Very Hard): ~1 hour per block

## Architecture

### Project Structure

```
blockchain-cobol/
├── src/
│   ├── cobol/
│   │   └── BLOCKCHAIN.cbl          # Main blockchain program
│   ├── c/
│   │   ├── sha256.c                # SHA-256 C wrapper
│   │   └── sha256.h                # Header file
│   └── include/
│       └── BLOCKREC.cpy            # Block structure copybook
├── data/
│   └── blockchain.dat              # Sequential blockchain file
├── build/                          # Build artifacts
├── tests/
│   ├── test-sha256.c               # C test for SHA-256
│   ├── test-simple.sh              # Simple blockchain test
│   └── test-blockchain.sh          # Comprehensive test suite
├── Makefile                        # Build system
└── README.md                       # This file
```

### Block Structure

Each block contains 416 bytes of data:

```cobol
01  BLOCK-STRUCTURE.
    05  BLOCK-INDEX          PIC 9(8) COMP.        * 4 bytes
    05  BLOCK-TIMESTAMP      PIC X(20).            * 20 bytes
    05  BLOCK-PREV-HASH      PIC X(64).            * 64 bytes
    05  BLOCK-DATA           PIC X(256).           * 256 bytes
    05  BLOCK-NONCE          PIC 9(18) COMP.       * 8 bytes
    05  BLOCK-CURRENT-HASH   PIC X(64).            * 64 bytes
```

### How It Works

1. **Hashing**: COBOL calls a C function `sha256_hash()` which uses OpenSSL
2. **Mining**: Loop increments nonce until hash meets difficulty (N leading zeros)
3. **Chain Linking**: Each block stores previous block's hash
4. **Storage**: Sequential file appends new blocks
5. **Validation**: Recalculate all hashes and verify chain integrity

## Testing

### Run All Tests
```bash
make test
```

### Test Suite Includes:
1. **SHA-256 Hash Function Test**: Verifies correct hash output for known inputs
2. **Genesis Block Creation**: Tests automatic blockchain initialization
3. **Block Addition**: Tests mining and adding new blocks
4. **Chain Display**: Tests blockchain visualization
5. **Chain Validation**: Tests integrity checking
6. **Corruption Detection**: Tests tamper detection

### Manual Testing
```bash
# Clean start
make clean-all

# Run blockchain
make run

# Follow the menu to add blocks and validate
```

## Performance

### Mining Performance (Difficulty 3, Modern CPU)

- Average nonces per block: ~1,000-8,000
- Average time per block: ~1-2 seconds
- Hash rate: ~2,500 hashes/second

### Blockchain Size

- Each block: ~416 bytes
- 100 blocks: ~41 KB
- 1,000 blocks: ~406 KB
- 10,000 blocks: ~4 MB

## Technical Details

### COBOL-C Interoperability

COBOL passes fixed-length, space-padded strings to C:

```cobol
CALL "sha256_hash" USING WS-HASH-INPUT WS-HASH-OUTPUT
```

C receives pointer and trims spaces:

```c
void sha256_hash(char *input, char *output) {
    // Trim trailing spaces
    size_t len = MAX_INPUT_LENGTH;
    while (len > 0 && input[len-1] == ' ') len--;

    // Compute SHA-256
    SHA256((unsigned char*)input, len, hash);

    // Convert to hex string
    for (int i = 0; i < 32; i++)
        sprintf(output + (i*2), "%02x", hash[i]);
}
```

### Proof-of-Work Algorithm

```cobol
MINE-BLOCK.
    MOVE 0 TO WS-NONCE
    PERFORM UNTIL HASH-IS-VALID
        PERFORM CALCULATE-HASH
        PERFORM CHECK-HASH-DIFFICULTY
        IF NOT HASH-IS-VALID THEN
            ADD 1 TO WS-NONCE
        END-IF
    END-PERFORM.
```

## Limitations

### Educational Purpose
This blockchain is designed for educational and demonstration purposes. It is **NOT**:
- Suitable for production cryptocurrency
- Network-enabled (single-node only)
- Optimized for high-performance mining
- Equipped with advanced security features

### Known Limitations
- **Single-user**: No concurrent access support
- **Sequential file**: No indexed lookups
- **No networking**: Cannot sync with other nodes
- **Limited performance**: COBOL is slower than C/Rust for mining
- **Fixed block size**: 256-byte transaction data limit

## Future Enhancements

Potential improvements for learning:
- [ ] Network synchronization (P2P)
- [ ] VSAM indexed files for faster lookups
- [ ] JSON import/export
- [ ] Smart contracts (embedded COBOL scripts)
- [ ] Web interface (CGI)
- [ ] Multi-threading for mining
- [ ] Account balance tracking
- [ ] Digital signatures

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- **GnuCOBOL Team**: For maintaining an excellent modern COBOL compiler
- **OpenSSL Project**: For providing robust cryptographic libraries
- **Satoshi Nakamoto**: For inventing blockchain technology
- **COBOL Community**: For keeping the language alive and relevant

## Contact

For questions, issues, or discussions:
- Open an issue on GitHub
- Email: nicolab@estrem.eu
- Website: https://estrem.eu

## See Also

- [GnuCOBOL Documentation](https://gnucobol.sourceforge.io/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Bitcoin Whitepaper](https://bitcoin.org/bitcoin.pdf)
- [Blockchain Basics](https://en.wikipedia.org/wiki/Blockchain)

---

**Made with COBOL**

Demonstrating that even a 60+ year old language by a 45 year old coder can implement cutting-edge technology.
