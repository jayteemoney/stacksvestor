# 🪙 StacksVestor

A decentralized token vesting and airdrop manager built on the Stacks blockchain.

## 🎯 Overview

StacksVestor is a smart contract system that enables:
- Token vesting schedules with customizable unlock heights
- Secure beneficiary management
- Self-service token claiming
- Admin-controlled airdrop functionality

## 🏗️ Project Structure

```
stacksvestor/
├── contracts/           # Clarity smart contracts
│   └── stacksvestor.clar
├── tests/              # Contract unit tests
│   └── stacksvestor.test.ts
├── settings/           # Network configurations
└── Clarinet.toml       # Clarinet project configuration
```

## ✨ Features

- **Vesting Management**: Admins can add beneficiaries with specific vesting amounts and unlock heights
- **Token Claiming**: Beneficiaries can claim tokens once the unlock height is reached
- **Vesting Info**: Query vesting details for any beneficiary
- **Admin Controls**: Revoke vesting entries and manage airdrops
- **Security**: Only authorized admins can manage vesting schedules

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js 16+ (for frontend integration)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/stacksvestor.git
cd stacksvestor

# Check contract validity
clarinet check
```

### Running Tests

```bash
clarinet test
```

## 📝 Smart Contract Functions

### Write Functions

- `add-beneficiary`: Add a new vesting entry (admin only)
- `claim-tokens`: Claim vested tokens when unlocked
- `revoke-beneficiary`: Cancel a vesting entry (admin only)
- `airdrop-tokens`: Distribute tokens to multiple recipients

### Read-Only Functions

- `get-vesting-info`: Get vesting details for a beneficiary
- `get-admin`: Get the current admin address
- `is-beneficiary`: Check if an address is a beneficiary

## 🛠️ Tech Stack

- **Smart Contract**: Clarity 2.0
- **Development**: Clarinet SDK
- **Network**: Stacks Blockchain (Testnet)

## 📄 License

MIT

## 🤝 Contributing

This project was built for the Stacks Ascent $750 grant program.

---

Built with ❤️ on Stacks
