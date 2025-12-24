# Software Requirements Specification (SRS)
**Project:** BlockPay - Real-Time Digital Wallet Simulator
**Version:** 2.0 (Production Simulation)

## 1. Introduction
### 1.1 Purpose
The purpose of this document is to define the requirements for **BlockPay**, a **real-time simulated digital wallet system**. Unlike dummy applications, BlockPay implements **production-grade payment logic**, authentic transaction states, and value settlement workflows using a **Virtual Currency (VC)**. It serves as a comprehensive academic demonstration of fintech architecture without the regulatory constraints of real-money handling.

### 1.2 Scope
- **System Type**: Real-Time Transaction Simulator.
- **Core Engine**: Deterministic State Machine for transaction lifecycle (Initiated -> Pending -> Confirming -> Settled).
- **Ledger**: Immutable sequential log (Blockchain-inspired) for audit trails.
- **Currency**: Internally managed Virtual Currency (VC) with 1:1 consistent value logic.

## 2. Functional Requirements
### 2.1 User Authentication & Security
- **FR-01**: System shall enforce secure session management logic.
- **FR-02**: Every user identity shall be cryptographically linked to a unique Wallet Address.

### 2.2 Wallet & Ledger Logic
- **FR-03**: System shall maintain an atomic ledger for all credit/debit operations.
- **FR-04**: Balance updates must occur in real-time following the "Double-Entry Bookkeeping" principle (Debit Sender, Credit Receiver).
- **FR-05**: System shall prevent double-spending attacks via state-locking during the "Processing" phase.

### 2.3 Real-Time Transaction Processing
- **FR-06**: The application must simulate the full lifecycle of a payment:
    1.  **Authorization**: Validating keys and balance.
    2.  **Broadcasting**: Simulating network propagation.
    3.  **Settlement**: Finalizing the ledger state.
- **FR-07**: Users must receive real-time feedback (toasts, status screens) reflecting the backend state.
- **FR-08**: Failed transactions (e.g., insufficient funds) must generate authentic error logs and user prompts.

### 2.4 History & Auditability
- **FR-09**: All transactions are immutable once "Settled".
- **FR-10**: The history log serves as the "Source of Truth" for all account balances.

## 3. Non-Functional Requirements
### 3.1 Reliability
- **NFR-01**: Transaction states (Success/Failure) must be deterministic.
- **NFR-02**: The system shall handle "network delays" utilizing asynchronous processing queues (simulated).

### 3.2 User Experience (UX)
- **NFR-03**: The interface must mimic industry-standard apps (e.g., GPay, PhonePe) in terms of flow and responsiveness.
- **NFR-04**: Latency should be artificially introduced during critical operations (signing, mining) to emulate security protocols.

## 4. System Architecture
### 4.1 Technology Stack
- **Frontend**: Flutter (Production-grade UI components)
- **Logic Layer**: Dart (State Management via Provider)
- **Data Layer**: Local Encrypted Storage / In-Memory Ledger

### 4.2 Data Flow
1.  **Initiation**: User authenticates and signs a transaction request.
2.  **Processing**: The Engine accepts the request, locks funds, and validates constraints.
3.  **Settlement**: Upon validation, the Engine appends the Block to the Chain.
4.  **Notification**: The UI receives the success signal and unlocks the UI.

## 5. Conclusion
BlockPay successfully demonstrates **fintech engineering principles** by simulating the **entire vertical** of a payment system—from UI prompts to ledger settlement—providing a safe yet technically rigorous environment for analysis.
