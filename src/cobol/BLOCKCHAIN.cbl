       IDENTIFICATION DIVISION.
       PROGRAM-ID. BLOCKCHAIN.
      *> ================================================================
      *> BLOCKCHAIN - Main Blockchain Program
      *>
      *> PURPOSE:
      *>   Implements a complete blockchain system with:
      *>   - Sequential file-based ledger
      *>   - Proof-of-Work mining with configurable difficulty
      *>   - SHA-256 hashing via C wrapper
      *>   - Chain validation
      *>   - Interactive menu interface
      *>
      *> AUTHOR: COBOL Blockchain Project
      *> DATE: 2026-01-14
      *>
      *> DEPENDENCIES:
      *>   - GnuCOBOL 3.x or higher
      *>   - OpenSSL library (libssl, libcrypto)
      *>   - sha256_hash C function (sha256.c)
      *>   - BLOCKREC.cpy copybook
      *> ================================================================

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. GNU-LINUX.
       OBJECT-COMPUTER. GNU-LINUX.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BLOCKCHAIN-FILE
               ASSIGN TO "data/blockchain.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  BLOCKCHAIN-FILE.
       COPY BLOCKREC REPLACING ==BLOCK-STRUCTURE== BY ==BLOCK-RECORD==.

       WORKING-STORAGE SECTION.
      *> ================================================================
      *> File Status and Control Variables                             *
      *> ================================================================
       01  WS-FILE-STATUS           PIC XX.
           88  FILE-SUCCESS         VALUE "00".
           88  FILE-EOF             VALUE "10".
           88  FILE-NOT-FOUND       VALUE "35".

      *> ================================================================
      *> Menu and User Interface Variables                             *
      *> ================================================================
       01  WS-MENU-CHOICE           PIC 9.
           88  CHOICE-ADD-BLOCK     VALUE 1.
           88  CHOICE-DISPLAY       VALUE 2.
           88  CHOICE-VALIDATE      VALUE 3.
           88  CHOICE-SET-DIFFICULTY VALUE 4.
           88  CHOICE-EXIT          VALUE 9.

       01  WS-CONTINUE              PIC X.

      *> ================================================================
      *> Mining Configuration                                          *
      *> ================================================================
       01  WS-DIFFICULTY            PIC 99 VALUE 3.
       01  WS-TARGET-PREFIX         PIC X(8) VALUE SPACES.
       01  WS-HASH-PREFIX           PIC X(8).
       01  WS-HASH-VALID            PIC 9 VALUE 0.
           88  HASH-IS-VALID        VALUE 1.

      *> ================================================================
      *> Current Block Workspace                                       *
      *> ================================================================
       01  WS-CURRENT-BLOCK.
           05  WS-BLOCK-INDEX       PIC 9(8) COMP VALUE 0.
           05  WS-TIMESTAMP         PIC X(20).
           05  WS-PREV-HASH         PIC X(64).
           05  WS-DATA              PIC X(256).
           05  WS-NONCE             PIC 9(18) COMP VALUE 0.
           05  WS-CURRENT-HASH      PIC X(64).

      *> ================================================================
      *> Hash Calculation Buffers                                      *
      *> ================================================================
       01  WS-HASH-INPUT            PIC X(512).
       01  WS-HASH-OUTPUT           PIC X(64).

      *> ================================================================
      *> Chain Validation Variables                                    *
      *> ================================================================
       01  WS-VALIDATION-DATA.
           05  WS-BLOCK-COUNT       PIC 9(8) COMP VALUE 0.
           05  WS-CHAIN-VALID       PIC 9 VALUE 1.
               88  CHAIN-IS-VALID   VALUE 1.
               88  CHAIN-IS-INVALID VALUE 0.
           05  WS-LAST-HASH         PIC X(64).

      *> ================================================================
      *> Display Formatting Variables                                  *
      *> ================================================================
       01  WS-DISPLAY-DATA.
           05  WS-DISPLAY-INDEX     PIC Z(7)9.
           05  WS-DISPLAY-NONCE     PIC Z(17)9.
           05  WS-SHORT-HASH        PIC X(16).
           05  WS-PROGRESS-COUNTER  PIC 9(8) COMP VALUE 0.

      *> ================================================================
      *> Miscellaneous Variables                                       *
      *> ================================================================
       01  WS-TEMP-INDEX            PIC 9(8) COMP.
       01  WS-LOOP-INDEX            PIC 99 COMP.
       01  WS-GENESIS-HASH          PIC X(64) VALUE ALL "0".

       PROCEDURE DIVISION.

      *> ================================================================
      *> MAIN-LOGIC - Main program entry point                         *
      *> ================================================================
       MAIN-LOGIC.
           PERFORM INITIALIZE-BLOCKCHAIN
           PERFORM MENU-LOOP UNTIL CHOICE-EXIT
           PERFORM CLEANUP
           STOP RUN.

      *> ================================================================
      *> INITIALIZE-BLOCKCHAIN - Initialize or create blockchain file  *
      *> ================================================================
       INITIALIZE-BLOCKCHAIN.
           DISPLAY "===== COBOL BLOCKCHAIN SYSTEM ====="
           DISPLAY "Initializing blockchain..."

           OPEN INPUT BLOCKCHAIN-FILE

           IF FILE-NOT-FOUND THEN
               DISPLAY "Creating new blockchain..."
               OPEN OUTPUT BLOCKCHAIN-FILE
               CLOSE BLOCKCHAIN-FILE
               OPEN EXTEND BLOCKCHAIN-FILE
               PERFORM CREATE-GENESIS-BLOCK
               DISPLAY "Genesis block created."
           ELSE
               CLOSE BLOCKCHAIN-FILE
               OPEN EXTEND BLOCKCHAIN-FILE
               PERFORM COUNT-BLOCKS
               DISPLAY "Blockchain loaded. Blocks: " WS-BLOCK-COUNT
           END-IF

           DISPLAY " "
           .

      *> ================================================================
      *> CREATE-GENESIS-BLOCK - Create the first block in the chain    *
      *> ================================================================
       CREATE-GENESIS-BLOCK.
           DISPLAY "Mining genesis block..."

           MOVE 0 TO WS-BLOCK-INDEX
           PERFORM GET-CURRENT-TIMESTAMP
           MOVE WS-GENESIS-HASH TO WS-PREV-HASH
           MOVE "Genesis Block - COBOL Blockchain" TO WS-DATA
           MOVE 0 TO WS-NONCE

           PERFORM MINE-BLOCK
           PERFORM WRITE-BLOCK-TO-FILE

           DISPLAY "Genesis block mined successfully!"
           DISPLAY "Nonce: " WS-NONCE
           DISPLAY "Hash: " WS-CURRENT-HASH(1:32)
           DISPLAY " "
           .

      *> ================================================================
      *> MENU-LOOP - Display menu and process user selections          *
      *> ================================================================
       MENU-LOOP.
           DISPLAY " "
           DISPLAY "╔════════════════════════════════════════╗"
           DISPLAY "║   COBOL BLOCKCHAIN MENU                ║"
           DISPLAY "╠════════════════════════════════════════╣"
           DISPLAY "║  1. Add New Block                      ║"
           DISPLAY "║  2. Display Blockchain                 ║"
           DISPLAY "║  3. Validate Chain                     ║"
           DISPLAY "║  4. Set Mining Difficulty              ║"
           DISPLAY "║  9. Exit                               ║"
           DISPLAY "╚════════════════════════════════════════╝"
           DISPLAY "Current Difficulty: " WS-DIFFICULTY " leading zeros"
           DISPLAY " "
           DISPLAY "Select option: " WITH NO ADVANCING
           ACCEPT WS-MENU-CHOICE

           EVALUATE TRUE
               WHEN CHOICE-ADD-BLOCK
                   PERFORM ADD-NEW-BLOCK
               WHEN CHOICE-DISPLAY
                   PERFORM DISPLAY-BLOCKCHAIN
               WHEN CHOICE-VALIDATE
                   PERFORM VALIDATE-CHAIN
               WHEN CHOICE-SET-DIFFICULTY
                   PERFORM SET-DIFFICULTY
               WHEN CHOICE-EXIT
                   DISPLAY "Exiting blockchain system..."
               WHEN OTHER
                   DISPLAY "Invalid choice. Please try again."
           END-EVALUATE
           .

      *> ================================================================
      *> ADD-NEW-BLOCK - Add a new block to the blockchain             *
      *> ================================================================
       ADD-NEW-BLOCK.
           DISPLAY " "
           DISPLAY "===== ADD NEW BLOCK ====="

           PERFORM GET-LAST-BLOCK
           ADD 1 TO WS-BLOCK-INDEX
           PERFORM GET-CURRENT-TIMESTAMP

           DISPLAY "Enter transaction data (max 256 chars): "
           ACCEPT WS-DATA

           MOVE 0 TO WS-NONCE
           DISPLAY "Mining block " WS-BLOCK-INDEX "..."
           PERFORM MINE-BLOCK
           PERFORM WRITE-BLOCK-TO-FILE

           DISPLAY "Block added successfully!"
           DISPLAY "Block Index: " WS-BLOCK-INDEX
           DISPLAY "Nonce: " WS-NONCE
           DISPLAY "Hash: " WS-CURRENT-HASH(1:32)
           DISPLAY " "
           DISPLAY "Press ENTER to continue..."
           ACCEPT WS-CONTINUE
           .

      *> ================================================================
      *> GET-LAST-BLOCK - Retrieve the last block from the chain       *
      *> ================================================================
       GET-LAST-BLOCK.
           CLOSE BLOCKCHAIN-FILE
           OPEN INPUT BLOCKCHAIN-FILE

           MOVE 0 TO WS-BLOCK-INDEX
           MOVE WS-GENESIS-HASH TO WS-PREV-HASH

           PERFORM UNTIL FILE-EOF
               READ BLOCKCHAIN-FILE
                   AT END
                       CONTINUE
                   NOT AT END
                       MOVE BLOCK-INDEX TO WS-BLOCK-INDEX
                       MOVE BLOCK-CURRENT-HASH TO WS-PREV-HASH
               END-READ
           END-PERFORM

           CLOSE BLOCKCHAIN-FILE
           OPEN EXTEND BLOCKCHAIN-FILE
           .

      *> ================================================================
      *> MINE-BLOCK - Perform Proof-of-Work mining                     *
      *> ================================================================
       MINE-BLOCK.
           PERFORM BUILD-TARGET-PREFIX
           MOVE 0 TO WS-NONCE
           MOVE 0 TO WS-PROGRESS-COUNTER

           MOVE 0 TO WS-HASH-VALID
           PERFORM UNTIL HASH-IS-VALID
               PERFORM CALCULATE-HASH
               PERFORM CHECK-HASH-DIFFICULTY

               IF NOT HASH-IS-VALID THEN
                   ADD 1 TO WS-NONCE
                   ADD 1 TO WS-PROGRESS-COUNTER

                   IF WS-PROGRESS-COUNTER = 10000 THEN
                       DISPLAY "Trying nonce: " WS-NONCE "..."
                       MOVE 0 TO WS-PROGRESS-COUNTER
                   END-IF
               END-IF
           END-PERFORM
           .

      *> ================================================================
      *> BUILD-TARGET-PREFIX - Create target hash prefix (leading zeros)*
      *> ================================================================
       BUILD-TARGET-PREFIX.
           MOVE ALL "0" TO WS-TARGET-PREFIX
           IF WS-DIFFICULTY > 8 THEN
               MOVE 8 TO WS-DIFFICULTY
           END-IF
           .

      *> ================================================================
      *> CALCULATE-HASH - Compute SHA-256 hash of current block data   *
      *> ================================================================
       CALCULATE-HASH.
           MOVE SPACES TO WS-HASH-INPUT

           STRING WS-BLOCK-INDEX DELIMITED BY SIZE
                  WS-TIMESTAMP DELIMITED BY SIZE
                  WS-PREV-HASH DELIMITED BY SIZE
                  WS-DATA DELIMITED BY SIZE
                  WS-NONCE DELIMITED BY SIZE
               INTO WS-HASH-INPUT
           END-STRING

           CALL "sha256_hash" USING WS-HASH-INPUT WS-HASH-OUTPUT
           MOVE WS-HASH-OUTPUT TO WS-CURRENT-HASH
           .

      *> ================================================================
      *> CHECK-HASH-DIFFICULTY - Check if hash meets PoW requirement   *
      *> ================================================================
       CHECK-HASH-DIFFICULTY.
           MOVE WS-CURRENT-HASH(1:8) TO WS-HASH-PREFIX
           MOVE 1 TO WS-HASH-VALID

           PERFORM VARYING WS-LOOP-INDEX FROM 1 BY 1
                   UNTIL WS-LOOP-INDEX > WS-DIFFICULTY
               IF WS-HASH-PREFIX(WS-LOOP-INDEX:1) NOT = "0" THEN
                   MOVE 0 TO WS-HASH-VALID
                   EXIT PERFORM
               END-IF
           END-PERFORM
           .

      *> ================================================================
      *> WRITE-BLOCK-TO-FILE - Write current block to blockchain file  *
      *> ================================================================
       WRITE-BLOCK-TO-FILE.
           MOVE WS-BLOCK-INDEX TO BLOCK-INDEX
           MOVE WS-TIMESTAMP TO BLOCK-TIMESTAMP
           MOVE WS-PREV-HASH TO BLOCK-PREV-HASH
           MOVE WS-DATA TO BLOCK-DATA
           MOVE WS-NONCE TO BLOCK-NONCE
           MOVE WS-CURRENT-HASH TO BLOCK-CURRENT-HASH

           WRITE BLOCK-RECORD

           IF NOT FILE-SUCCESS THEN
               DISPLAY "ERROR: Failed to write block. Status: "
                       WS-FILE-STATUS
           END-IF
           .

      *> ================================================================
      *> DISPLAY-BLOCKCHAIN - Display all blocks in the chain          *
      *> ================================================================
       DISPLAY-BLOCKCHAIN.
           DISPLAY " "
           DISPLAY "===== BLOCKCHAIN DISPLAY ====="

           CLOSE BLOCKCHAIN-FILE
           OPEN INPUT BLOCKCHAIN-FILE

           MOVE 0 TO WS-BLOCK-COUNT

           PERFORM UNTIL FILE-EOF
               READ BLOCKCHAIN-FILE
                   AT END
                       CONTINUE
                   NOT AT END
                       ADD 1 TO WS-BLOCK-COUNT
                       PERFORM DISPLAY-BLOCK-INFO
               END-READ
           END-PERFORM

           DISPLAY " "
           DISPLAY "Total Blocks: " WS-BLOCK-COUNT

           CLOSE BLOCKCHAIN-FILE
           OPEN EXTEND BLOCKCHAIN-FILE

           DISPLAY " "
           DISPLAY "Press ENTER to continue..."
           ACCEPT WS-CONTINUE
           .

      *> ================================================================
      *> DISPLAY-BLOCK-INFO - Display information for a single block   *
      *> ================================================================
       DISPLAY-BLOCK-INFO.
           MOVE BLOCK-INDEX TO WS-DISPLAY-INDEX
           MOVE BLOCK-NONCE TO WS-DISPLAY-NONCE

           DISPLAY " "
           DISPLAY "Block #" WS-DISPLAY-INDEX
           DISPLAY "  Timestamp: " BLOCK-TIMESTAMP
           DISPLAY "  Prev Hash: " BLOCK-PREV-HASH(1:32) "..."
           DISPLAY "  Data: " BLOCK-DATA
           DISPLAY "  Nonce: " WS-DISPLAY-NONCE
           DISPLAY "  Hash: " BLOCK-CURRENT-HASH(1:32) "..."
           .

      *> ================================================================
      *> VALIDATE-CHAIN - Validate blockchain integrity                *
      *> ================================================================
       VALIDATE-CHAIN.
           DISPLAY " "
           DISPLAY "===== VALIDATING BLOCKCHAIN ====="

           CLOSE BLOCKCHAIN-FILE
           OPEN INPUT BLOCKCHAIN-FILE

           MOVE 0 TO WS-BLOCK-COUNT
           MOVE 1 TO WS-CHAIN-VALID
           MOVE WS-GENESIS-HASH TO WS-LAST-HASH

           PERFORM UNTIL FILE-EOF
               READ BLOCKCHAIN-FILE
                   AT END
                       CONTINUE
                   NOT AT END
                       ADD 1 TO WS-BLOCK-COUNT
                       PERFORM VALIDATE-BLOCK
               END-READ
           END-PERFORM

           CLOSE BLOCKCHAIN-FILE
           OPEN EXTEND BLOCKCHAIN-FILE

           DISPLAY " "
           IF CHAIN-IS-VALID THEN
               DISPLAY "✓ BLOCKCHAIN IS VALID"
               DISPLAY "  Total Blocks Validated: " WS-BLOCK-COUNT
           ELSE
               DISPLAY "✗ BLOCKCHAIN IS INVALID"
               DISPLAY "  Validation failed!"
           END-IF

           DISPLAY " "
           DISPLAY "Press ENTER to continue..."
           ACCEPT WS-CONTINUE
           .

      *> ================================================================
      *> VALIDATE-BLOCK - Validate a single block                      *
      *> ================================================================
       VALIDATE-BLOCK.
           MOVE BLOCK-INDEX TO WS-DISPLAY-INDEX

           IF WS-BLOCK-COUNT > 1 THEN
               IF BLOCK-PREV-HASH NOT = WS-LAST-HASH THEN
                   DISPLAY "✗ Block " WS-DISPLAY-INDEX
                           ": Invalid previous hash"
                   MOVE 0 TO WS-CHAIN-VALID
               END-IF
           END-IF

           MOVE BLOCK-INDEX TO WS-BLOCK-INDEX
           MOVE BLOCK-TIMESTAMP TO WS-TIMESTAMP
           MOVE BLOCK-PREV-HASH TO WS-PREV-HASH
           MOVE BLOCK-DATA TO WS-DATA
           MOVE BLOCK-NONCE TO WS-NONCE

           PERFORM CALCULATE-HASH

           IF WS-CURRENT-HASH NOT = BLOCK-CURRENT-HASH THEN
               DISPLAY "✗ Block " WS-DISPLAY-INDEX
                       ": Hash mismatch"
               MOVE 0 TO WS-CHAIN-VALID
           END-IF

           PERFORM CHECK-HASH-DIFFICULTY
           IF NOT HASH-IS-VALID THEN
               DISPLAY "✗ Block " WS-DISPLAY-INDEX
                       ": Does not meet difficulty"
               MOVE 0 TO WS-CHAIN-VALID
           END-IF

           MOVE BLOCK-CURRENT-HASH TO WS-LAST-HASH
           .

      *> ================================================================
      *> SET-DIFFICULTY - Allow user to change mining difficulty       *
      *> ================================================================
       SET-DIFFICULTY.
           DISPLAY " "
           DISPLAY "===== SET MINING DIFFICULTY ====="
           DISPLAY "Current difficulty: " WS-DIFFICULTY " leading zeros"
           DISPLAY " "
           DISPLAY "Difficulty Guide:"
           DISPLAY "  2 = Very Easy (instant)"
           DISPLAY "  3 = Easy (~1 second)"
           DISPLAY "  4 = Medium (~15 seconds)"
           DISPLAY "  5 = Hard (~4 minutes)"
           DISPLAY "  6 = Very Hard (~1 hour)"
           DISPLAY " "
           DISPLAY "Enter new difficulty (2-6): " WITH NO ADVANCING
           ACCEPT WS-DIFFICULTY

           IF WS-DIFFICULTY < 2 OR WS-DIFFICULTY > 6 THEN
               DISPLAY "Invalid difficulty. Using default: 3"
               MOVE 3 TO WS-DIFFICULTY
           ELSE
               DISPLAY "Difficulty set to: " WS-DIFFICULTY
           END-IF

           DISPLAY " "
           DISPLAY "Press ENTER to continue..."
           ACCEPT WS-CONTINUE
           .

      *> ================================================================
      *> GET-CURRENT-TIMESTAMP - Get system timestamp                  *
      *> ================================================================
       GET-CURRENT-TIMESTAMP.
           MOVE FUNCTION CURRENT-DATE(1:20) TO WS-TIMESTAMP
           .

      *> ================================================================
      *> COUNT-BLOCKS - Count total blocks in the chain                *
      *> ================================================================
       COUNT-BLOCKS.
           CLOSE BLOCKCHAIN-FILE
           OPEN INPUT BLOCKCHAIN-FILE

           MOVE 0 TO WS-BLOCK-COUNT

           PERFORM UNTIL FILE-EOF
               READ BLOCKCHAIN-FILE
                   AT END
                       CONTINUE
                   NOT AT END
                       ADD 1 TO WS-BLOCK-COUNT
               END-READ
           END-PERFORM

           CLOSE BLOCKCHAIN-FILE
           OPEN EXTEND BLOCKCHAIN-FILE
           .

      *> ================================================================
      *> CLEANUP - Close files and clean up resources                  *
      *> ================================================================
       CLEANUP.
           CLOSE BLOCKCHAIN-FILE
           DISPLAY " "
           DISPLAY "Blockchain system shut down successfully."
           .

       END PROGRAM BLOCKCHAIN.
