// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TokenManager.sol";

contract Wallet is AccessControlEnumerable, ReentrancyGuard, TokenManager {
    using SafeMath for uint256;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() {
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    /**
     * Mapping from address to balance of a particular token
     */
    mapping(address => mapping(bytes32 => uint256)) balanceMapping;

    /**
     * Deposit has occurred
     */
    event deposited(address depositer, uint256 amount);

    /**
     * Wtihdrawl has occurred
     */
    event withdrawn(address depositer, uint256 amount);

    /**
     * Function to add token assets into the accepted token lists
     */
    function addToken(bytes32 token_, address tokenAddress_) external {
        require(
            hasRole(MANAGER_ROLE, msg.sender),
            "Must have manager role to add tokens"
        );
        require(
            tokenAddress[token_] == address(0),
            "This token has already been added"
        );
        tokenAddress[token_] = tokenAddress_;
        tokenList.push(token_);
    }

    /**
     * Withdraw function
     * @dev funds are taken out back from the contract
     * Using the Check, Effect, Interaction Rule
     * Is Reentrancy module neccassary over here?
     */
    function withdraw(bytes32 token_, uint256 amount_)
        external
        tokenExists(token_)
        nonReentrant
    {
        require(
            balanceMapping[msg.sender][token_] >= amount_,
            "Insufficient balance"
        );

        balanceMapping[msg.sender][token_] = balanceMapping[msg.sender][token_]
        .sub(amount_);

        IERC20(tokenAddress[token_]).transfer(msg.sender, amount_);

        emit withdrawn(msg.sender, amount_);
    }

    /**
     * @dev funds are deposited into the contract
     * Using the Check, Effect, Interaction Rule
     * Using the openzeppelin Reentrancy module
     */
    function deposit(bytes32 token_, uint256 amount_)
        external
        tokenExists(token_)
        nonReentrant
    {
        require(
            balanceMapping[msg.sender][token_] >= amount_,
            "Insufficient balance"
        );

        IERC20 ERC20 = IERC20(tokenAddress[token_]);

        if (ERC20.allowance(msg.sender, address(this)) > amount_) {
            ERC20.transferFrom(msg.sender, address(this), amount_);
        } else {
            bool isApproved = ERC20.approve(address(this), amount_);
            if (isApproved == true) {
                ERC20.transferFrom(msg.sender, address(this), amount_);
            }
        }

        balanceMapping[msg.sender][token_] = balanceMapping[msg.sender][token_]
        .add(amount_);

        emit deposited(msg.sender, amount_);
    }
}
