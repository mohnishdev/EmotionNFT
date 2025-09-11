// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract BasicNftTest is Test {
    DeployBasicNft public deployer;
    BasicNft public basicNft;
    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");
    address public NON_WHITELISTED = makeAddr("nonWhitelisted");
    address public OWNER;
    
    string public constant PUG_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    string public constant VALID_JSON_URI = '{"name":"Test NFT","description":"A test NFT","image":"ipfs://test"}';
    string public constant INVALID_JSON_URI = '{"name":"Test NFT","description":"A test NFT"}'; // Missing image
    string public constant MALFORMED_JSON_URI = '{"name":"Test NFT"'; // Incomplete JSON

    function setUp() public {
        deployer = new DeployBasicNft();
        basicNft = deployer.run();
        OWNER = basicNft.owner();
    }

    // ============ BASIC FUNCTIONALITY TESTS ============

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

    // ============ BATCH MINTING TESTS ============

    function testBatchMint() public {
        string[] memory tokenUris = new string[](3);
        tokenUris[0] = PUG_URI;
        tokenUris[1] = PUG_URI;
        tokenUris[2] = PUG_URI;

        vm.prank(USER);
        basicNft.batchMintNft(tokenUris);
        
        assert(basicNft.balanceOf(USER) == 3);
        assert(basicNft.ownerOf(0) == USER);
        assert(basicNft.ownerOf(1) == USER);
        assert(basicNft.ownerOf(2) == USER);
    }

    function testBatchMintEmitsEvent() public {
        string[] memory tokenUris = new string[](2);
        tokenUris[0] = PUG_URI;
        tokenUris[1] = PUG_URI;

        uint256[] memory expectedTokenIds = new uint256[](2);
        expectedTokenIds[0] = 0;
        expectedTokenIds[1] = 1;

        vm.expectEmit(true, false, false, true);
        emit BasicNft.BatchMinted(USER, expectedTokenIds, tokenUris);
        
        vm.prank(USER);
        basicNft.batchMintNft(tokenUris);
    }

    function testBatchMintRevertsWithEmptyArray() public {
        string[] memory tokenUris = new string[](0);
        
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__InvalidBatchSize.selector);
        basicNft.batchMintNft(tokenUris);
    }

    function testBatchMintRevertsWithTooManyTokens() public {
        string[] memory tokenUris = new string[](51); // MAX_BATCH_SIZE is 50
        for (uint256 i = 0; i < 51; i++) {
            tokenUris[i] = PUG_URI;
        }
        
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__InvalidBatchSize.selector);
        basicNft.batchMintNft(tokenUris);
    }

    function testBatchMintRevertsWithEmptyTokenURI() public {
        string[] memory tokenUris = new string[](2);
        tokenUris[0] = PUG_URI;
        tokenUris[1] = ""; // Empty URI
        
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__EmptyTokenUri.selector);
        basicNft.batchMintNft(tokenUris);
    }

    // ============ BURN FUNCTIONALITY TESTS ============

    function testCanBurnToken() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        uint256 tokenId = 0;
        assert(basicNft.ownerOf(tokenId) == USER);
        
        vm.expectEmit(true, false, false, false);
        emit BasicNft.TokenBurned(tokenId);
        
        vm.prank(USER);
        basicNft.burn(tokenId);
        
        vm.expectRevert();
        basicNft.ownerOf(tokenId); // Should revert as token is burned
    }

    function testBurnRevertsWhenNotOwner() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        vm.prank(USER2);
        vm.expectRevert(BasicNft.BasicNft__NotOwnerOrApproved.selector);
        basicNft.burn(0);
    }

    function testBurnRevertsWhenApproved() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        vm.prank(USER);
        basicNft.approve(USER2, 0);
        
        vm.prank(USER2);
        basicNft.burn(0); // Should work when approved
    }

    // ============ WHITELIST TESTS ============

    function testWhitelistMint() public {
        vm.prank(OWNER);
        basicNft.addToWhitelist(USER);
        
        vm.prank(OWNER);
        basicNft.toggleWhitelist();
        
        vm.prank(USER);
        basicNft.whitelistMintNft(PUG_URI);
        
        assert(basicNft.balanceOf(USER) == 1);
        assert(basicNft.ownerOf(0) == USER);
    }

    function testWhitelistMintRevertsWhenNotWhitelisted() public {
        vm.prank(OWNER);
        basicNft.toggleWhitelist();
        
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__NotWhitelisted.selector);
        basicNft.whitelistMintNft(PUG_URI);
    }

    function testWhitelistMintRevertsWhenWhitelistNotActive() public {
        vm.prank(OWNER);
        basicNft.addToWhitelist(USER);
        
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__WhitelistNotActive.selector);
        basicNft.whitelistMintNft(PUG_URI);
    }

    function testWhitelistBatchMint() public {
        vm.prank(OWNER);
        basicNft.addToWhitelist(USER);
        
        vm.prank(OWNER);
        basicNft.toggleWhitelist();
        
        string[] memory tokenUris = new string[](2);
        tokenUris[0] = PUG_URI;
        tokenUris[1] = PUG_URI;
        
        vm.prank(USER);
        basicNft.whitelistBatchMintNft(tokenUris);
        
        assert(basicNft.balanceOf(USER) == 2);
    }

    function testAddToWhitelist() public {
        vm.prank(OWNER);
        basicNft.addToWhitelist(USER);
        
        assert(basicNft.isWhitelisted(USER) == true);
    }

    function testRemoveFromWhitelist() public {
        vm.prank(OWNER);
        basicNft.addToWhitelist(USER);
        assert(basicNft.isWhitelisted(USER) == true);
        
        vm.prank(OWNER);
        basicNft.removeFromWhitelist(USER);
        assert(basicNft.isWhitelisted(USER) == false);
    }

    function testBatchAddToWhitelist() public {
        address[] memory accounts = new address[](2);
        accounts[0] = USER;
        accounts[1] = USER2;
        
        vm.prank(OWNER);
        basicNft.batchAddToWhitelist(accounts);
        
        assert(basicNft.isWhitelisted(USER) == true);
        assert(basicNft.isWhitelisted(USER2) == true);
    }

    function testBatchRemoveFromWhitelist() public {
        address[] memory accounts = new address[](2);
        accounts[0] = USER;
        accounts[1] = USER2;
        
        vm.prank(OWNER);
        basicNft.batchAddToWhitelist(accounts);
        
        vm.prank(OWNER);
        basicNft.batchRemoveFromWhitelist(accounts);
        
        assert(basicNft.isWhitelisted(USER) == false);
        assert(basicNft.isWhitelisted(USER2) == false);
    }

    function testToggleWhitelist() public {
        assert(basicNft.isWhitelistActive() == false);
        
        vm.prank(OWNER);
        basicNft.toggleWhitelist();
        assert(basicNft.isWhitelistActive() == true);
        
        vm.prank(OWNER);
        basicNft.toggleWhitelist();
        assert(basicNft.isWhitelistActive() == false);
    }

    function testTogglePublicMinting() public {
        assert(basicNft.isPublicMintingActive() == true);
        
        vm.prank(OWNER);
        basicNft.togglePublicMinting();
        assert(basicNft.isPublicMintingActive() == false);
        
        vm.prank(OWNER);
        basicNft.togglePublicMinting();
        assert(basicNft.isPublicMintingActive() == true);
    }

    function testPublicMintRevertsWhenDisabled() public {
        vm.prank(OWNER);
        basicNft.togglePublicMinting();
        
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__WhitelistNotActive.selector);
        basicNft.mintNft(PUG_URI);
    }

    // ============ PAUSE FUNCTIONALITY TESTS ============

    function testPause() public {
        vm.prank(OWNER);
        basicNft.pause();
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.mintNft(PUG_URI);
    }

    function testUnpause() public {
        vm.prank(OWNER);
        basicNft.pause();
        
        vm.prank(OWNER);
        basicNft.unpause();
        
        vm.prank(USER);
        basicNft.mintNft(PUG_URI); // Should work now
        assert(basicNft.balanceOf(USER) == 1);
    }

    function testPauseRevertsWhenNotOwner() public {
        vm.prank(USER);
        vm.expectRevert();
        basicNft.pause();
    }

    function testUnpauseRevertsWhenNotOwner() public {
        vm.prank(OWNER);
        basicNft.pause();
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.unpause();
    }

    // ============ ROYALTY TESTS ============

    function testDefaultRoyalty() public {
        (address receiver, uint256 royaltyAmount) = basicNft.royaltyInfo(0, 10000);
        assert(receiver == OWNER);
        assert(royaltyAmount == 250); // 2.5% of 10000
    }

    function testSetDefaultRoyalty() public {
        vm.prank(OWNER);
        basicNft.setDefaultRoyalty(USER, 500); // 5%
        
        (address receiver, uint256 royaltyAmount) = basicNft.royaltyInfo(0, 10000);
        assert(receiver == USER);
        assert(royaltyAmount == 500);
    }

    function testSetTokenRoyalty() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        vm.prank(OWNER);
        basicNft.setTokenRoyalty(0, USER2, 1000); // 10%
        
        (address receiver, uint256 royaltyAmount) = basicNft.royaltyInfo(0, 10000);
        assert(receiver == USER2);
        assert(royaltyAmount == 1000);
    }

    function testDeleteDefaultRoyalty() public {
        vm.prank(OWNER);
        basicNft.deleteDefaultRoyalty();
        
        (address receiver, uint256 royaltyAmount) = basicNft.royaltyInfo(0, 10000);
        assert(receiver == address(0));
        assert(royaltyAmount == 0);
    }

    function testResetTokenRoyalty() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        vm.prank(OWNER);
        basicNft.setTokenRoyalty(0, USER2, 1000);
        
        vm.prank(OWNER);
        basicNft.resetTokenRoyalty(0);
        
        (address receiver, uint256 royaltyAmount) = basicNft.royaltyInfo(0, 10000);
        assert(receiver == OWNER); // Should revert to default
        assert(royaltyAmount == 250);
    }

    function testRoyaltyRevertsWhenNotOwner() public {
        vm.prank(USER);
        vm.expectRevert();
        basicNft.setDefaultRoyalty(USER, 500);
    }

    // ============ METADATA VALIDATION TESTS ============

    function testValidateValidJsonMetadata() public {
        bool isValid = basicNft.validateMetadata(VALID_JSON_URI);
        assert(isValid == true);
    }

    function testValidateInvalidJsonMetadata() public {
        bool isValid = basicNft.validateMetadata(INVALID_JSON_URI);
        assert(isValid == false);
    }

    function testValidateMalformedJsonMetadata() public {
        bool isValid = basicNft.validateMetadata(MALFORMED_JSON_URI);
        assert(isValid == false);
    }

    function testValidateEmptyMetadata() public {
        bool isValid = basicNft.validateMetadata("");
        assert(isValid == false);
    }

    function testMintWithValidJsonMetadata() public {
        vm.prank(USER);
        basicNft.mintNft(VALID_JSON_URI);
        
        assert(basicNft.balanceOf(USER) == 1);
        assert(keccak256(abi.encodePacked(basicNft.tokenURI(0))) == keccak256(abi.encodePacked(VALID_JSON_URI)));
    }

    function testMintWithInvalidJsonMetadataReverts() public {
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__InvalidJsonMetadata.selector);
        basicNft.mintNft(INVALID_JSON_URI);
    }

    function testMintWithMalformedJsonMetadataReverts() public {
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__InvalidJsonMetadata.selector);
        basicNft.mintNft(MALFORMED_JSON_URI);
    }

    function testBatchMintWithMixedMetadata() public {
        string[] memory tokenUris = new string[](3);
        tokenUris[0] = PUG_URI; // Non-JSON, should pass
        tokenUris[1] = VALID_JSON_URI; // Valid JSON, should pass
        tokenUris[2] = PUG_URI; // Non-JSON, should pass
        
        vm.prank(USER);
        basicNft.batchMintNft(tokenUris);
        
        assert(basicNft.balanceOf(USER) == 3);
    }

    function testBatchMintWithInvalidJsonReverts() public {
        string[] memory tokenUris = new string[](2);
        tokenUris[0] = VALID_JSON_URI; // Valid JSON, should pass
        tokenUris[1] = INVALID_JSON_URI; // Invalid JSON, should revert
        
        vm.prank(USER);
        vm.expectRevert(BasicNft.BasicNft__InvalidJsonMetadata.selector);
        basicNft.batchMintNft(tokenUris);
    }

    // ============ VIEW FUNCTION TESTS ============

    function testGetTokenCounter() public {
        assert(basicNft.getTokenCounter() == 0);
        
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(basicNft.getTokenCounter() == 1);
        
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(basicNft.getTokenCounter() == 2);
    }

    function testGetTokenUri() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        assert(keccak256(abi.encodePacked(basicNft.getTokenUri(0))) == keccak256(abi.encodePacked(PUG_URI)));
    }

    function testTokenURIRevertsForInvalidTokenId() public {
        vm.expectRevert();
        basicNft.tokenURI(999);
    }

    // ============ ACCESS CONTROL TESTS ============

    function testWhitelistFunctionsRevertWhenNotOwner() public {
        vm.prank(USER);
        vm.expectRevert();
        basicNft.addToWhitelist(USER2);
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.removeFromWhitelist(USER2);
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.toggleWhitelist();
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.togglePublicMinting();
    }

    function testRoyaltyFunctionsRevertWhenNotOwner() public {
        vm.prank(USER);
        vm.expectRevert();
        basicNft.setDefaultRoyalty(USER, 500);
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.setTokenRoyalty(0, USER, 500);
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.deleteDefaultRoyalty();
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.resetTokenRoyalty(0);
    }

    // ============ EDGE CASE TESTS ============

    function testMintAfterBurn() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        vm.prank(USER);
        basicNft.burn(0);
        
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        
        assert(basicNft.balanceOf(USER) == 1);
        assert(basicNft.ownerOf(1) == USER); // Next token ID is 1
    }

    function testBatchMintAfterPause() public {
        vm.prank(OWNER);
        basicNft.pause();
        
        string[] memory tokenUris = new string[](2);
        tokenUris[0] = PUG_URI;
        tokenUris[1] = PUG_URI;
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.batchMintNft(tokenUris);
    }

    function testWhitelistBatchMintAfterPause() public {
        vm.prank(OWNER);
        basicNft.addToWhitelist(USER);
        
        vm.prank(OWNER);
        basicNft.toggleWhitelist();
        
        vm.prank(OWNER);
        basicNft.pause();
        
        string[] memory tokenUris = new string[](2);
        tokenUris[0] = PUG_URI;
        tokenUris[1] = PUG_URI;
        
        vm.prank(USER);
        vm.expectRevert();
        basicNft.whitelistBatchMintNft(tokenUris);
    }
}
