# ===================================================================
# Makefile for COBOL Blockchain Project
#
# This Makefile automates the build process for the blockchain system.
# It compiles the C SHA-256 wrapper and links it with the COBOL program.
#
# Author: COBOL Blockchain Project
# Date: 2026-01-14
# ===================================================================

# Compiler and tools
CC = gcc
COBC = cobc
CFLAGS = -Wall -O2 -fPIC
COBFLAGS = -x -free -std=default
LDFLAGS = -lssl -lcrypto

# Directories
SRC_DIR = src
COBOL_DIR = $(SRC_DIR)/cobol
C_DIR = $(SRC_DIR)/c
INCLUDE_DIR = $(SRC_DIR)/include
BUILD_DIR = build
DATA_DIR = data
TEST_DIR = tests

# Source files
COBOL_MAIN = $(COBOL_DIR)/BLOCKCHAIN.cbl
C_SHA256 = $(C_DIR)/sha256.c
C_SHA256_HEADER = $(C_DIR)/sha256.h
COPYBOOK = $(INCLUDE_DIR)/BLOCKREC.cpy

# Build targets
BLOCKCHAIN_BIN = $(BUILD_DIR)/blockchain
SHA256_LIB = $(BUILD_DIR)/libsha256.so
TEST_SHA256 = $(BUILD_DIR)/test-sha256

# Default target
.PHONY: all
all: setup $(BLOCKCHAIN_BIN)
	@echo ""
	@echo "===== Build Complete ====="
	@echo "Blockchain executable: $(BLOCKCHAIN_BIN)"
	@echo "Run with: make run"
	@echo ""

# Setup directories
.PHONY: setup
setup:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(DATA_DIR)

# Build shared C library for SHA-256
$(SHA256_LIB): $(C_SHA256) $(C_SHA256_HEADER)
	@echo "Compiling SHA-256 library..."
	$(CC) $(CFLAGS) -shared -o $@ $(C_SHA256) $(LDFLAGS)
	@echo "SHA-256 library created: $@"

# Build COBOL main program
$(BLOCKCHAIN_BIN): $(COBOL_MAIN) $(SHA256_LIB) $(COPYBOOK)
	@echo "Compiling COBOL blockchain program..."
	$(COBC) $(COBFLAGS) -o $@ $(COBOL_MAIN) \
		-I$(INCLUDE_DIR) -L$(BUILD_DIR) -lsha256 $(LDFLAGS)
	@echo "Blockchain executable created: $@"

# Alternative: Build with static linking (simpler)
.PHONY: blockchain-static
blockchain-static: setup $(C_SHA256) $(COBOL_MAIN) $(COPYBOOK)
	@echo "Compiling blockchain (static linking)..."
	$(COBC) $(COBFLAGS) -o $(BLOCKCHAIN_BIN) \
		$(COBOL_MAIN) $(C_SHA256) -I$(INCLUDE_DIR) $(LDFLAGS)
	@echo "Blockchain executable created: $(BLOCKCHAIN_BIN)"

# Build test program for SHA-256
$(TEST_SHA256): $(TEST_DIR)/test-sha256.c $(C_SHA256)
	@echo "Compiling SHA-256 test..."
	$(CC) -o $@ $(TEST_DIR)/test-sha256.c $(C_SHA256) $(LDFLAGS)

# Run the blockchain program
.PHONY: run
run: all
	@echo "Starting blockchain system..."
	@echo ""
	LD_LIBRARY_PATH=$(BUILD_DIR):$$LD_LIBRARY_PATH $(BLOCKCHAIN_BIN)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)/*
	@echo "Build directory cleaned."

# Clean everything including blockchain data
.PHONY: clean-all
clean-all: clean
	@echo "Cleaning blockchain data..."
	rm -f $(DATA_DIR)/*.dat
	@echo "All data cleaned."

# Run test suite
.PHONY: test
test: all $(TEST_SHA256)
	@echo ""
	@echo "===== Running Test Suite ====="
	@echo ""
	@echo "Test 1: SHA-256 Hash Function"
	@$(TEST_SHA256)
	@echo ""
	@echo "Test 2: Full Blockchain Test"
	@chmod +x $(TEST_DIR)/test-blockchain.sh
	@$(TEST_DIR)/test-blockchain.sh

# Quick test - just SHA-256
.PHONY: test-hash
test-hash: $(TEST_SHA256)
	@echo "Testing SHA-256 implementation..."
	@$(TEST_SHA256)

# Install to system (requires sudo)
.PHONY: install
install: all
	@echo "Installing blockchain to /usr/local/bin..."
	sudo cp $(BLOCKCHAIN_BIN) /usr/local/bin/blockchain
	sudo cp $(SHA256_LIB) /usr/local/lib/
	sudo ldconfig
	@echo "Installation complete. Run with: blockchain"

# Uninstall from system
.PHONY: uninstall
uninstall:
	@echo "Uninstalling blockchain..."
	sudo rm -f /usr/local/bin/blockchain
	sudo rm -f /usr/local/lib/libsha256.so
	sudo ldconfig
	@echo "Uninstall complete."

# Display help
.PHONY: help
help:
	@echo "COBOL Blockchain - Makefile Targets"
	@echo ""
	@echo "Build Targets:"
	@echo "  all               - Build blockchain program (default)"
	@echo "  blockchain-static - Build with static linking"
	@echo "  setup             - Create build and data directories"
	@echo ""
	@echo "Run Targets:"
	@echo "  run               - Build and run blockchain"
	@echo "  test              - Run full test suite"
	@echo "  test-hash         - Test SHA-256 implementation only"
	@echo ""
	@echo "Maintenance Targets:"
	@echo "  clean             - Remove build artifacts"
	@echo "  clean-all         - Remove build artifacts and blockchain data"
	@echo "  install           - Install to system (requires sudo)"
	@echo "  uninstall         - Remove from system (requires sudo)"
	@echo ""
	@echo "Help:"
	@echo "  help              - Display this help message"

# Rebuild everything from scratch
.PHONY: rebuild
rebuild: clean-all all

# Check dependencies
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@which $(COBC) > /dev/null || (echo "ERROR: GnuCOBOL not found" && exit 1)
	@which $(CC) > /dev/null || (echo "ERROR: GCC not found" && exit 1)
	@$(CC) -lssl -lcrypto -x c -o /dev/null - < /dev/null 2>/dev/null || \
		(echo "ERROR: OpenSSL libraries not found" && exit 1)
	@echo "✓ All dependencies installed"
	@echo "  GnuCOBOL: $$($(COBC) --version | head -1)"
	@echo "  GCC: $$($(CC) --version | head -1)"
	@echo "  OpenSSL: $$(openssl version)"

# Show project info
.PHONY: info
info:
	@echo "COBOL Blockchain Project"
	@echo "========================"
	@echo "Source Directory: $(SRC_DIR)"
	@echo "Build Directory: $(BUILD_DIR)"
	@echo "Data Directory: $(DATA_DIR)"
	@echo "COBOL Source: $(COBOL_MAIN)"
	@echo "C Source: $(C_SHA256)"
	@echo "Copybook: $(COPYBOOK)"
	@echo "Executable: $(BLOCKCHAIN_BIN)"
	@echo ""
	@$(MAKE) -s check-deps
