# Blueprint Bank

## Overview
The **Blueprint Bank** is a flexible, generic asset deposit and withdrawal system implemented in **Sui Move**. It allows users to deposit any type of coin and receive a unique, non-transferable receipt NFT that can be used to withdraw the exact deposited amount.

## Features
- Deposit any coin type (**SUI, USDC, custom tokens, etc.**)
- Receive a unique **receipt NFT** for each deposit
- Withdraw deposited funds using the original receipt
- Supports **multiple simultaneous coin type deposits**
- **Event tracking** for deposits and withdrawals
- Secure and non-transferable NFT-based deposit receipts

## Prerequisites
Before using or contributing to this project, ensure you have the following installed:

- **Sui CLI**
- **Rust**
- **Sui Move Developer Environment**

## Project Structure
```
BlueprintBank/
├── sources/
│   ├── bank.move         # Main bank module implementation
│   ├── bank_tests.move   # Unit tests for the bank module
│   ├── fake_coin.move    # Test token
└── Move.toml             # Move package configuration
```

## Installation

### Clone the repository:
```bash
git clone https://github.com/AureliusEth/BlueprintBank.git
cd BlueprintBank
```

### Install dependencies:
```bash
sui move build
```

## Running Tests
To execute the test suite, run:
```bash
cd sources
sui move test
```

## Key Concepts
### Deposit Process
1. Deposit any coin type into the shared bank.
2. Receive a unique **receipt NFT**.
3. The receipt tracks:
   - **Depositor address**
   - **Deposit amount**
   - **Unique deposit number**

### Withdrawal Process
1. Return the original receipt.
2. Receive the exact deposited amount.
3. The receipt is **burned** after withdrawal.

## Module Implementation
The **bank.move** module is responsible for handling deposits and withdrawals securely. It includes:
- **AssetBank struct**: Stores coins tracks total deposits and active receipts.
- **Receipt struct**: Represents the NFT issued for each deposit.
- **Deposit method**: Allows users to deposit any coin type and receive an NFT receipt.
- **Withdraw method**: Allows users to return the receipt and reclaim their funds.
- **Event emissions**: Tracks all deposits and withdrawals in the system.


## Security Notes
- **Receipts are non-transferable**.
- **Only the original depositor can withdraw**.
- **Zero-value deposits are rejected**.
- **Each receipt can be used only once**.
- **Strict validation ensures only valid withdrawals occur**.

## Unit Tests
The `bank_tests.move` module includes:
- Initialization tests
- Deposit and withdrawal tests
- Multi-coin deposit tests
- Edge case handling

