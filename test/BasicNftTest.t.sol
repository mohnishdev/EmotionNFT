// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract BasicNftTest is Test {
    DeployBasicNft public deployer;
    BasicNft public basicNft;
    address public USER = makeAddr("user");
    
    string public constant PUG_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function setUp() public {
        deployer = new DeployBasicNft();
        basicNft = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Dogie";
        string memory actualName = basicNft.name();
        assert(keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(actualName)));
    }

    function testSymbolIsCorrect() public view {
        string memory expectedSymbol = "DOG";
        string memory actualSymbol = basicNft.symbol();
        assert(keccak256(abi.encodePacked(expectedSymbol)) == keccak256(abi.encodePacked(actualSymbol)));
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(basicNft.balanceOf(USER) == 1);
        assert(basicNft.ownerOf(0) == USER);
    }

    function testTokenURIIsSet() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(keccak256(abi.encodePacked(basicNft.tokenURI(0))) == keccak256(abi.encodePacked(PUG_URI)));
    }

    function testRevertsWithEmptyTokenURI() public {
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__EmptyTokenUri.selector);
        basicNft.mintNft("");
    }

    function testMintingUpdatesTokenCounter() public {
        uint256 startingCounter = 0;
        assert(basicNft.balanceOf(USER) == startingCounter);
        
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(basicNft.balanceOf(USER) == 1);
        
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(basicNft.balanceOf(USER) == 2);
    }

    function testCanMintMultipleNFTs() public {
        vm.startPrank(USER);
        basicNft.mintNft(PUG_URI);
        basicNft.mintNft(PUG_URI);
        basicNft.mintNft(PUG_URI);
        vm.stopPrank();
        
        assert(basicNft.balanceOf(USER) == 3);
        assert(basicNft.ownerOf(0) == USER);
        assert(basicNft.ownerOf(1) == USER);
        assert(basicNft.ownerOf(2) == USER);
    }
}
