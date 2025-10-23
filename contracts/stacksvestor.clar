;; StacksVestor - Token Vesting & Airdrop Manager
;;
;; A smart contract for managing token vesting schedules on the Stacks blockchain.
;; This contract allows an admin to create vesting schedules for beneficiaries,
;; who can then claim their tokens after a specified unlock height.

;; ==============================================================================
;; CONSTANTS
;; ==============================================================================

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-TOKENS-LOCKED (err u103))
(define-constant ERR-ALREADY-CLAIMED (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-INVALID-HEIGHT (err u106))

;; Contract owner/deployer
(define-constant CONTRACT-OWNER tx-sender)

;; ==============================================================================
;; DATA VARIABLES
;; ==============================================================================

;; The admin who can manage vesting schedules
;; Initially set to the contract deployer
(define-data-var admin principal CONTRACT-OWNER)

;; Total number of beneficiaries added
(define-data-var total-beneficiaries uint u0)

;; Total amount of tokens locked in vesting
(define-data-var total-vesting-amount uint u0)

;; ==============================================================================
;; DATA MAPS
;; ==============================================================================

;; Main vesting data structure
;; Maps a beneficiary's principal to their vesting details
(define-map vestings
  { recipient: principal }
  {
    amount: uint,           ;; Total amount of tokens to be vested
    claimed: bool,          ;; Whether the tokens have been claimed
    unlock-height: uint,    ;; Block height when tokens become claimable
    created-at: uint        ;; Block height when the vesting was created
  }
)

;; Track all beneficiaries for enumeration
;; This allows us to iterate through all beneficiaries if needed
(define-map beneficiary-index
  { index: uint }
  { recipient: principal }
)

;; Reverse lookup for beneficiary indices
(define-map recipient-to-index
  { recipient: principal }
  { index: uint }
)

;; ==============================================================================
;; PHASE 1 COMPLETE: Basic contract structure with data variables and maps
;; Next Phase: Core vesting functions (add-beneficiary, claim-tokens)
;; ==============================================================================
