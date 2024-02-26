//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{

    NetworkConfig public activeNetworkConfig;
    uint8 private constant DECIAMLS = 8;
    int256 private constant INTIAL_PRICE = 2000e8;
    uint256 private constant sepoliaChainId = 11155111;

    struct NetworkConfig{
        address priceFeed;
    }

    constructor() {
        if(block.chainid == sepoliaChainId){
            activeNetworkConfig = getSepEthConfig();
        }else{
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory sepConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){
        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIAMLS, INTIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}