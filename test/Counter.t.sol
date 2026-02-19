// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// Simple interface to check balances
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract MakinaForkTest is Test {
    // 1. Define the addresses
    address constant DUSD = 0x1e33E98aF620F1D563fcD3cfd3C75acE841204ef; // Add the DUSD address from Etherscan
    address constant ATTACKER = 0x935bfb495E33f74d2E9735DF1DA66acE442ede48;
    
    uint256 mainnetFork;

    function setUp() public {
        // 2. Create and Select the Fork at a specific block
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        mainnetFork = vm.createSelectFork(rpcUrl, 24273360); 
    }

    function testStateAtFork() public {
        // 3. Verify we are in the past
        assertEq(block.number, 24273360);
        
        // 4. Check the attacker's balance before the hack
        uint256 balance = IERC20(DUSD).balanceOf(ATTACKER);
        console.log("Attacker DUSD Balance at block 24273360:", balance);
    }
}