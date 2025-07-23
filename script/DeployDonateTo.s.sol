// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DonateTo} from "../src/DonateTo.sol";

contract DeployDonateTo is Script {
    function run() public returns (DonateTo, HelperConfig.NetworkConfig memory) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        DonateTo donateTo = new DonateTo(config.priceFeedContract);
        vm.stopBroadcast();

        return (donateTo, config);
    }
}
