/*
 * SHA-256 Wrapper for GnuCOBOL Blockchain Implementation
 *
 * This header provides SHA-256 hashing functionality compatible with
 * GnuCOBOL's calling conventions.
 *
 * Author: COBOL Blockchain Project
 * Date: 2026-01-14
 */

#ifndef SHA256_H
#define SHA256_H

#include <stdint.h>
#include <stddef.h>

/*
 * GnuCOBOL-compatible SHA-256 hash function
 *
 * Parameters:
 *   input  - Fixed-length COBOL string (space-padded, not null-terminated)
 *            Expected max length: 512 characters
 *   output - Buffer to receive 64-character hex string
 *            Will contain lowercase hex digits (0-9, a-f)
 *
 * Note: This function is designed to be called from COBOL using:
 *       CALL "sha256_hash" USING input-field output-field
 */
void sha256_hash(char *input, char *output);

/*
 * Internal helper: Compute SHA-256 hash
 *
 * Parameters:
 *   data - Input data to hash
 *   len  - Length of input data in bytes
 *   hash - Output buffer (must be 32 bytes)
 */
void sha256_compute(const uint8_t *data, size_t len, uint8_t hash[32]);

/*
 * Internal helper: Convert SHA-256 hash to hex string
 *
 * Parameters:
 *   hash - 32-byte hash value
 *   hex  - Output buffer for 65-character hex string (64 chars + null)
 */
void sha256_to_hex(const uint8_t hash[32], char hex[65]);

#endif /* SHA256_H */
