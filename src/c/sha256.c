/*
 * SHA-256 Wrapper Implementation for GnuCOBOL
 *
 * This implementation provides SHA-256 hashing using OpenSSL's crypto library.
 * It handles the conversion between COBOL's fixed-length space-padded strings
 * and C's null-terminated strings.
 *
 * Author: COBOL Blockchain Project
 * Date: 2026-01-14
 */

#include <string.h>
#include <stdio.h>
#include <openssl/sha.h>
#include "sha256.h"

/* Maximum input length from COBOL */
#define MAX_INPUT_LENGTH 512

/*
 * Main GnuCOBOL-callable function
 *
 * This function:
 * 1. Trims trailing spaces from COBOL fixed-length string
 * 2. Computes SHA-256 hash using OpenSSL
 * 3. Converts hash to 64-character lowercase hex string
 * 4. Writes result to output buffer
 */
void sha256_hash(char *input, char *output) {
    unsigned char hash[SHA256_DIGEST_LENGTH];
    size_t input_len;
    int i;

    /* Find actual length by trimming trailing spaces */
    /* COBOL strings are space-padded to fixed length */
    input_len = MAX_INPUT_LENGTH;
    while (input_len > 0 && input[input_len - 1] == ' ') {
        input_len--;
    }

    /* Compute SHA-256 hash using OpenSSL */
    SHA256((unsigned char*)input, input_len, hash);

    /* Convert hash bytes to lowercase hexadecimal string */
    for (i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        sprintf(output + (i * 2), "%02x", hash[i]);
    }

    /* Ensure null termination (although COBOL doesn't require it) */
    output[64] = '\0';
}

/*
 * Internal helper: Direct SHA-256 computation wrapper
 * (Currently just uses OpenSSL, but this function allows
 *  for future pure C implementation if desired)
 */
void sha256_compute(const uint8_t *data, size_t len, uint8_t hash[32]) {
    SHA256(data, len, hash);
}

/*
 * Internal helper: Convert hash bytes to hex string
 */
void sha256_to_hex(const uint8_t hash[32], char hex[65]) {
    int i;
    for (i = 0; i < 32; i++) {
        sprintf(hex + (i * 2), "%02x", hash[i]);
    }
    hex[64] = '\0';
}
