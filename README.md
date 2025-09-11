# 🎨 NFTs - Non-Fungible Tokens

A Foundry-based Solidity project demonstrating two different NFT implementations with unique features and on-chain metadata.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Smart Contracts](#smart-contracts)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This project showcases two distinct NFT implementations built with Solidity and Foundry:

1. **BasicNft** - A simple ERC721 implementation with custom token URIs
2. **MoodNft** - An interactive NFT that can change its mood (appearance) based on owner actions

Both contracts demonstrate different approaches to NFT metadata handling and user interaction patterns.

## ✨ Features

### BasicNft Contract
- ✅ ERC721 compliant
- ✅ Custom token URI mapping
- ✅ Simple minting functionality
- ✅ Input validation for empty URIs
- ✅ Automatic token counter management

### MoodNft Contract
- ✅ ERC721 compliant with Ownable access control
- ✅ **100% on-chain metadata** (no external dependencies)
- ✅ **Interactive mood flipping** - owners can change NFT appearance
- ✅ **Paid minting** with configurable pricing
- ✅ **Base64 encoded SVG images** stored on-chain
- ✅ **Dynamic JSON metadata** generation
- ✅ **Owner withdrawal** functionality
- ✅ **Comprehensive access control**

## 📁 Project Structure

```
NFTs-NonFungibleTokens/
├── src/
│   ├── BasicNft.sol          # Simple NFT implementation
│   └── MoodNft.sol           # Interactive mood-based NFT
├── test/
│   ├── BasicNftTest.t.sol    # BasicNft test suite
│   └── MoodNftTest.t.sol     # MoodNft test suite
├── script/
│   ├── DeployBasicNft.s.sol  # BasicNft deployment script
│   ├── DeployMoodNft.s.sol   # MoodNft deployment script
│   └── Interactions.s.sol    # Interaction examples
├── img/
│   ├── Happy.svg             # Happy mood SVG image
│   └── Sad.svg               # Sad mood SVG image
├── lib/                      # Dependencies (OpenZeppelin, Forge-std)
└── foundry.toml             # Foundry configuration
```

## 🔧 Smart Contracts

### BasicNft.sol
A straightforward ERC721 implementation that allows users to mint NFTs with custom metadata URIs.

**Key Functions:**
- `mintNft(string memory tokenUri)` - Mint a new NFT with custom URI
- `tokenURI(uint256 tokenId)` - Retrieve metadata URI for a token

### MoodNft.sol
An advanced NFT contract featuring on-chain SVG images and interactive mood changes.

**Key Functions:**
- `mintNft()` - Mint a new mood NFT (requires payment)
- `flipMood(uint256 tokenId)` - Change the NFT's mood (Happy ↔ Sad)
- `setMintPrice(uint256 newPrice)` - Owner can adjust minting price
- `withdraw()` - Owner can withdraw contract balance
- `getMintPrice()` - View current minting price
- `getTokenCounter()` - View total minted tokens

## 🛠 Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)
- [Node.js](https://nodejs.org/) (for additional tooling)

## 🚀 Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd NFTs-NonFungibleTokens
   ```

2. **Install dependencies:**
   ```bash
   forge install
   ```

3. **Build the project:**
   ```bash
   forge build
   ```

## 🎮 Usage

### Running Tests

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-contract BasicNftTest
forge test --match-contract MoodNftTest

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

### Deploying Contracts

1. **Deploy BasicNft:**
   ```bash
   forge script script/DeployBasicNft.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
   ```

2. **Deploy MoodNft:**
   ```bash
   forge script script/DeployMoodNft.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
   ```

### Interacting with Contracts

**BasicNft Interaction:**
```solidity
// Mint an NFT with custom metadata
basicNft.mintNft("ipfs://your-metadata-uri");
```

**MoodNft Interaction:**
```solidity
// Mint a mood NFT (requires 0.01 ETH by default)
moodNft.mintNft{value: 0.01 ether}();

// Flip the mood of your NFT
moodNft.flipMood(tokenId);
```

## 🧪 Testing

The project includes comprehensive test suites covering:

- **BasicNft Tests:**
  - Name and symbol verification
  - Minting functionality
  - Token URI handling
  - Input validation
  - Multiple NFT minting

- **MoodNft Tests:**
  - Payment validation
  - Mood flipping functionality
  - Access control (owner vs non-owner)
  - Price management
  - Withdrawal functionality
  - Event emission
  - Token counter management

Run tests with detailed output:
```bash
forge test -vvv
```

## 🚀 Deployment

### Local Development
```bash
# Start local node
anvil

# Deploy to local network
forge script script/DeployMoodNft.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY> --broadcast
```

### Testnet Deployment
```bash
# Deploy to Sepolia testnet
forge script script/DeployMoodNft.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## 🎨 On-Chain Metadata

The MoodNft contract demonstrates **100% on-chain metadata** storage:

- **SVG Images**: Base64 encoded and stored directly in the contract
- **JSON Metadata**: Dynamically generated with current mood state
- **No External Dependencies**: All data is stored on the blockchain

Example metadata structure:
```json
{
  "name": "Mood NFT",
  "description": "An NFT that reflects the mood of the owner, 100% on Chain!",
  "attributes": [{"trait_type": "moodiness", "value": 100}],
  "image": "data:image/svg+xml;base64,..."
}
```

## 🔒 Security Features

- **Access Control**: Owner-only functions for critical operations
- **Input Validation**: Prevents empty token URIs and invalid payments
- **Error Handling**: Custom errors for better gas efficiency
- **Safe Transfers**: Uses OpenZeppelin's `_safeMint` for secure transfers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) for secure contract libraries
- [Foundry](https://book.getfoundry.sh/) for the development framework
- [Forge](https://book.getfoundry.sh/forge/) for testing and deployment tools

---

**Happy Coding! 🚀**