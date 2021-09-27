// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract BitBookRewardClaim is Ownable, AccessControl  {
    using SafeERC20 for IERC20;

    bytes32 public constant REWARD_SIGNER_ROLE = keccak256("REWARD_SIGNER_ROLE");

    bytes32 public CLAIM_TYPEHASH;
    bytes32 public DOMAIN_SEPARATOR;
    mapping(address => uint) public nonces;

    IERC20 public bitbook;
    mapping(address => uint256) public userClaimedRewards;
    bool public claimPaused;

    event RewardClaimed(address indexed account, uint256 indexed amount);
    event SignerAdminUpdated(address admin);
    event ClaimPausedUpdated(bool paused);

    constructor(IERC20 _bitbook) {
        bitbook = _bitbook;
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("BITBOOK_REWARD_CLAIM")),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        CLAIM_TYPEHASH = calculateTypeHash();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function claimRewards(address user, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(!claimPaused, 'BITBOOK_REWARD_CLAIM: REWARD_CLAIM_PAUSED');
        require(deadline >= block.timestamp, 'BITBOOK_REWARD_CLAIM: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(CLAIM_TYPEHASH, user, amount, nonces[user]++, deadline))
            )
        );
        address signer = ecrecover(digest, v, r, s);
        require(hasRole(REWARD_SIGNER_ROLE, signer), 'BITBOOK_REWARD_CLAIM: INVALID_SIGNATURE');
        bitbook.safeTransfer(user, amount);
        userClaimedRewards[user] += amount;
        emit RewardClaimed(user, amount);
    }
    
    function calculateTypeHash() internal pure returns (bytes32) {
        return keccak256('ClaimRewards(address user,uint256 amount,uint256 nonce,uint256 deadline)');
    }

    function setSignerRoleAdmin(address admin) external onlyOwner {
        require(admin != address(0), 'BITBOOK_REWARD_CLAIM: INVALID_ADMIN!');
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        emit SignerAdminUpdated(admin);
    }

    function grandRewardSignerRole(address account) external onlyOwner {
        require(account != address(0), 'BITBOOK_REWARD_CLAIM: INVALID_ACCOUNT!');
        grantRole(REWARD_SIGNER_ROLE, account);
    }

    function revokeRewardSignerRole(address account) external onlyOwner {
        revokeRole(REWARD_SIGNER_ROLE, account);
    }

    function updateClaimPaused(bool paused) external onlyOwner {
        claimPaused = paused;
        emit ClaimPausedUpdated(paused);
    }

    function withdrawBEP20(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        token.transfer(recipient, amount);
    }
}