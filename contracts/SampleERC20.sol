// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract SampleERC20 is ERC20 {
    constructor() ERC20('Sample ERC20','SAMPLE'){
        _mint(msg.sender, 1_000_000e18);
    }
}