// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// Simple interface to check balances
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}
interface Morpho{
    function flashLoan(address token, uint256 assets, bytes calldata data) external;
}

contract MakinaForkTest is Test {
    // 1. Define the addresses
    address constant DUSD = 0x1e33E98aF620F1D563fcD3cfd3C75acE841204ef; 
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ATTACKER = 0x935bfb495E33f74d2E9735DF1DA66acE442ede48;
    uint256 constant BLOCK_NUMBER = 24273361;
    address constant MORPHO_ADDRESS = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    function setUp() public {
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpcUrl, BLOCK_NUMBER); 
    }

    function testStateAtFork() public {
        assertEq(block.number, BLOCK_NUMBER);
    }

    function testcallFlashLoan() public {
        uint256 mophoBalance = IERC20(USDC).balanceOf(MORPHO_ADDRESS);
        console.log("Mopho balance:", mophoBalance/1e6);
        bytes memory data = abi.encode(1111, "zabi");
        Morpho(MORPHO_ADDRESS).flashLoan(USDC, mophoBalance, data);
    }

    function onMorphoFlashLoan(uint256 amount, bytes memory data) public returns (bool) {
        require(msg.sender == MORPHO_ADDRESS, "Not Morpho");
        console.log("Funds received", amount, string(data));
        return true;
    }
}