# Merkle Airdrop Project

A complete Merkle-tree based airdrop system with EIP-712 signature verification built with Foundry.

## Project Structure

```
├── script/
│   ├── DeployMerkleAirdrop.s.sol    # Deployment script
│   ├── GenerateInput.s.sol          # Generates input.json with addresses and amounts
│   ├── MakeMerkle.s.sol            # Generates Merkle tree and proofs
│   └── target/
│       ├── input.json              # Input data for Merkle tree
│       └── output.json             # Merkle root and proofs
├── src/
│   ├── Michael.sol                 # ERC20 token to be airdropped
│   └── MerkleAirdrop.sol           # Main airdrop contract
└── test/
    └── MerkleAirdropTest.t.sol     # Test suite
```

## Dependencies Installation

```bash
# Initialize Foundry project (if not already)
forge init

# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install Murky for Merkle tree generation
forge install dmfxyz/murky --no-commit

# Install Foundry DevOps
forge install Cyfrin/foundry-devops --no-commit
```

## Configuration

Add to your `foundry.toml`:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
    "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/",
    "forge-std/=lib/forge-std/src/"
]

[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"
mainnet = "${MAINNET_RPC_URL}"
```

## Setup Steps

### 1. Generate Input Data

Generate the input.json file with whitelisted addresses and amounts:

```bash
forge script script/GenerateInput.s.sol
```

This creates `script/target/input.json` with your airdrop recipients.

### 2. Generate Merkle Tree and Proofs

Generate the Merkle root and proofs from input data:

```bash
forge script script/MakeMerkle.s.sol
```

This creates `script/target/output.json` with:
- Merkle root
- Merkle proofs for each address

### 3. Update Deployment Script

Copy the Merkle root from `output.json` and update it in `DeployMerkleAirdrop.s.sol`:

```solidity
bytes32 public ROOT = 0xYOUR_MERKLE_ROOT_HERE;
```

### 4. Deploy Contracts

Deploy to local Anvil chain:

```bash
# Start Anvil
anvil

# Deploy (in new terminal)
forge script script/DeployMerkleAirdrop.s.sol --rpc-url http://localhost:8545 --broadcast
```

Deploy to testnet (e.g., Sepolia):

```bash
forge script script/DeployMerkleAirdrop.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

## Usage

### Claiming Airdrop

Users need to:
1. Sign a message with their private key
2. Submit the signature along with their Merkle proof

#### Generate Signature (Off-chain)

Use Cast to generate signature:

```bash
# Get message hash
cast call <AIRDROP_ADDRESS> "getMessageHash(address,uint256)" <USER_ADDRESS> <AMOUNT>

# Sign the message hash
cast wallet sign <MESSAGE_HASH> --private-key <PRIVATE_KEY>
```

#### Claim via Direct Contract Interaction

Users can claim through:
- **Frontend dApp** (recommended for end users)
- **Direct contract interaction** (using Cast or web3 libraries)
- **Custom scripts** (for automated systems)

Example using Cast:

```bash
# Split signature into v, r, s
# Then call claim function
cast send <AIRDROP_ADDRESS> "claim(address,uint256,bytes32[],uint8,bytes32,bytes32)" \
  <USER_ADDRESS> <AMOUNT> "[<PROOF1>,<PROOF2>]" <V> <R> <S> \
  --private-key <PRIVATE_KEY>
```

## Testing

Run all tests:

```bash
forge test
```

Run with verbosity:

```bash
forge test -vvvv
```

Run specific test:

```bash
forge test --match-test testUsersCanClaim -vvvv
```

Run with gas report:

```bash
forge test --gas-report
```

## Key Features

### MerkleAirdrop Contract

- **EIP-712 Signatures**: Users sign typed structured data
- **Merkle Proof Verification**: Efficient whitelist verification
- **Gas Optimization**: Third-party can pay gas for users
- **Reentrancy Protection**: Uses OpenZeppelin's SafeERC20

### Security Features

- Prevents double claiming
- Validates signatures against message hash
- Verifies Merkle proofs
- Uses battle-tested OpenZeppelin contracts

## Contract Interactions

### Check if Address Has Claimed

```bash
cast call <AIRDROP_ADDRESS> "hasClaimed(address)" <USER_ADDRESS>
```

### Get Merkle Root

```bash
cast call <AIRDROP_ADDRESS> "getMerkleRoot()"
```

### Get Airdrop Token

```bash
cast call <AIRDROP_ADDRESS> "getAirdropToken()"
```

### Check Token Balance

```bash
cast call <TOKEN_ADDRESS> "balanceOf(address)" <USER_ADDRESS>
```

## Environment Variables

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

Load environment variables:

```bash
source .env
```

## Workflow Example

```bash
# 1. Generate input data
forge script script/GenerateInput.s.sol

# 2. Generate Merkle tree
forge script script/MakeMerkle.s.sol

# 3. Copy Merkle root to deployment script

# 4. Deploy
forge script script/DeployMerkleAirdrop.s.sol --rpc-url http://localhost:8545 --broadcast

# 5. User signs message (off-chain)
cast wallet sign <MESSAGE_HASH> --private-key <PRIVATE_KEY>

# 6. User claims airdrop (via dApp or direct call)

# 7. Verify claim
cast call <TOKEN_ADDRESS> "balanceOf(address)" <USER_ADDRESS>
```

## Customization

### Adding More Users

Edit `GenerateInput.s.sol`:

```solidity
string[] whitelist = new string[](YOUR_COUNT);
whitelist[0] = "0xAddress1";
whitelist[1] = "0xAddress2";
// Add more addresses
```

### Changing Airdrop Amount

Edit in `GenerateInput.s.sol`:

```solidity
uint256 private constant AMOUNT = YOUR_AMOUNT * 1e18;
```

Update `AMOUNT_TO_TRANSFER` in `DeployMerkleAirdrop.s.sol` accordingly.

## Troubleshooting

### "Invalid Proof" Error

- Ensure you're using the correct proof from `output.json`
- Verify the Merkle root matches deployment
- Check that address and amount match input data
- Regenerate Merkle tree if you modified `input.json`

### "Invalid Signature" Error

- Ensure signature is signed by the claiming address
- Verify message hash is generated correctly
- Check v, r, s values are split correctly

### "Already Claimed" Error

- Address has already claimed their airdrop
- Check with `hasClaimed(address)` function

### Merkle Tree Generation Issues

If proofs don't verify:
1. Ensure `MakeMerkle.s.sol` uses double-hashing: `keccak256(bytes.concat(keccak256(dataEncoded)))`
2. This must match the contract's leaf generation
3. Regenerate the tree after any changes

## Gas Optimization Tips

- Users can have someone else pay for gas (meta-transaction pattern)
- Batch multiple claims in a single transaction (requires contract modification)
- Use efficient data structures (uint96 for amounts if possible)

## License

MIT
