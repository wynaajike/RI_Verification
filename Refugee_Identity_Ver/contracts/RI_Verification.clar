;; Refugee Identity Verification System
;; Privacy-preserving identity management for displaced persons

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-identity-exists (err u102))
(define-constant err-identity-not-found (err u103))
(define-constant err-already-verified (err u104))
(define-constant err-invalid-hash (err u105))
(define-constant err-attestation-exists (err u106))

;; Define data variables
(define-data-var identity-counter uint u0)
(define-data-var required-attestations uint u3)

;; Define maps
(define-map identities
    principal
    {
        identity-hash: (buff 32), ;; Hash of personal data stored off-chain
        creation-block: uint,
        verification-status: (string-utf8 20),
        attestation-count: uint,
        last-update: uint
    }
)

(define-map identity-attestations
    { identity: principal, attester: principal }
    {
        attestation-type: (string-utf8 50),
        attestation-hash: (buff 32),
        timestamp: uint,
        valid: bool
    }
)

(define-map authorized-attesters
    principal
    {
        organization: (string-utf8 100),
        attester-type: (string-utf8 50), ;; "government", "ngo", "un-agency"
        active: bool
    }
)

(define-map access-grants
    { identity: principal, grantee: principal }
    {
        access-type: (string-utf8 50),
        expiry-block: uint
    }
)

;; Read-only functions
(define-read-only (get-identity (user principal))
    (map-get? identities user)
)

(define-read-only (get-attestation (identity principal) (attester principal))
    (map-get? identity-attestations { identity: identity, attester: attester })
)

(define-read-only (is-authorized-attester (attester principal))
    (match (map-get? authorized-attesters attester)
        attestation-info (get active attestation-info)
        false
    )
)

(define-read-only (has-access (identity principal) (grantee principal))
    (match (map-get? access-grants { identity: identity, grantee: grantee })
        grant (< stacks-block-height (get expiry-block grant))
        false
    )
)

;; Public functions
(define-public (register-identity (identity-hash (buff 32)))
    (begin
        (asserts! (is-none (get-identity tx-sender)) err-identity-exists)
        (map-set identities tx-sender {
            identity-hash: identity-hash,
            creation-block: stacks-block-height,
            verification-status: u"pending",
            attestation-count: u0,
            last-update: stacks-block-height
        })
        (var-set identity-counter (+ (var-get identity-counter) u1))
        (ok true)
    )
)

(define-public (add-authorized-attester 
    (attester principal)
    (organization (string-utf8 100))
    (attester-type (string-utf8 50)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-attesters attester {
            organization: organization,
            attester-type: attester-type,
            active: true
        })
        (ok true)
    )
)

(define-public (submit-attestation 
    (identity principal)
    (attestation-type (string-utf8 50))
    (attestation-hash (buff 32)))
    (let
        (
            (identity-info (unwrap! (get-identity identity) err-identity-not-found))
            (existing-attestation (get-attestation identity tx-sender))
        )
        (asserts! (is-authorized-attester tx-sender) err-not-authorized)
        (asserts! (is-none existing-attestation) err-attestation-exists)
        
        (map-set identity-attestations 
            { identity: identity, attester: tx-sender }
            {
                attestation-type: attestation-type,
                attestation-hash: attestation-hash,
                timestamp: stacks-block-height,
                valid: true
            }
        )
        
        (let
            (
                (new-count (+ (get attestation-count identity-info) u1))
            )
            (map-set identities identity 
                (merge identity-info { 
                    attestation-count: new-count,
                    verification-status: (if (>= new-count (var-get required-attestations))
                                           u"verified"
                                           u"pending"),
                    last-update: stacks-block-height
                })
            )
        )
        (ok true)
    )
)

(define-public (grant-access 
    (grantee principal)
    (access-type (string-utf8 50))
    (duration-blocks uint))
    (let
        (
            (identity-info (unwrap! (get-identity tx-sender) err-identity-not-found))
        )
        (asserts! (is-eq (get verification-status identity-info) u"verified") err-not-authorized)
        
        (map-set access-grants
            { identity: tx-sender, grantee: grantee }
            {
                access-type: access-type,
                expiry-block: (+ stacks-block-height duration-blocks)
            }
        )
        (ok true)
    )
)

(define-public (revoke-access (grantee principal))
    (begin
        (asserts! (is-some (get-identity tx-sender)) err-identity-not-found)
        (map-delete access-grants { identity: tx-sender, grantee: grantee })
        (ok true)
    )
)