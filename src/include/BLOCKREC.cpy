      *> BLOCKREC.cpy - Block Record Structure
      *> Defines the structure of a blockchain block
      *> Total Record Size: ~432 bytes
       01  BLOCK-STRUCTURE.
           05  BLOCK-INDEX          PIC 9(8) COMP.
           05  BLOCK-TIMESTAMP      PIC X(20).
           05  BLOCK-PREV-HASH      PIC X(64).
           05  BLOCK-DATA           PIC X(256).
           05  BLOCK-NONCE          PIC 9(18) COMP.
           05  BLOCK-CURRENT-HASH   PIC X(64).
