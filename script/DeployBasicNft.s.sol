// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract DeployBasicNft is Script {
    function run() external returns(BasicNft) {
        vm.startBroadcast();
        BasicNft basicNft = new BasicNft();
        vm.stopBroadcast();

        console.log("BasicNft deployed at:", address(basicNft));
        console.log("Owner:", basicNft.owner());
        console.log("Name:", basicNft.name());
        console.log("Symbol:", basicNft.symbol());
        console.log("Default Royalty Fee:", basicNft.DEFAULT_ROYALTY_FEE());
        console.log("Max Batch Size:", basicNft.MAX_BATCH_SIZE());
        console.log("Public Minting Active:", basicNft.isPublicMintingActive());
        console.log("Whitelist Active:", basicNft.isWhitelistActive());

        return basicNft;
    }
}