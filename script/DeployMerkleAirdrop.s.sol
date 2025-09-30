// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {Michael} from "../src/Michael.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    // Merkle root from output.json
    bytes32 public constant MERKLE_ROOT = 0x6ca27f42c07c4174051ccff754332d7da0513d513bedbe8ce35b3fa05fc66522;
    
    // Amount to transfer to airdrop contract (4 users * 25 tokens each)
    uint256 public constant AIRDROP_AMOUNT = 100e18;

    function run() external returns (MerkleAirdrop, Michael) {
        return deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns (MerkleAirdrop, Michael) {
        vm.startBroadcast();

        // Deploy Michael token
        Michael token = new Michael();
        console.log("Michael Token deployed at:", address(token));

        // Deploy MerkleAirdrop contract
        MerkleAirdrop airdrop = new MerkleAirdrop(MERKLE_ROOT, IERC20(address(token)));
        console.log("MerkleAirdrop deployed at:", address(airdrop));

        // Transfer tokens to airdrop contract
        token.transfer(address(airdrop), AIRDROP_AMOUNT);
        console.log("Transferred", AIRDROP_AMOUNT / 1e18, "tokens to airdrop contract");

        // Log merkle root for verification
        console.log("Merkle Root:", vm.toString(MERKLE_ROOT));

        vm.stopBroadcast();

        return (airdrop, token);
    }
}