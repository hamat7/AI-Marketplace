# AI Model Marketplace Platform Smart Contract

A comprehensive blockchain-based marketplace for AI model distribution and monetization built on the Stacks blockchain. This smart contract enables AI researchers and developers to securely publish, license, and generate revenue from their machine learning models with automated licensing, royalty distribution, version control, and decentralized access management.

## Features

- **Model Publishing**: Secure registration of AI models with metadata and technical specifications
- **Automated Licensing**: Time-based licensing system with automatic expiration
- **Revenue Distribution**: Automated royalty payments to model creators with platform commission
- **Version Control**: Track model versions, file hashes, and updates
- **Access Management**: Decentralized license validation and access control
- **Analytics**: Comprehensive revenue tracking and usage statistics
- **Admin Controls**: Platform governance and emergency controls

## Architecture

### Core Components

1. **Model Registry**: Primary storage for model information and metadata
2. **License Registry**: Manages user licenses and access permissions
3. **Revenue Tracking**: Financial analytics and earnings distribution
4. **Metadata Storage**: Technical specifications and version control

### Data Structures

```clarity
;; Model Registry
{
  model-id: uint,
  creator: principal,
  title: string-ascii 64,
  description: string-ascii 256,
  license-fee: uint,
  license-duration: uint,
  is-active: bool,
  created-at: uint,
  total-sales: uint
}

;; License Registry
{
  model-id: uint,
  licensee: principal,
  expires-at: uint,
  purchased-at: uint,
  license-type: string-ascii 32,
  amount-paid: uint
}
```

## Usage

### For Model Publishers

#### 1. Publish a Model

```clarity
(contract-call? .ai-marketplace publish-model
  "GPT-4 Clone"                    ;; title
  "Advanced language model"        ;; description
  u1000000                         ;; license fee (1 STX)
  u1008                           ;; license duration (1 week)
  "v1.0.0"                        ;; version
  "abc123def456..."               ;; file hash
  u500000000                      ;; file size
  u9500                           ;; accuracy score (95%)
  "Trained on 100TB text data"    ;; training info
  "8GB GPU minimum"               ;; hardware requirements
  "PyTorch, TensorFlow"           ;; frameworks
)
```

#### 2. Update Model Information

```clarity
(contract-call? .ai-marketplace update-model-info
  u1                              ;; model-id
  "Updated Model Title"           ;; new title
  "Updated description"           ;; new description
  u2000000                        ;; new license fee
  u2016                          ;; new license duration
)
```

### For License Purchasers

#### 1. Purchase a License

```clarity
(contract-call? .ai-marketplace purchase-license
  u1                             ;; model-id
  "commercial"                   ;; license type
)
```

#### 2. Check License Validity

```clarity
(contract-call? .ai-marketplace check-license-validity
  u1                             ;; model-id
  'SP1ABC...                     ;; user principal
)
```

#### 3. Renew License

```clarity
(contract-call? .ai-marketplace renew-license
  u1                             ;; model-id
)
```

### Query Functions

#### Get Model Information

```clarity
(contract-call? .ai-marketplace get-model-info u1)
```

#### Get License Information

```clarity
(contract-call? .ai-marketplace get-license-info u1 'SP1ABC...)
```

#### Get Revenue Statistics

```clarity
(contract-call? .ai-marketplace get-revenue-stats u1)
```

## API Reference

### Public Functions

#### Model Management

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `publish-model` | Register a new AI model | title, description, license-fee, duration, version, file-hash, file-size, accuracy, training-info, hardware-reqs, frameworks | `(response uint uint)` |
| `update-model-info` | Update model basic information | model-id, new-title, new-description, new-license-fee, new-duration | `(response bool uint)` |
| `update-model-metadata` | Update technical metadata | model-id, version, file-hash, file-size, accuracy, training-info, hardware-reqs, frameworks | `(response bool uint)` |
| `deactivate-model` | Deactivate a model | model-id | `(response bool uint)` |
| `reactivate-model` | Reactivate a model | model-id | `(response bool uint)` |

#### License Management

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `purchase-license` | Buy access to a model | model-id, license-type | `(response bool uint)` |
| `renew-license` | Extend existing license | model-id | `(response bool uint)` |

#### Administrative Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `set-commission-rate` | Update platform commission | new-rate | `(response bool uint)` |
| `update-license-duration-limits` | Set min/max license periods | new-minimum, new-maximum | `(response bool uint)` |
| `pause-platform` | Emergency platform pause | none | `(response bool uint)` |
| `resume-platform` | Resume platform operations | none | `(response bool uint)` |
| `admin-deactivate-model` | Admin model deactivation | model-id | `(response bool uint)` |

### Read-Only Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get-model-info` | Retrieve model details | model-id | `(optional model-data)` |
| `get-license-info` | Get license details | model-id, user | `(optional license-data)` |
| `get-model-metadata` | Get technical metadata | model-id | `(optional metadata)` |
| `get-revenue-stats` | Get financial statistics | model-id | `(optional revenue-data)` |
| `check-license-validity` | Verify active license | model-id, user | `bool` |
| `get-next-model-id` | Get next available ID | none | `uint` |
| `get-platform-commission-rate` | Get current commission | none | `uint` |
| `calculate-platform-fee` | Calculate fee amount | amount | `uint` |
| `is-platform-operational` | Check platform status | none | `bool` |

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-UNAUTHORIZED-ACCESS` | Caller lacks required permissions |
| 101 | `ERR-MODEL-NOT-FOUND` | Specified model does not exist |
| 102 | `ERR-MODEL-ALREADY-EXISTS` | Model with ID already registered |
| 103 | `ERR-INSUFFICIENT-PAYMENT` | Payment amount below required fee |
| 104 | `ERR-LICENSE-EXPIRED` | User license has expired |
| 105 | `ERR-ACCESS-DENIED` | User not authorized for this action |
| 106 | `ERR-INVALID-PARAMETERS` | Invalid input parameters provided |
| 107 | `ERR-MODEL-UNAVAILABLE` | Model is deactivated or unavailable |
| 108 | `ERR-ACTIVE-LICENSE-EXISTS` | User already has active license |

## Configuration

### Platform Constants

- **Default Commission Rate**: 2.5% (250 basis points)
- **Minimum License Period**: ~1 day (144 blocks)
- **Maximum License Period**: ~1 year (52,560 blocks)
- **Maximum Commission Rate**: 10% (1000 basis points)
- **Maximum File Size**: 999,999,999,999 bytes
- **Maximum Accuracy Score**: 100% (10,000 basis points)

### String Limits

- **Model Title**: 64 characters
- **Model Description**: 256 characters
- **Version String**: 16 characters
- **File Hash**: 32-64 characters
- **License Type**: 32 characters
- **Training Info**: 128 characters
- **Hardware Requirements**: 64 characters
- **Framework Compatibility**: 128 characters

## Security

### Access Controls

1. **Model Ownership**: Only model creators can update their models
2. **Platform Administration**: Critical functions restricted to contract owner
3. **License Validation**: Automatic expiration and access control
4. **Payment Security**: Atomic STX transfers with automatic fee distribution

### Validation Mechanisms

- Input parameter validation for all public functions
- String length and format validation
- Numeric range validation
- Hash format verification
- Platform operational status checks