#!/bin/bash
# Simple blockchain test

set -e

echo "Cleaning old blockchain..."
rm -f data/blockchain.dat

echo ""
echo "Test 1: Genesis block and add block, display, validate"
echo "========================================================"
(
    echo "1"  # Add block
    echo "Transaction 1: Alice sends 10 BTC to Bob"
    echo ""  # Press ENTER to continue
    echo "2"  # Display blockchain
    echo ""  # Press ENTER to continue
    echo "3"  # Validate chain
    echo ""  # Press ENTER to continue
    echo "9"  # Exit
) | ./build/blockchain | tee /tmp/blockchain-test.log

echo ""
echo "Test 2: Check blockchain file"
echo "=============================="
if [ -f data/blockchain.dat ]; then
    FILE_SIZE=$(stat -c%s data/blockchain.dat)
    echo "Blockchain file exists: data/blockchain.dat"
    echo "File size: $FILE_SIZE bytes"

    # Each block is ~416 bytes, so 2 blocks should be ~832 bytes
    if [ $FILE_SIZE -gt 700 ]; then
        echo "✓ File size looks correct for 2 blocks (genesis + 1 transaction)"
    else
        echo "✗ File size too small: $FILE_SIZE bytes"
        exit 1
    fi
else
    echo "✗ Blockchain file not created"
    exit 1
fi

echo ""
echo "Test 3: Check for valid hash output"
echo "===================================="
if grep -q "Hash:" /tmp/blockchain-test.log; then
    echo "✓ Found hash output in logs"
else
    echo "✗ No hash output found"
    exit 1
fi

if grep -q "BLOCKCHAIN IS VALID" /tmp/blockchain-test.log; then
    echo "✓ Blockchain validation passed"
else
    echo "✗ Blockchain validation failed or not found"
    exit 1
fi

echo ""
echo "===== ALL TESTS PASSED ====="
