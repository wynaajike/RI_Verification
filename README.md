# 🛂 Refugee Identity Verification System – Smart Contract Overview

This Clarity smart contract provides a **decentralized and privacy-preserving identity verification system** for refugees and displaced persons. It supports **off-chain identity hashing**, **attestation workflows by trusted organizations**, and **controlled access grants** to third parties (e.g., agencies, embassies, NGOs).

---

## 🎯 Purpose

Designed for real-world humanitarian scenarios, this system helps individuals:

* **Prove their identity** without exposing sensitive data.
* **Receive attestations** from authorized verifiers.
* **Control who can access** their identity verification status.

---

## 🔐 Identity Structure

Each identity is anchored on-chain by a **32-byte hash** representing off-chain data like:

* Biometric data
* Documents (passport, visa, ID)
* Proof of origin or displacement

Stored in the `identities` map.

### 🧾 Identity Fields:

```clojure
{
  identity-hash: buff-32,
  creation-block: uint,
  verification-status: "pending" | "verified",
  attestation-count: uint,
  last-update: uint
}
```

---

## 🔏 Attestation Model

### 👥 Authorized Attesters

* Only attesters added by the contract owner can verify identities.
* Must belong to a trusted group: `"government"`, `"ngo"`, `"un-agency"`.

Stored in the `authorized-attesters` map:

```clojure
{
  organization, attester-type, active
}
```

### 🖋 Identity Attestations

* Each attester can attest to an identity once.
* Must include a 32-byte hash of the attestation data.
* Stored in `identity-attestations` with timestamp and validity.

If the number of valid attestations ≥ `required-attestations` (default 3), status becomes `"verified"`.

---

## 🧠 Functional Summary

### 👤 Identity Owner Functions

#### `register-identity(identity-hash)`

* Registers a new identity for the caller.
* Only one identity per principal.
* Initializes status as `"pending"`.

#### `grant-access(grantee, access-type, duration-blocks)`

* Grants a third-party view access for a duration (in blocks).
* Only possible if identity is `"verified"`.

#### `revoke-access(grantee)`

* Revokes access from a previously granted principal.

---

### 🛡️ Contract Owner Function

#### `add-authorized-attester(attester, org, type)`

* Allows the contract owner to add authorized attesters.
* `active: true` by default.

---

### ✅ Attester Function

#### `submit-attestation(identity, attestation-type, attestation-hash)`

* Attesters can submit attestations to a refugee’s identity.
* Hash must be unique per attester/identity.
* Increments count and possibly changes status to `"verified"`.

---

### 📖 Read-only Helpers

* `get-identity(principal)`
* `get-attestation(identity, attester)`
* `is-authorized-attester(attester)`
* `has-access(identity, grantee)`

---

## ✅ Security & Privacy Highlights

* ⚠️ **No identity data on-chain**, only hashes.
* ✅ **Users control access** to their identity status.
* 🧾 **Attestation hashes** can reference encrypted documents or proofs stored off-chain (e.g., IPFS, Arweave).
* ⛔ Prevents unauthorized attestation or identity overwrite.

---

## 🧱 Potential Improvements

* **Revoke or invalidate attestations** if needed.
* **Multiple identity revisions** per user (if identity changes).
* **Support anonymous selective disclosures** (e.g., age/proof of country without full ID).
* **Cross-chain access bridging** to share identity proofs with other blockchains or apps.
This contract is a strong foundation for digital identity inclusion among displaced populations.
