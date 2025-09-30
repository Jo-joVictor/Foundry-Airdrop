// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {Michael} from "src/Michael.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop airdrop;
    Michael token;

    address user;
    uint256 userPrivKey;
    address gasPayer;

    // I'll generate a new merkle root with our test user
    bytes32 public MERKLE_ROOT;
    uint256 public constant AMOUNT_TO_CLAIM = 25e18;
    uint256 public constant STARTING_BALANCE = 10 ether;
    uint256 public constant MINTING_AMOUNT = AMOUNT_TO_CLAIM * 10;

    bytes32[] public PROOF;
    bytes32[] public BAD_PROOF;

    /** Events */
    event Claim(address account, uint256 amount);

    function setUp() public {
        // Create test user with known private key
        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
        
        console.log("user address:", user);
        console.log("private key:", userPrivKey);
        console.log("gas payer:", gasPayer);

        // Generate merkle tree for our test user
        // For a tree with just one user, the proof is empty and root equals the leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, AMOUNT_TO_CLAIM))));
        MERKLE_ROOT = leaf; // Single leaf tree - root equals leaf
        
        // Empty proof for single-node tree
        PROOF = new bytes32[](0);
        
        // Bad proof for testing
        BAD_PROOF = new bytes32[](1);
        BAD_PROOF[0] = bytes32(uint256(1));

        // Deploy contracts with our generated merkle root
        token = new Michael();
        airdrop = new MerkleAirdrop(MERKLE_ROOT, IERC20(address(token)));
        token.transfer(address(airdrop), MINTING_AMOUNT);

        vm.deal(user, STARTING_BALANCE);
        vm.deal(gasPayer, STARTING_BALANCE);
    }

    function _getDigest(address _user, uint256 _amount) private view returns (bytes32) {
        return airdrop.getMessageHash(_user, _amount);
    }

    function _getSignParams(uint256 _userPrivKey, bytes32 _digest)
        private
        pure
        returns (uint8, bytes32, bytes32)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_userPrivKey, _digest);
        return (v, r, s);
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);

        vm.startPrank(user);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endedBalance = token.balanceOf(user);
        vm.stopPrank();
        
        console.log("ending Balance:", endedBalance);
        assertNotEq(startingBalance, endedBalance);
        assertEq(endedBalance, AMOUNT_TO_CLAIM);
    }

    function testGasPayerToClaimInsteadUser() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);

        vm.startPrank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endedBalance = token.balanceOf(user);
        console.log("ending Balance:", endedBalance);
        assertNotEq(startingBalance, endedBalance);
        assertEq(endedBalance, AMOUNT_TO_CLAIM);
        vm.stopPrank();
    }

    function testClaimAgainAndGetReverted() public {
        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);

        vm.startPrank(user);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopPrank();
    }

    function testClaimRevertMerkleProofFailed() public {
        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);

        vm.startPrank(user);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        airdrop.claim(user, AMOUNT_TO_CLAIM, BAD_PROOF, v, r, s);
        vm.stopPrank();
    }

    function testClaimRevertInvalidSignature() public {
        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);
        uint8 v = 20;
        
        vm.startPrank(user);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopPrank();
    }

    function testEmitEventCorrect() public {
        vm.expectEmit(true, true, false, true);
        emit Claim(user, AMOUNT_TO_CLAIM);

        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);

        vm.startPrank(user);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopPrank();
    }

    function testCheckGetterGetMerkleRoot() public view {
        bytes32 merkleRootGetter = airdrop.getMerkleRoot();
        assertEq(MERKLE_ROOT, merkleRootGetter);
    }

    function testCheckGetterAirdropToken() public view {
        IERC20 tokenGetter = airdrop.getAirdropToken();
        assertEq(address(tokenGetter), address(token));
    }

    function testCheckHasClaimed() public {
        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);

        assertEq(airdrop.hasClaimed(user), false);

        vm.prank(user);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        assertEq(airdrop.hasClaimed(user), true);
    }

    function testClaimersArrayTracking() public {
        bytes32 digest = _getDigest(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = _getSignParams(userPrivKey, digest);

        address[] memory claimersBefore = airdrop.getClaimers();
        assertEq(claimersBefore.length, 0);

        vm.prank(user);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        address[] memory claimersAfter = airdrop.getClaimers();
        assertEq(claimersAfter.length, 1);
        assertEq(claimersAfter[0], user);
    }
}