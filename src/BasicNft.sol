// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract BasicNft is ERC721, Ownable, Pausable, ERC2981 {
    using Strings for uint256;
    
    // Errors
    error BasicNft__EmptyTokenUri();
    error BasicNft__InvalidTokenId();
    error BasicNft__NotOwnerOrApproved();
    error BasicNft__NotWhitelisted();
    error BasicNft__InvalidJsonMetadata();
    error BasicNft__WhitelistNotActive();
    error BasicNft__WhitelistActive();
    error BasicNft__InvalidBatchSize();
    error BasicNft__ArrayLengthMismatch();
    
    // State variables
    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_tokenIdToUri;
    mapping(address => bool) private s_whitelist;
    bool private s_whitelistActive;
    bool private s_publicMintingActive;
    
    // Events
    event BatchMinted(address indexed to, uint256[] tokenIds, string[] tokenUris);
    event TokenBurned(uint256 indexed tokenId);
    event WhitelistUpdated(address indexed account, bool status);
    event WhitelistToggled(bool active);
    event PublicMintingToggled(bool active);
    event MetadataValidated(uint256 indexed tokenId, bool isValid);
    
    // Constants
    uint256 public constant MAX_BATCH_SIZE = 50;
    uint96 public constant DEFAULT_ROYALTY_FEE = 250; // 2.5% (250/10000)
    
    constructor() ERC721("Dogie", "DOG") Ownable(msg.sender) {
        s_tokenCounter = 0;
        s_whitelistActive = false;
        s_publicMintingActive = true;
        
        // Set default royalty to contract owner (2.5%)
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTY_FEE);
    }

    // ============ MINTING FUNCTIONS ============
    
    function mintNft(string memory tokenUri) public whenNotPaused {
        if (!s_publicMintingActive) {
            revert BasicNft__WhitelistNotActive();
        }
        _mintSingle(msg.sender, tokenUri);
    }
    
    function whitelistMintNft(string memory tokenUri) public whenNotPaused {
        if (!s_whitelistActive) {
            revert BasicNft__WhitelistNotActive();
        }
        if (!s_whitelist[msg.sender]) {
            revert BasicNft__NotWhitelisted();
        }
        _mintSingle(msg.sender, tokenUri);
    }
    
    function batchMintNft(string[] memory tokenUris) public whenNotPaused {
        if (!s_publicMintingActive) {
            revert BasicNft__WhitelistNotActive();
        }
        _batchMint(msg.sender, tokenUris);
    }
    
    function whitelistBatchMintNft(string[] memory tokenUris) public whenNotPaused {
        if (!s_whitelistActive) {
            revert BasicNft__WhitelistNotActive();
        }
        if (!s_whitelist[msg.sender]) {
            revert BasicNft__NotWhitelisted();
        }
        _batchMint(msg.sender, tokenUris);
    }
    
    // ============ BURN FUNCTIONALITY ============
    
    function burn(uint256 tokenId) public {
        if (!_isAuthorized(ownerOf(tokenId), msg.sender, tokenId)) {
            revert BasicNft__NotOwnerOrApproved();
        }
        
        delete s_tokenIdToUri[tokenId];
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }
    
    // ============ WHITELIST MANAGEMENT ============
    
    function addToWhitelist(address account) public onlyOwner {
        s_whitelist[account] = true;
        emit WhitelistUpdated(account, true);
    }
    
    function removeFromWhitelist(address account) public onlyOwner {
        s_whitelist[account] = false;
        emit WhitelistUpdated(account, false);
    }
    
    function batchAddToWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            s_whitelist[accounts[i]] = true;
            emit WhitelistUpdated(accounts[i], true);
        }
    }
    
    function batchRemoveFromWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            s_whitelist[accounts[i]] = false;
            emit WhitelistUpdated(accounts[i], false);
        }
    }
    
    function toggleWhitelist() public onlyOwner {
        s_whitelistActive = !s_whitelistActive;
        emit WhitelistToggled(s_whitelistActive);
    }
    
    function togglePublicMinting() public onlyOwner {
        s_publicMintingActive = !s_publicMintingActive;
        emit PublicMintingToggled(s_publicMintingActive);
    }
    
    // ============ PAUSE FUNCTIONALITY ============
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // ============ ROYALTY FUNCTIONALITY ============
    
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    
    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }
    
    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
    
    // ============ METADATA VALIDATION ============
    
    function validateMetadata(string memory tokenUri) public pure returns (bool) {
        bytes memory data = bytes(tokenUri);
        if (data.length == 0) return false;
        
        // Basic JSON structure validation
        string memory trimmed = _trim(tokenUri);
        bytes memory trimmedBytes = bytes(trimmed);
        
        // Check if it starts with { and ends with }
        if (trimmedBytes[0] != '{' || trimmedBytes[trimmedBytes.length - 1] != '}') {
            return false;
        }
        
        // Check for required JSON fields (basic validation)
        string memory lowerUri = _toLowerCase(tokenUri);
        bool hasName = _contains(lowerUri, '"name"');
        bool hasDescription = _contains(lowerUri, '"description"');
        bool hasImage = _contains(lowerUri, '"image"');
        
        return hasName && hasDescription && hasImage;
    }
    
    // ============ VIEW FUNCTIONS ============
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert BasicNft__InvalidTokenId();
        }
        return s_tokenIdToUri[tokenId];
    }
    
    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
    
    function isWhitelisted(address account) public view returns (bool) {
        return s_whitelist[account];
    }
    
    function isWhitelistActive() public view returns (bool) {
        return s_whitelistActive;
    }
    
    function isPublicMintingActive() public view returns (bool) {
        return s_publicMintingActive;
    }
    
    function getTokenUri(uint256 tokenId) public view returns (string memory) {
        return s_tokenIdToUri[tokenId];
    }
    
    // ============ INTERNAL FUNCTIONS ============
    
    function _mintSingle(address to, string memory tokenUri) internal {
        if (bytes(tokenUri).length == 0) {
            revert BasicNft__EmptyTokenUri();
        }
        
        // Validate metadata if it's a JSON string
        if (_isJsonUri(tokenUri)) {
            bool isValid = validateMetadata(tokenUri);
            emit MetadataValidated(s_tokenCounter, isValid);
            if (!isValid) {
                revert BasicNft__InvalidJsonMetadata();
            }
        }
        
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(to, s_tokenCounter);
        unchecked {
            s_tokenCounter++;
        }
    }
    
    function _batchMint(address to, string[] memory tokenUris) internal {
        if (tokenUris.length == 0) {
            revert BasicNft__InvalidBatchSize();
        }
        if (tokenUris.length > MAX_BATCH_SIZE) {
            revert BasicNft__InvalidBatchSize();
        }
        
        uint256[] memory tokenIds = new uint256[](tokenUris.length);
        
        for (uint256 i = 0; i < tokenUris.length; i++) {
            if (bytes(tokenUris[i]).length == 0) {
                revert BasicNft__EmptyTokenUri();
            }
            
            // Validate metadata if it's a JSON string
            if (_isJsonUri(tokenUris[i])) {
                bool isValid = validateMetadata(tokenUris[i]);
                emit MetadataValidated(s_tokenCounter, isValid);
                if (!isValid) {
                    revert BasicNft__InvalidJsonMetadata();
                }
            }
            
            tokenIds[i] = s_tokenCounter;
            s_tokenIdToUri[s_tokenCounter] = tokenUris[i];
            _safeMint(to, s_tokenCounter);
            unchecked {
                s_tokenCounter++;
            }
        }
        
        emit BatchMinted(to, tokenIds, tokenUris);
    }
    
    function _isJsonUri(string memory uri) internal pure returns (bool) {
        bytes memory data = bytes(uri);
        if (data.length == 0) return false;
        
        // Check if it looks like JSON (starts with { or [)
        return data[0] == '{' || data[0] == '[';
    }
    
    function _trim(string memory str) internal pure returns (string memory) {
        bytes memory data = bytes(str);
        uint256 start = 0;
        uint256 end = data.length;
        
        // Find first non-whitespace character
        while (start < end && (data[start] == ' ' || data[start] == '\t' || data[start] == '\n' || data[start] == '\r')) {
            start++;
        }
        
        // Find last non-whitespace character
        while (end > start && (data[end - 1] == ' ' || data[end - 1] == '\t' || data[end - 1] == '\n' || data[end - 1] == '\r')) {
            end--;
        }
        
        bytes memory result = new bytes(end - start);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = data[start + i];
        }
        
        return string(result);
    }
    
    function _toLowerCase(string memory str) internal pure returns (string memory) {
        bytes memory data = bytes(str);
        bytes memory result = new bytes(data.length);
        
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] >= 'A' && data[i] <= 'Z') {
                result[i] = bytes1(uint8(data[i]) + 32);
            } else {
                result[i] = data[i];
            }
        }
        
        return string(result);
    }
    
    function _contains(string memory str, string memory substr) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory substrBytes = bytes(substr);
        
        if (substrBytes.length > strBytes.length) return false;
        
        for (uint256 i = 0; i <= strBytes.length - substrBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < substrBytes.length; j++) {
                if (strBytes[i + j] != substrBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        
        return false;
    }
    
    // ============ OVERRIDES ============
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }
}