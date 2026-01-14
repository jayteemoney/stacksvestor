;; StacksVestor - Token Vesting & Airdrop Manager

(use-trait sip010-token .sip-010-trait.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-TOKENS-LOCKED (err u103))
(define-constant ERR-ALREADY-CLAIMED (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-INVALID-HEIGHT (err u106))
(define-constant ERR-INVALID-RECIPIENT (err u107))
(define-constant ERR-TOKEN-TRANSFER-FAILED (err u108))
(define-constant ERR-TOKEN-NOT-SET (err u109))
(define-constant ERR-INSUFFICIENT-BALANCE (err u110))

(define-constant CONTRACT-OWNER tx-sender)

(define-data-var admin principal CONTRACT-OWNER)
(define-data-var total-beneficiaries uint u0)
(define-data-var total-vesting-amount uint u0)
(define-data-var token-contract (optional principal) none)

(define-map vestings
  { recipient: principal }
  {
    amount: uint,
    claimed: bool,
    unlock-height: uint,
    created-at: uint
  }
)

(define-map beneficiary-index
  { index: uint }
  { recipient: principal }
)

(define-map recipient-to-index
  { recipient: principal }
  { index: uint }
)

(define-private (is-admin (caller principal))
  (is-eq caller (var-get admin))
)

(define-private (validate-principal (principal-to-check principal))
  (not (is-eq principal-to-check (as-contract tx-sender)))
)

(define-private (validate-amount (amount uint))
  (> amount u0)
)

(define-private (validate-height (height uint))
  (> height block-height)
)

(define-public (add-beneficiary (token <sip010-token>) (recipient principal) (amount uint) (unlock-height uint))
  (let
    (
      (current-height block-height)
      (current-total (var-get total-beneficiaries))
      (token-principal (contract-of token))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (some token-principal) (var-get token-contract)) ERR-TOKEN-NOT-SET)
    (asserts! (validate-principal recipient) ERR-INVALID-RECIPIENT)
    (asserts! (validate-amount amount) ERR-INVALID-AMOUNT)
    (asserts! (validate-height unlock-height) ERR-INVALID-HEIGHT)
    (asserts! (is-none (map-get? vestings { recipient: recipient })) ERR-ALREADY-EXISTS)

    (match (contract-call? token transfer amount tx-sender (as-contract tx-sender) none)
      success-val (begin
        (map-set vestings
          { recipient: recipient }
          {
            amount: amount,
            claimed: false,
            unlock-height: unlock-height,
            created-at: current-height
          }
        )
        (map-set beneficiary-index
          { index: current-total }
          { recipient: recipient }
        )
        (map-set recipient-to-index
          { recipient: recipient }
          { index: current-total }
        )
        (var-set total-beneficiaries (+ current-total u1))
        (var-set total-vesting-amount (+ (var-get total-vesting-amount) amount))
        (ok true)
      )
      error-val ERR-TOKEN-TRANSFER-FAILED
    )
  )
)

(define-public (claim-tokens (token <sip010-token>))
  (let
    (
      (caller tx-sender)
      (vesting-data (unwrap! (map-get? vestings { recipient: caller }) ERR-NOT-FOUND))
      (amount (get amount vesting-data))
      (claimed (get claimed vesting-data))
      (unlock-height (get unlock-height vesting-data))
      (current-height block-height)
      (token-principal (contract-of token))
    )
    (asserts! (is-eq (some token-principal) (var-get token-contract)) ERR-TOKEN-NOT-SET)
    (asserts! (not claimed) ERR-ALREADY-CLAIMED)
    (asserts! (>= current-height unlock-height) ERR-TOKENS-LOCKED)

    (match (as-contract (contract-call? token transfer amount tx-sender caller none))
      success-val (begin
        (map-set vestings
          { recipient: caller }
          (merge vesting-data { claimed: true })
        )
        (var-set total-vesting-amount (- (var-get total-vesting-amount) amount))
        (ok amount)
      )
      error-val ERR-TOKEN-TRANSFER-FAILED
    )
  )
)

(define-read-only (get-vesting-info (recipient principal))
  (map-get? vestings { recipient: recipient })
)

(define-read-only (get-admin)
  (var-get admin)
)

(define-read-only (is-beneficiary (recipient principal))
  (is-some (map-get? vestings { recipient: recipient }))
)

(define-read-only (get-total-beneficiaries)
  (var-get total-beneficiaries)
)

