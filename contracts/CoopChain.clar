(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-MEMBER (err u101))
(define-constant ERR-NOT-MEMBER (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-VOTING-ENDED (err u106))
(define-constant ERR-INVALID-AMOUNT (err u107))
(define-constant ERR-WITHDRAWAL-FAILED (err u108))

(define-data-var next-proposal-id uint u1)
(define-data-var total-members uint u0)
(define-data-var treasury-balance uint u0)

(define-map members principal 
  {
    joined-at: uint,
    contribution: uint,
    shares: uint,
    active: bool
  })

(define-map proposals uint
  {
    title: (string-ascii 50),
    description: (string-ascii 200),
    amount: uint,
    recipient: principal,
    proposer: principal,
    created-at: uint,
    voting-end: uint,
    yes-votes: uint,
    no-votes: uint,
    executed: bool,
    proposal-type: (string-ascii 20)
  })

(define-map votes {proposal-id: uint, voter: principal} bool)

(define-map profit-shares principal uint)

(define-public (join-cooperative (initial-contribution uint))
  (begin
    (asserts! (> initial-contribution u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? members tx-sender)) ERR-ALREADY-MEMBER)
    (try! (stx-transfer? initial-contribution tx-sender (as-contract tx-sender)))
    (map-set members tx-sender {
      joined-at: stacks-block-height,
      contribution: initial-contribution,
      shares: initial-contribution,
      active: true
    })
    (var-set total-members (+ (var-get total-members) u1))
    (var-set treasury-balance (+ (var-get treasury-balance) initial-contribution))
    (ok true)))

(define-public (contribute-funds (amount uint))
  (let ((member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER)))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (get active member-data) ERR-NOT-AUTHORIZED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set members tx-sender (merge member-data {
      contribution: (+ (get contribution member-data) amount),
      shares: (+ (get shares member-data) amount)
    }))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))
    (ok true)))

(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 200)) 
                               (amount uint) (recipient principal) (proposal-type (string-ascii 20)))
  (let ((proposal-id (var-get next-proposal-id))
        (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER)))
    (asserts! (get active member-data) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (map-set proposals proposal-id {
      title: title,
      description: description,
      amount: amount,
      recipient: recipient,
      proposer: tx-sender,
      created-at: stacks-block-height,
      voting-end: (+ stacks-block-height u144),
      yes-votes: u0,
      no-votes: u0,
      executed: false,
      proposal-type: proposal-type
    })
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)))

(define-public (vote-on-proposal (proposal-id uint) (vote-yes bool))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
        (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER)))
    (asserts! (get active member-data) ERR-NOT-AUTHORIZED)
    (asserts! (<= stacks-block-height (get voting-end proposal)) ERR-VOTING-ENDED)
    (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
    (map-set votes {proposal-id: proposal-id, voter: tx-sender} vote-yes)
    (if vote-yes
      (map-set proposals proposal-id (merge proposal {
        yes-votes: (+ (get yes-votes proposal) (get shares member-data))
      }))
      (map-set proposals proposal-id (merge proposal {
        no-votes: (+ (get no-votes proposal) (get shares member-data))
      })))
    (ok true)))

(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
    (asserts! (not (get executed proposal)) ERR-NOT-AUTHORIZED)
    (asserts! (> stacks-block-height (get voting-end proposal)) ERR-VOTING-ENDED)
    (asserts! (> (get yes-votes proposal) (get no-votes proposal)) ERR-NOT-AUTHORIZED)
    (asserts! (>= (var-get treasury-balance) (get amount proposal)) ERR-INSUFFICIENT-FUNDS)
    (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
    (map-set proposals proposal-id (merge proposal {executed: true}))
    (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
    (ok true)))

(define-public (distribute-profits)
  (let ((total-shares (fold + (map get-member-shares (get-all-members)) u0)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> total-shares u0) ERR-INVALID-AMOUNT)
    (ok (map distribute-to-member (get-all-members)))))

(define-public (leave-cooperative)
  (let ((member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
        (refund-amount (/ (* (get shares member-data) (var-get treasury-balance)) 
                         (fold + (map get-member-shares (get-all-members)) u0))))
    (asserts! (get active member-data) ERR-NOT-AUTHORIZED)
    (try! (as-contract (stx-transfer? refund-amount tx-sender tx-sender)))
    (map-set members tx-sender (merge member-data {active: false}))
    (var-set total-members (- (var-get total-members) u1))
    (var-set treasury-balance (- (var-get treasury-balance) refund-amount))
    (ok refund-amount)))

(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= (var-get treasury-balance) amount) ERR-INSUFFICIENT-FUNDS)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))
    (var-set treasury-balance (- (var-get treasury-balance) amount))
    (ok true)))

(define-read-only (get-member-info (member principal))
  (map-get? members member))

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id))

(define-read-only (get-treasury-balance)
  (var-get treasury-balance))

(define-read-only (get-total-members)
  (var-get total-members))

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? votes {proposal-id: proposal-id, voter: voter})))

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter}))

(define-read-only (is-member (address principal))
  (match (map-get? members address)
    member-data (get active member-data)
    false))

(define-read-only (get-member-shares (member principal))
  (default-to u0 (get shares (map-get? members member))))

(define-read-only (get-profit-share (member principal))
  (default-to u0 (map-get? profit-shares member)))

(define-private (get-all-members)
  (list tx-sender))

(define-private (distribute-to-member (member principal))
  (let ((member-data (unwrap-panic (map-get? members member)))
        (total-shares (fold + (map get-member-shares (get-all-members)) u0))
        (profit-amount (/ (* (get shares member-data) (var-get treasury-balance)) total-shares)))
    (map-set profit-shares member profit-amount)
    true))

(define-public (add-revenue (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))
    (ok true)))

(define-public (update-member-status (member principal) (active bool))
  (let ((member-data (unwrap! (map-get? members member) ERR-NOT-MEMBER)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set members member (merge member-data {active: active}))
    (ok true)))

(define-read-only (calculate-voting-power (member principal))
  (let ((member-data (map-get? members member)))
    (match member-data
      data (if (get active data) (get shares data) u0)
      u0)))

(define-read-only (get-proposal-status (proposal-id uint))
  (let ((proposal (map-get? proposals proposal-id)))
    (match proposal
      prop (if (> stacks-block-height (get voting-end prop))
             (if (> (get yes-votes prop) (get no-votes prop)) "passed" "rejected")
             "active")
      "not-found")))
