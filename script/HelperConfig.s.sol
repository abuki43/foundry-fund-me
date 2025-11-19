// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {

    NetworkConfig public activeNetworkConfig;

    uint8 constant ETH_DECIMALS = 8;  
    int256 constant ETH_INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }else{
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory sepoliaCOnfig = NetworkConfig({
            priceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaCOnfig;
    }

    function getOrCreateAnvilEthConfig() public  returns(NetworkConfig memory){

        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(ETH_DECIMALS, ETH_INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig; 
    }
}