# Merkle Airdrop with EIP-712 Signatures

A secure and gas-efficient airdrop system using Merkle trees and EIP-712 typed signatures for the JOJO token.

## Features

- **Merkle Tree Verification**: Efficient whitelist verification using Merkle proofs
- **EIP-712 Signatures**: Gasless claiming with meta-transactions
- **Signature Verification**: Users sign claims off-chain, anyone can submit
- **Double-Claim Protection**: Prevents users from claiming multiple times
- **Gas Efficient**: Optimized for minimal gas costs

## Project Structure

```
├── src/
│   ├── MerkleAirdrop.sol          # Main airdrop contract
│   └── Jojo.sol                   # JOJO ERC20 token
├── script/
│   ├── DeployMerkleAirdrop.s.sol  # Deployment script
│   ├── GenerateInput.s.sol        # Generate input.json for whitelist
│   ├── MakeMerkle.s.sol           # Generate Merkle tree and proofs
│   ├── Interact.s.sol             # Claim airdrop script
│   └── targets/
│       ├── input.json             # Whitelist addresses and amounts
│       └── output.json            # Merkle root and proofs
├── test/
│   └── MerkleAirdropTest.t.sol    # Comprehensive tests
└── foundry.toml                   # Foundry configuration
```

## Setup

### 1. Install Dependencies

```bash
make install
# or
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install Cyfrin/foundry-devops --no-commit
```

### 2. Create Environment File

Create a `.env` file with your configuration:

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
AIRDROP_TOKEN=0xYourJojoTokenAddressOnSepolia
```

### 3. Build the Project

```bash
make build
# or
forge build
```

## Usage Workflow

### Step 1: Generate Input File

First, generate the `input.json` file with whitelisted addresses and amounts:

```bash
make generate-input
# or
forge script script/GenerateInput.s.sol
```

This creates `script/targets/input.json` with your whitelist:

```json
{
  "types": ["address", "uint"],
  "count": 4,
  "values": {
    "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D": "25000000000000000000",
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": "25000000000000000000"
  }
}
```

**Customize this file** with your actual addresses and amounts!

### Step 2: Generate Merkle Tree

Generate the Merkle tree and proofs from the input file:

```bash
make make-merkle
# or
forge script script/MakeMerkle.s.sol
```

This creates `script/targets/output.json` containing:
- Merkle root
- Merkle proofs for each address

### Step 3: Deploy the Airdrop Contract

Deploy to Sepolia (make sure you have JOJO tokens deployed first):

```bash
make deploy-sepolia
# or
forge script script/DeployMerkleAirdrop.s.sol:DeployMerkleAirdrop \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --verify
```

**Important**: After deployment, transfer JOJO tokens to the airdrop contract!

```bash
# Transfer tokens to airdrop contract
cast send <JOJO_TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  <AIRDROP_CONTRACT_ADDRESS> \
  100000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Step 4: Claim Airdrop

Users need to:

1. **Get their proof** from `output.json`
2. **Sign the claim message** using their private key
3. **Submit the claim** (can be done by anyone - gasless for user!)

#### Generate Signature (Off-chain)

```javascript
// Example using ethers.js
const domain = {
  name: "MerkleAirdrop",
  version: "1",
  chainId: 11155111, // Sepolia
  verifyingContract: airdropAddress
};

const types = {
  AirdropClaim: [
    { name: "account", type: "address" },
    { name: "amount", type: "uint256" }
  ]
};

const value = {
  account: userAddress,
  amount: claimAmount
};

const signature = await signer._signTypedData(domain, types, value);
```

#### Submit Claim

```bash
make claim
# or
forge script script/Interact.s.sol:ClaimAirdrop \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## Testing

Run comprehensive tests:

```bash
make test
# or
forge test -vvv
```

Tests include:
- ✅ Successful claims
- ✅ Prevent double claiming
- ✅ Invalid proof rejection
- ✅ Invalid signature rejection

## Contract Functions

### MerkleAirdrop.sol

#### `claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)`

Claims airdrop tokens for an address. Requires:
- Valid Merkle proof
- Valid EIP-712 signature from the claiming address
- Address hasn't claimed before

#### `getMessageHash(address account, uint256 amount)`

Returns the EIP-712 typed data hash for signing.

#### `getMerkleRoot()`

Returns the Merkle root used for verification.

#### `hasClaimed(address account)`

Checks if an address has already claimed.

## Security Features

1. **Merkle Proof Verification**: Only whitelisted addresses can claim
2. **EIP-712 Signatures**: Prevents signature replay attacks across chains
3. **Double-Claim Prevention**: Mapping tracks claimed addresses
4. **Signature Verification**: Only valid signatures accepted
5. **Immutable Root**: Merkle root cannot be changed after deployment

## Gas Optimization

- Custom errors instead of require strings
- Immutable variables for gas savings
- SafeERC20 for safe token transfers
- Optimized Merkle verification

## Important Notes

1. **Update Token Address**: Replace `SEPOLIA_JOJO_TOKEN` in `DeployMerkleAirdrop.s.sol` with your actual JOJO token address
2. **Fund Airdrop Contract**: Transfer tokens to the airdrop contract before users can claim
3. **Update Whitelist**: Modify `GenerateInput.s.sol` with your actual recipient addresses
4. **Signature Generation**: Users must sign claims off-chain (can use the contract's `getMessageHash` function)
5. **Gas Payer**: Anyone can pay gas to submit claims, enabling gasless airdrops for users

## Example Flow

```bash
# 1. Generate whitelist
make generate-input

# 2. Edit script/targets/input.json with your addresses

# 3. Generate Merkle tree
make make-merkle

# 4. Deploy contract (with Merkle root from output.json)
make deploy-sepolia

# 5. Transfer JOJO tokens to airdrop contract

# 6. Users sign their claims off-chain

# 7. Submit claims (anyone can do this)
make claim
```

## Troubleshooting

**Issue**: "Merkle root is zero"
- **Solution**: Run `make make-merkle` before deploying

**Issue**: "Insufficient balance" during claim
- **Solution**: Ensure airdrop contract has enough JOJO tokens

**Issue**: "Invalid signature"
- **Solution**: Verify the signature was created using the correct domain and types

**Issue**: "Invalid proof"
- **Solution**: Use the exact proof from `output.json` for the claiming address

## License

MIT
