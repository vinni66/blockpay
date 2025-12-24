# System Diagrams

## 1. Use Case Diagram

```mermaid
usecaseDiagram
    actor User as "Wallet User"
    actor Admin as "System Admin"
    participant App as "Flutter App"
    participant BC as "Blockchain Ledger"

    User --> (Register/Login)
    User --> (View Balance)
    User --> (Send Money)
    User --> (Scan QR Code)
    User --> (View History)

    (Send Money) ..> (Validate Balance) : include
    (Send Money) --> BC : "Record Transaction"
    
    Admin --> (Monitor Network)
    Admin --> (Manage Users)
```

## 2. Entity Relationship Diagram (ERD)

Although this is a blockchain system, we represent the logical data structure below.

```mermaid
erDiagram
    USER ||--o{ WALLET : owns
    WALLET ||--o{ TRANSACTION : initiates
    BLOCKCHAIN ||--|{ BLOCK : contains
    BLOCK ||--|{ TRANSACTION : records

    USER {
        string email PK
        string password_hash
        string name
        datetime created_at
    }

    WALLET {
        string wallet_address PK
        string private_key
        float balance
        string user_email FK
    }

    TRANSACTION {
        string txn_id PK
        string sender_address FK
        string receiver_address FK
        float amount
        datetime timestamp
        string status
    }

    BLOCK {
        int index PK
        string hash
        string previous_hash
        int timestamp
        string data_hash
    }
```

## 3. Data Flow Diagram (Level 0)

```mermaid
graph LR
    U[User] -- "Initiates Payment" --> A[Mobile App]
    A -- "Validates Request" --> W[Wallet Manager]
    W -- "Checks Balance" --> DB[(Local Storage)]
    W -- "Creates Block" --> B[Blockchain Service]
    B -- "Returns Txn ID" --> W
    W -- "Success Notification" --> A
    A -- "Display Receipt" --> U
```