(define-read-only (get-total-vesting-amount)
  (var-get total-vesting-amount)
)

(define-read-only (get-beneficiary-at-index (index uint))
  (map-get? beneficiary-index { index: index })
)

(define-read-only (get-token-contract)
  (var-get token-contract)
)

(define-public (revoke-beneficiary (token <sip010-token>) (recipient principal))
  (let
    (
      (vesting-data (unwrap! (map-get? vestings { recipient: recipient }) ERR-NOT-FOUND))
      (amount (get amount vesting-data))
      (claimed (get claimed vesting-data))
      (token-principal (contract-of token))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-principal recipient) ERR-INVALID-RECIPIENT)
    (asserts! (is-eq (some token-principal) (var-get token-contract)) ERR-TOKEN-NOT-SET)
    (asserts! (not claimed) ERR-ALREADY-CLAIMED)

    (match (as-contract (contract-call? token transfer amount tx-sender (var-get admin) none))
      success-val (begin
        (map-delete vestings { recipient: recipient })
        (var-set total-vesting-amount (- (var-get total-vesting-amount) amount))
        (ok amount)
      )
      error-val ERR-TOKEN-TRANSFER-FAILED
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-principal new-admin) ERR-INVALID-RECIPIENT)
    (asserts! (not (is-eq new-admin (var-get admin))) ERR-ALREADY-EXISTS)
    (var-set admin new-admin)
    (ok true)
  )
)

(define-public (set-token-contract (token <sip010-token>))
  (let
    (
      (token-principal (contract-of token))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (var-get token-contract)) ERR-ALREADY-EXISTS)
    (var-set token-contract (some token-principal))
    (ok true)
  )
)

;; USE WITH CAUTION: This can withdraw vested tokens
(define-public (emergency-withdraw (token <sip010-token>) (amount uint) (recipient principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-principal recipient) ERR-INVALID-RECIPIENT)
    (asserts! (validate-amount amount) ERR-INVALID-AMOUNT)

    (match (as-contract (contract-call? token transfer amount tx-sender recipient none))
      success-val (ok amount)
      error-val ERR-TOKEN-TRANSFER-FAILED
    )
  )
)

(define-private (process-airdrop-entry-with-transfer
  (entry { recipient: principal, amount: uint, unlock-height: uint })
  (context { token: principal, admin: principal, success-count: uint }))
  (let
    (
      (recipient (get recipient entry))
      (amount (get amount entry))
      (unlock-height (get unlock-height entry))
      (current-height block-height)
      (current-total (var-get total-beneficiaries))
      (current-success (get success-count context))
    )
    (if (not (validate-principal recipient))
      context
      (if (not (validate-amount amount))
        context
        (if (not (validate-height unlock-height))
          context
          (if (is-some (map-get? vestings { recipient: recipient }))
            context
          (begin
            (map-set vestings
              { recipient: recipient }
              {
                amount: amount,
                claimed: false,
                unlock-height: unlock-height,
                created-at: current-height
              }
            )
            (map-set beneficiary-index
              { index: current-total }
              { recipient: recipient }
            )
            (map-set recipient-to-index
              { recipient: recipient }
              { index: current-total }
            )
            (var-set total-beneficiaries (+ current-total u1))
            (var-set total-vesting-amount (+ (var-get total-vesting-amount) amount))
            (merge context { success-count: (+ current-success u1) })
          )
          )
        )
      )
    )
  )
)

(define-public (airdrop-tokens (token <sip010-token>) (recipients (list 200 { recipient: principal, amount: uint, unlock-height: uint })))
  (let
    (
      (token-principal (contract-of token))
      (total-amount (fold sum-amounts recipients u0))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (some token-principal) (var-get token-contract)) ERR-TOKEN-NOT-SET)

    (match (contract-call? token transfer total-amount tx-sender (as-contract tx-sender) none)
      success-val (begin
        (let
          (
            (result (fold process-airdrop-entry-with-transfer
                         recipients
                         { token: token-principal, admin: tx-sender, success-count: u0 }))
          )
          (ok (get success-count result))
        )
      )
      error-val ERR-TOKEN-TRANSFER-FAILED
    )
  )
)

(define-private (get-amount (entry { recipient: principal, amount: uint, unlock-height: uint }))
  (get amount entry)
)

(define-private (sum-amounts (entry { recipient: principal, amount: uint, unlock-height: uint }) (acc uint))
  (+ acc (get amount entry))
)