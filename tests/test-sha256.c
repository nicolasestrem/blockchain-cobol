/*
 * Test program for SHA-256 wrapper
 *
 * Tests the sha256_hash function with known test vectors
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Declare the external function from sha256.c */
extern void sha256_hash(char *input, char *output);

typedef struct {
    const char *input;
    const char *expected_hash;
} TestVector;

int main() {
    /* Known SHA-256 test vectors */
    TestVector tests[] = {
        {"hello", "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"},
        {"", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
        {"The quick brown fox jumps over the lazy dog", "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"},
        {"blockchain", "ef7797e13d3a75526946a3bcf00daec9fc9c9c4d51ddc7cc5df888f74dd434d1"},
    };

    int num_tests = sizeof(tests) / sizeof(TestVector);
    int passed = 0;
    int failed = 0;

    printf("===== SHA-256 Test Suite =====\n\n");

    for (int i = 0; i < num_tests; i++) {
        char input[512];
        char output[65];

        /* Clear buffers */
        memset(input, ' ', sizeof(input));
        memset(output, 0, sizeof(output));

        /* Copy test input (simulating COBOL fixed-length field) */
        strncpy(input, tests[i].input, strlen(tests[i].input));

        /* Call the hash function */
        sha256_hash(input, output);

        /* Verify result */
        if (strncmp(output, tests[i].expected_hash, 64) == 0) {
            printf("[PASS] Test %d: \"%s\"\n", i + 1, tests[i].input);
            printf("       Hash: %s\n\n", output);
            passed++;
        } else {
            printf("[FAIL] Test %d: \"%s\"\n", i + 1, tests[i].input);
            printf("       Expected: %s\n", tests[i].expected_hash);
            printf("       Got:      %s\n\n", output);
            failed++;
        }
    }

    printf("===== Test Results =====\n");
    printf("Passed: %d/%d\n", passed, num_tests);
    printf("Failed: %d/%d\n", failed, num_tests);

    return (failed == 0) ? 0 : 1;
}
