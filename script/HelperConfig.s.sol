// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {CodeConstants} from "./CodeConstants.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address priceFeedContract;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory config) {
        config = getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 _chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[_chainId].priceFeedContract != address(0)) {
            return networkConfigs[_chainId];
        } else if (_chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfigByChainId() public {}

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaEthNetworkConfig) {
        sepoliaEthNetworkConfig = NetworkConfig({priceFeedContract: ETH_SEPOLIA_PRICE_FEED_ADDRESS});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.priceFeedContract != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast(msg.sender);
        MockV3Aggregator priceFeedMock = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({priceFeedContract: address(priceFeedMock)});

        return localNetworkConfig;
    }
}
