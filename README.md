# 🌾 CoopChain - Decentralized Farmer Cooperatives

A blockchain-based smart contract system for managing farmer cooperatives with transparent voting and fair profit distribution.

## 🚀 Features

- 👥 **Membership Management**: Join cooperatives with initial contributions
- 🗳️ **Democratic Voting**: Weighted voting based on member contributions  
- 💰 **Profit Distribution**: Fair distribution based on member shares
- 📊 **Proposal System**: Create and vote on funding proposals
- 🏦 **Treasury Management**: Secure fund management and tracking
- 🔒 **Emergency Controls**: Owner-controlled emergency functions

## 🏗️ Contract Architecture

### Core Functions

#### Member Management
- `join-cooperative(amount)` - Join with initial contribution 💵
- `contribute-funds(amount)` - Add additional funds to increase shares 📈
- `leave-cooperative()` - Exit with proportional refund 🚪

#### Governance
- `create-proposal(title, description, amount, recipient, type)` - Create funding proposal 📝
- `vote-on-proposal(proposal-id, vote-yes)` - Vote on proposals ✅
- `execute-proposal(proposal-id)` - Execute approved proposals ⚡

#### Financial Operations  
- `add-revenue(amount)` - Add cooperative revenue 💹
- `distribute-profits()` - Distribute profits to members 🎁
- `emergency-withdraw(amount)` - Owner emergency withdrawal 🚨

### Read-Only Functions

- `get-member-info(principal)` - Get member details 👤
- `get-proposal(proposal-id)` - Get proposal information 📋
- `get-treasury-balance()` - Check treasury balance 💳
- `is-member(principal)` - Check membership status ✅
- `calculate-voting-power(principal)` - Get member voting power ⚖️

## 🛠️ Usage Instructions

### 1. Joining the Cooperative
```clarity
(contract-call? .CoopChain join-cooperative u1000000)
```

### 2. Creating a Proposal
```clarity
(contract-call? .CoopChain create-proposal 
  "Equipment Purchase" 
  "Buy new farming equipment for increased productivity" 
  u5000000 
  'ST1FARMER123
  "equipment")
```

### 3. Voting on Proposals
```clarity
(contract-call? .CoopChain vote-on-proposal u1 true)
```

### 4. Contributing Additional Funds
```clarity
(contract-call? .CoopChain contribute-funds u500000)
```

### 5. Adding Revenue
```clarity
(contract-call? .CoopChain add-revenue u2000000)
```

## 🔧 Setup & Testing

### Prerequisites
- Clarinet installed
- Stacks CLI tools

### Installation
1. Clone the repository
2. Navigate to project directory
3. Run `clarinet check` to verify contracts
4. Use `clarinet console` for testing

### Testing Commands
```bash
clarinet check
clarinet test
clarinet console
```

## 🌟 Key Benefits

- 🎯 **Transparency**: All transactions and votes on blockchain
- ⚖️ **Fair Voting**: Share-weighted democratic decision making  
- 💡 **Flexibility**: Support for various proposal types
- 🔐 **Security**: Built-in safeguards and emergency controls
- 📊 **Traceability**: Complete audit trail of all activities

## 🎭 Error Codes

| Code | Description |
|------|-------------|
| 100  | Not Authorized |
| 101  | Already Member |
| 102  | Not Member |
| 103  | Insufficient Funds |
| 104  | Proposal Not Found |
| 105  | Already Voted |
| 106  | Voting Ended |
| 107  | Invalid Amount |
| 108  | Withdrawal Failed |

## 🤝 Contributing

Feel free to submit issues and enhancement requests! 

## 📜 License

This project is open source and available under the MIT License.

---

Built with ❤️ for farmers by farmers 🚜
