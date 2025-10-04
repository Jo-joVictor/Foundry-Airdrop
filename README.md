# MerkleAirdrop Smart Contract

A gas-efficient token airdrop system built with Solidity and Foundry that uses Merkle trees for verification and EIP-712 signatures for secure, gasless claiming via relayers.

## Features

- **Merkle tree verification**: Efficient proof-based claim validation
- **EIP-712 signature support**: Enables gasless transactions through meta-transactions
- **Gas-optimized claiming**: Users can claim tokens or delegate to a gas payer
- **Duplicate claim protection**: Prevents multiple claims from the same address
- **Claimer tracking**: Maintains a record of all addresses that have claimed
- **Safe token transfers**: Uses OpenZeppelin's SafeERC20 for secure transfers
- **Automated proof generation**: Scripts included for merkle tree creation

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Installation

```bash
git clone <your-repo-url>
cd merkle-airdrop
forge install
```

## Usage

### Generate Merkle Tree

```bash
# Step 1: Generate input.json with whitelisted addresses
forge script script/GenerateInput.s.sol

# Step 2: Generate merkle proofs and root
forge script script/MakeMerkle.s.sol
```

This creates two files in `script/target/`:
- `input.json`: Whitelist of addresses and amounts
- `output.json`: Merkle proofs, root, and leaf hashes

### Deploy Contracts

```bash
# Deploy to local anvil
forge script script/DeployMerkleAirdrop.s.sol --rpc-url <RPC_URL> --broadcast

# Deploy to testnet
forge script script/DeployMerkleAirdrop.s.sol --rpc-url <TESTNET_RPC_URL> --private-key <PRIVATE_KEY> --broadcast --verify
```

### Claim Tokens

Users can claim tokens by providing:
- Their address
- Claim amount
- Merkle proof (from output.json)
- EIP-712 signature (v, r, s)

```solidity
airdrop.claim(account, amount, merkleProof, v, r, s);
```

## Contract Architecture

### Core Contracts

- **MerkleAirdrop.sol**: Main airdrop contract with merkle verification and signature validation
- **Michael.sol**: ERC20 token being distributed (MIK token with 1M initial supply)

### Key Components

#### MerkleAirdrop Functions

- `claim()`: Verify proof and signature, then transfer tokens to claimer
- `getMessageHash()`: Generate EIP-712 typed data hash for signing
- `getMerkleRoot()`: Return the merkle root used for verification
- `getAirdropToken()`: Return the token contract address
- `hasClaimed()`: Check if an address has already claimed
- `getClaimers()`: Get list of all addresses that have claimed

#### Michael Token Functions

- `mint()`: Owner-only function to mint additional tokens
- Standard ERC20 functionality

### Deployment Scripts

- **DeployMerkleAirdrop.s.sol**: Deploys token and airdrop contracts, transfers initial supply
- **GenerateInput.s.sol**: Creates input.json with whitelisted addresses and amounts
- **MakeMerkle.s.sol**: Generates merkle tree, proofs, and root from input.json

## Testing

Run the complete test suite:

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test testUsersCanClaim
```

### Test Coverage

- **Successful Claims**: Users can claim with valid proof and signature
- **Gasless Claims**: Gas payer can claim on behalf of user with valid signature
- **Duplicate Prevention**: Reverts on second claim attempt
- **Invalid Proof**: Reverts with invalid merkle proof
- **Invalid Signature**: Reverts with incorrect signature
- **Event Emission**: Validates Claim event is emitted correctly
- **Getter Functions**: Tests all view functions
- **Claimer Tracking**: Verifies claimer array updates correctly

## Security Features

- **Merkle Proof Verification**: Only whitelisted addresses can claim
- **EIP-712 Signatures**: Prevents replay attacks and ensures claim authenticity
- **Duplicate Claim Prevention**: Mapping tracks claimed addresses
- **SafeERC20**: Protects against non-standard token implementations
- **Custom Errors**: Gas-efficient error handling
- **Immutable Variables**: Merkle root and token address cannot be changed

## Gas Optimization

- Custom errors instead of require strings
- Immutable variables for constant values
- Efficient storage with mappings
- SafeERC20 for optimized token transfers
- Merkle trees reduce on-chain storage requirements

## Merkle Tree Structure

The airdrop uses a standard Merkle tree implementation:

1. **Leaf Generation**: `keccak256(bytes.concat(keccak256(abi.encode(address, amount))))`
2. **Tree Construction**: Binary tree built from leaf hashes
3. **Proof Verification**: Users provide branch hashes to verify their leaf

### Example Whitelist

```json
{
  "types": ["address", "uint"],
  "count": 4,
  "values": {
    "0": {
      "0": "0xEeaD1C9a07cbDcB51d6C658672A9BCc3c742a47D",
      "1": "25000000000000000000"
    },
    "1": {
      "0": "0x2C8a6AD355c6635A29eeb59AD2a4DFf58333DeED",
      "1": "25000000000000000000"
    },
    "2": {
      "0": "0x660c67397FD36EfB9116f90F555558B4da685790",
      "1": "25000000000000000000"
    },
    "3": {
      "0": "0x92188D4D8814886Ff08E1199d125E1995F432f1e",
      "1": "25000000000000000000"
    }
  }
}
```

## EIP-712 Signature Structure

The contract implements EIP-712 for structured data signing:

```solidity
struct AirdropClaim {
    address account;
    uint256 amount;
}
```

**Domain**: `MerkleAirdrop` version `1`

**Message Type**: `AirdropClaim(address account,uint256 amount)`

## Token Details

**Michael Token (MIK)**
- Initial Supply: 1,000,000 MIK
- Decimals: 18
- Mintable: Yes (owner only)
- Standard: ERC20

## Deployment Configuration

### Default Airdrop Parameters

- **Merkle Root**: `0x6ca27f42c07c4174051ccff754332d7da0513d513bedbe8ce35b3fa05fc66522`
- **Airdrop Amount**: 100 tokens (4 users × 25 tokens each)
- **Claim Amount**: 25 tokens per address

### Whitelisted Addresses

1. `0xEeaD1C9a07cbDcB51d6C658672A9BCc3c742a47D` - 25 MIK
2. `0x2C8a6AD355c6635A29eeb59AD2a4DFf58333DeED` - 25 MIK
3. `0x660c67397FD36EfB9116f90F555558B4da685790` - 25 MIK
4. `0x92188D4D8814886Ff08E1199d125E1995F432f1e` - 25 MIK

## Deployed Contracts

### Sepolia Testnet
- **MerkleAirdrop Contract**: `0x7fa9385be102ac3eac297483dd6233d62b3e1496`
- **Michael Token (MIK)**: `0x5b73c5498c1e3b4dba84de0f1833c4a029d90519`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [EIP-712 Specification](https://eips.ethereum.org/EIPS/eip-712)
- [Merkle Tree Explanation](https://en.wikipedia.org/wiki/Merkle_tree)
- [Murky Library](https://github.com/dmfxyz/murky)
