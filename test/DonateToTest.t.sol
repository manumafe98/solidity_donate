// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DonateTo} from "../src/DonateTo.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployDonateTo} from "../script/DeployDonateTo.s.sol";
import {CodeConstants} from "../script/CodeConstants.sol";

contract DonateToTest is Test, CodeConstants {
    DonateTo donateTo;
    HelperConfig.NetworkConfig config;

    address priceFeedContract;

    address SENDER = makeAddr("sender");
    address RECEIVER = makeAddr("receiver");

    modifier skipWhenSepolia() {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            return;
        }
        _;
    }

    modifier skipWhenLocal() {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployDonateTo deployer = new DeployDonateTo();
        (donateTo, config) = deployer.run();

        priceFeedContract = config.priceFeedContract;
    }

    function testPriceFeedContractAddressLocal() external view skipWhenSepolia {
        assertEq(donateTo.getPriceFeedContract(), priceFeedContract);
    }

    function testPriceFeedContractAddressSepolia() external view skipWhenLocal {
        assertEq(donateTo.getPriceFeedContract(), ETH_SEPOLIA_PRICE_FEED_ADDRESS);
    }

    function testGetOwner() external view {
        assertEq(donateTo.getOwner(), msg.sender);
    }

    function testGetEthAmountForUsd(uint256 _amount) external view {
        uint256 precision = donateTo.getPrecision();
        uint256 safeMaxAmount = type(uint256).max / precision;
        _amount = bound(_amount, 1, safeMaxAmount);

        uint256 currentEthAmount = donateTo.getEthAmountForUsd(_amount);
        uint256 expectedEthAmount = (_amount * precision) / uint256(ETH_USD_PRICE);

        assertEq(currentEthAmount, expectedEthAmount);
    }

    function testDonate(uint256 _amount) external {
        uint256 precision = donateTo.getPrecision();
        uint256 ethPrice = uint256(ETH_USD_PRICE);
        uint256 ethBudget = 100 ether;

        uint256 maxUsdAmount = (ethBudget * ethPrice) / precision;
        _amount = bound(_amount, 1, maxUsdAmount);

        uint256 ethAmount = donateTo.getEthAmountForUsd(_amount);

        vm.deal(SENDER, ethBudget);
        vm.prank(SENDER);
        donateTo.donate{value: ethAmount}(payable(RECEIVER), _amount);

        assertEq(RECEIVER.balance, ethAmount);
    }

    function testDonateReverts() external {
        vm.prank(SENDER);
        vm.deal(SENDER, 1 ether);
        vm.expectRevert(DonateTo.DonateTo_TransferDonationFailed.selector);
        donateTo.donate{value: 1 ether}(payable(RECEIVER), 10 ether);
    }
}
