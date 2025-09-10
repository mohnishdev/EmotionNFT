// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721 {
    error BasicNft__EmptyTokenUri();
    
    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_tokenIdToUri;

    constructor() ERC721("Dogie", "DOG"){
        s_tokenCounter = 0;
    }

    function mintNft(string memory tokenUri) public {
        if (bytes(tokenUri).length == 0) {
            revert BasicNft__EmptyTokenUri();
        }
        
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        unchecked {
            s_tokenCounter++;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return s_tokenIdToUri[tokenId];
    }
}