// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenManager {
    /**
     * Token Array for listing all the valid tokens that the dex support
     */
    bytes32[] tokenList;

    /**
     * Mapping from tokens to token addresses
     */
    mapping(bytes32 => address) tokenAddress;

    modifier tokenExists(bytes32 token_) {
        require(
            tokenAddress[token_] == address(0),
            "This token has already been added"
        );
        _;
    }
}
