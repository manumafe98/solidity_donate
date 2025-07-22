// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DonateTo {
    error DonateTo_TransferDonationFailed();
    error DonateTo_TransferRefundFailed();

    AggregatorV3Interface internal dataFeed;
    address private immutable i_owner;
    uint256 private constant PRECISION = 1e18;

    constructor(address priceFeedContract) {
        dataFeed = AggregatorV3Interface(priceFeedContract);
        i_owner = msg.sender;
    }

    function donate(address payable _receiver, uint256 _usdAmount) external payable {
        uint256 ethToDonate = getEthAmountForUsd(_usdAmount);
        (bool donationTransfer,) = _receiver.call{value: ethToDonate}("");
        if (!donationTransfer) {
            revert DonateTo_TransferDonationFailed();
        }

        if (msg.value > ethToDonate) {
            (bool refundTransfer,) =  msg.sender.call{value: msg.value - ethToDonate}("");
            if (!refundTransfer) {
                revert DonateTo_TransferRefundFailed();
            }
        }
    }

    function getEthAmountForUsd(uint256 _usdAmount) public view returns(uint256) {
        (
            /* uint80 roundId */,
            int256 currentPrice,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return (_usdAmount * PRECISION) / uint256(currentPrice);
    }
}
