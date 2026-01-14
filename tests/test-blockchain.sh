#!/bin/bash
#########################################################################
# Comprehensive Blockchain Test Suite
#
# Tests all major functionality of the COBOL blockchain implementation
#########################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Functions
print_test() {
    echo ""
    echo "========================================="
    echo "Test $1: $2"
    echo "========================================="
    TESTS_RUN=$((TESTS_RUN + 1))
}

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    if [ "$2" != "continue" ]; then
        exit 1
    fi
}

# Start tests
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  COBOL BLOCKCHAIN - COMPREHENSIVE TEST SUITE         ║"
echo "╚═══════════════════════════════════════════════════════╝"

#########################################################################
# Test 1: Build System
#########################################################################
print_test 1 "Build System"

echo "Cleaning previous build..."
make clean > /dev/null 2>&1

echo "Building project..."
if make blockchain-static > /tmp/build.log 2>&1; then
    pass "Project builds successfully"
else
    fail "Build failed" continue
    cat /tmp/build.log
    exit 1
fi

if [ -f build/blockchain ]; then
    pass "Blockchain executable created"
else
    fail "Blockchain executable not found"
fi

#########################################################################
# Test 2: SHA-256 Hash Function
#########################################################################
print_test 2 "SHA-256 Hash Function"

echo "Building SHA-256 test..."
if gcc -o build/test-sha256 tests/test-sha256.c src/c/sha256.c -lssl -lcrypto 2>/dev/null; then
    pass "SHA-256 test compiled"
else
    fail "SHA-256 test compilation failed"
fi

echo "Running SHA-256 tests..."
if build/test-sha256 > /tmp/sha256-test.log 2>&1; then
    pass "SHA-256 produces correct hashes"
else
    fail "SHA-256 hash verification failed"
fi

# Verify specific test cases
if grep -q "PASS.*hello" /tmp/sha256-test.log; then
    pass "SHA-256 'hello' test vector correct"
else
    fail "SHA-256 'hello' test vector incorrect"
fi

#########################################################################
# Test 3: Genesis Block Creation
#########################################################################
print_test 3 "Genesis Block Creation"

echo "Removing old blockchain..."
rm -f data/blockchain.dat

echo "Creating genesis block..."
(
    echo "9"  # Exit immediately
) | timeout 30 build/blockchain > /tmp/genesis-test.log 2>&1

if [ -f data/blockchain.dat ]; then
    pass "Blockchain file created"
else
    fail "Blockchain file not created"
fi

FILE_SIZE=$(stat -c%s data/blockchain.dat 2>/dev/null || stat -f%z data/blockchain.dat 2>/dev/null)
if [ $FILE_SIZE -gt 400 ]; then
    pass "Genesis block written (size: $FILE_SIZE bytes)"
else
    fail "Genesis block too small or missing"
fi

if grep -q "Genesis block mined successfully" /tmp/genesis-test.log; then
    pass "Genesis block mining successful"
else
    fail "Genesis block mining message not found"
fi

if grep -q "Nonce:" /tmp/genesis-test.log; then
    pass "Genesis block nonce found"
else
    fail "Genesis block nonce not displayed"
fi

#########################################################################
# Test 4: Adding Blocks
#########################################################################
print_test 4 "Adding Transaction Blocks"

echo "Adding 2 transaction blocks..."
(
    echo "1"  # Add block
    echo "Test Transaction 1"
    echo ""  # Press ENTER
    echo "1"  # Add another block
    echo "Test Transaction 2"
    echo ""  # Press ENTER
    echo "9"  # Exit
) | timeout 60 build/blockchain > /tmp/add-blocks-test.log 2>&1

FILE_SIZE=$(stat -c%s data/blockchain.dat 2>/dev/null || stat -f%z data/blockchain.dat 2>/dev/null)
if [ $FILE_SIZE -gt 1200 ]; then
    pass "Multiple blocks added (size: $FILE_SIZE bytes)"
else
    fail "Blocks not added correctly"
fi

BLOCK_COUNT=$(grep -c "Block added successfully" /tmp/add-blocks-test.log || echo "0")
if [ $BLOCK_COUNT -ge 2 ]; then
    pass "Successfully mined $BLOCK_COUNT new blocks"
else
    fail "Expected 2 blocks, got $BLOCK_COUNT"
fi

#########################################################################
# Test 5: Display Blockchain
#########################################################################
print_test 5 "Display Blockchain"

echo "Displaying blockchain..."
(
    echo "2"  # Display
    echo ""  # Press ENTER
    echo "9"  # Exit
) | timeout 30 build/blockchain > /tmp/display-test.log 2>&1

if grep -q "Block #" /tmp/display-test.log; then
    pass "Blockchain display shows blocks"
else
    fail "Blockchain display failed"
fi

if grep -q "Timestamp:" /tmp/display-test.log; then
    pass "Block timestamps displayed"
else
    fail "Block timestamps missing"
fi

if grep -q "Hash:" /tmp/display-test.log; then
    pass "Block hashes displayed"
else
    fail "Block hashes missing"
fi

if grep -q "Nonce:" /tmp/display-test.log; then
    pass "Block nonces displayed"
else
    fail "Block nonces missing"
fi

DISPLAYED_BLOCKS=$(grep -c "Block #" /tmp/display-test.log || echo "0")
if [ $DISPLAYED_BLOCKS -ge 3 ]; then
    pass "All $DISPLAYED_BLOCKS blocks displayed"
else
    fail "Expected 3+ blocks in display, got $DISPLAYED_BLOCKS"
fi

#########################################################################
# Test 6: Chain Validation
#########################################################################
print_test 6 "Chain Validation"

echo "Validating blockchain..."
(
    echo "3"  # Validate
    echo ""  # Press ENTER
    echo "9"  # Exit
) | timeout 30 build/blockchain > /tmp/validate-test.log 2>&1

if grep -q "BLOCKCHAIN IS VALID" /tmp/validate-test.log; then
    pass "Blockchain validation passed"
else
    fail "Blockchain validation failed"
    cat /tmp/validate-test.log
fi

if grep -q "Total Blocks Validated:" /tmp/validate-test.log; then
    pass "Validation counted all blocks"
else
    fail "Block count missing from validation"
fi

#########################################################################
# Test 7: Corruption Detection
#########################################################################
print_test 7 "Corruption Detection"

echo "Backing up valid blockchain..."
cp data/blockchain.dat data/blockchain.dat.backup

echo "Corrupting blockchain file..."
dd if=/dev/urandom of=data/blockchain.dat bs=1 count=10 seek=100 conv=notrunc 2>/dev/null

echo "Validating corrupted blockchain..."
(
    echo "3"  # Validate
    echo ""  # Press ENTER
    echo "9"  # Exit
) | timeout 30 build/blockchain > /tmp/corrupt-test.log 2>&1 || true

if grep -q "INVALID" /tmp/corrupt-test.log; then
    pass "Corruption detected successfully"
else
    fail "Corruption not detected"
fi

echo "Restoring valid blockchain..."
mv data/blockchain.dat.backup data/blockchain.dat

#########################################################################
# Test 8: Different Difficulty Levels
#########################################################################
print_test 8 "Mining with Different Difficulties"

for DIFF in 2 3 4; do
    echo "Testing difficulty $DIFF..."
    rm -f data/blockchain.dat

    START_TIME=$(date +%s)
    (
        echo "4"  # Set difficulty
        echo "$DIFF"
        echo ""  # Press ENTER
        echo "1"  # Add block
        echo "Difficulty $DIFF test"
        echo ""  # Press ENTER
        echo "9"  # Exit
    ) | timeout 120 build/blockchain > /tmp/diff-$DIFF-test.log 2>&1 || true
    END_TIME=$(date +%s)

    ELAPSED=$((END_TIME - START_TIME))

    if grep -q "Block added successfully" /tmp/diff-$DIFF-test.log; then
        pass "Difficulty $DIFF: block mined in ${ELAPSED}s"
    else
        fail "Difficulty $DIFF: mining failed or timeout"
    fi
done

#########################################################################
# Test 9: Hash Requirements
#########################################################################
print_test 9 "Hash Leading Zeros Requirement"

rm -f data/blockchain.dat
(
    echo "4"  # Set difficulty
    echo "3"
    echo ""  # Press ENTER
    echo "1"  # Add block
    echo "Hash test"
    echo ""  # Press ENTER
    echo "2"  # Display
    echo ""  # Press ENTER
    echo "9"  # Exit
) | timeout 60 build/blockchain > /tmp/hash-req-test.log 2>&1

# Extract hashes and check for leading zeros
if grep "Hash: 000" /tmp/hash-req-test.log > /dev/null; then
    pass "Hashes meet difficulty requirement (3 leading zeros)"
else
    fail "Hashes don't meet difficulty requirement"
fi

#########################################################################
# Test 10: File Persistence
#########################################################################
print_test 10 "File Persistence"

rm -f data/blockchain.dat

echo "Creating blockchain in first run..."
(
    echo "1"  # Add block
    echo "Persistence test block"
    echo ""  # Press ENTER
    echo "9"  # Exit
) | timeout 60 build/blockchain > /tmp/persist-1.log 2>&1

FIRST_SIZE=$(stat -c%s data/blockchain.dat 2>/dev/null || stat -f%z data/blockchain.dat 2>/dev/null)

echo "Loading blockchain in second run..."
(
    echo "2"  # Display
    echo ""  # Press ENTER
    echo "9"  # Exit
) | timeout 30 build/blockchain > /tmp/persist-2.log 2>&1

SECOND_SIZE=$(stat -c%s data/blockchain.dat 2>/dev/null || stat -f%z data/blockchain.dat 2>/dev/null)

if [ "$FIRST_SIZE" -eq "$SECOND_SIZE" ]; then
    pass "Blockchain persists between runs"
else
    fail "Blockchain file size changed: $FIRST_SIZE -> $SECOND_SIZE"
fi

if grep -q "Blockchain loaded" /tmp/persist-2.log; then
    pass "Blockchain loaded from file"
else
    fail "Blockchain not loaded from file"
fi

#########################################################################
# Test Results Summary
#########################################################################
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║                  TEST RESULTS SUMMARY                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Total Tests Run:    $TESTS_RUN"
echo -e "Tests Passed:       ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:       ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✓ ALL TESTS PASSED ✓                    ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ✗ SOME TESTS FAILED ✗                   ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
