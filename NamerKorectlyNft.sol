// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NamerKorectlyToken is ERC721 {
    address public immutable owner;

    using Counters for Counters.Counter;
    Counters.Counter private totalMints; // stores tokens that have been minted so far. Can only be incremented.

    uint256 public mintPrice = 1 ether; // 0.001 ether is about $2 as of 20-Apr-2023
    uint256 public maxSupply = 999999999999; // Total supply enough to cover everyone. World population today is < 8billion
    uint256 public maxPerWallet = 10; // Every wallet ideally should own one NamerKorectly NFT and to make updates (corrections) pay little fee to the owner

    struct WhoAmI {
        uint256 tokenId;
        address firstOwner;
        string firstName;
        string middleName;
        string lastName;
        string image; // image metadata URI
        string audio; // audio pronunciation metadata URI
    }
    // Define mapping: each token is mapped to a humans. In other words, every human can own one or more tokens depending on 'maxPerWallet' value
    mapping(uint256 => WhoAmI) public humans;

    // Define map storage for addresses mapped to NamerKorectlyToken ids. Also used to enforce limit mints per wallet.
    mapping(address => uint256) public walletMints;

    /** 
    * Constructor call to openzeppelin ERC721 parent contract's constructor to initialize the inherited state from ERC721 with ERC721("TokenName", "TKNSYMBL")
    */
    constructor() ERC721("NamerKorectlyToken", "MTK") {
        owner = msg.sender;
    }

    /**
    * This is the main function to mint NFTs.
    * Payable function which also enforces maxPerWallet, mintPrice & maxSupply conditions are respected by minters.
    * The frontend GUI (optionally) stores user Image and Audio recording onto IPFS, and metadata is passed to this function.
    * For example files are uploaded on IPFS https://web3.storage/ and example metadataURI is :
    * https://bafybeifqmgyfy4by3gpms5sdv3ft3knccmjsqxfqquuxemohtwfm7y7nwa.ipfs.dweb.link/metadata.json
    * or https://bafybeibc3di6g356tyr4nk73o72ahvsjpc4ygoi742yl55vcxhjh25xn6a.ipfs.dweb.link/
    */
    function mintToken(string memory _firstName, string memory _middleName, string memory _lastName, string memory _image, string memory _audio) public payable {
        
        if(walletMints[msg.sender] + 1 > maxPerWallet || mintPrice != msg.value || mintPrice < 0) {
            emit nftPurchaseFailed(msg.sender, "Wrong amount OR mints limit exceeded!");
        }
        // ensure maxPerWallet limit is respected by users
        require(walletMints[msg.sender] < maxPerWallet, "mints per wallet exceeded");
        // ensure users are paying the exact NFT price in ethers (mintPrice * 1)
        require(mintPrice == msg.value && mintPrice >= 0, "Wrong amount sent, please send exact NFT price in ether");
        walletMints[msg.sender] += 1;

        // mint the NFT to caller
        safeMint(msg.sender, _firstName, _middleName, _lastName, _image, _audio);
    }

    /** Function to safely mint NFT to given address. Marked as 'internal' so it can't be invoked outside the 'NamerKorectlyToken' smart contract */
    function safeMint(address _to, string memory _firstName, string memory _middleName, string memory _lastName, string memory _image, string memory _audio) internal {
        
        uint256 tokenId = totalMints.current();
        totalMints.increment();

        humans[tokenId] = WhoAmI({
            tokenId: tokenId,
            firstOwner: _to,
            firstName: _firstName, 
            middleName: _middleName, 
            lastName: _lastName, 
            image: _image, 
            audio: _audio
        });
        
        // invoke ERC721's _safeMint to mints/assigns the 'tokenID' to an address & that it's not owned by anyone else
        _safeMint(_to, tokenId);
        emit nftPurchased(_to);
    }

    /** 
    * This is another important function. Similar to mintToken(), but provides NFT transfer functionality
    */
    function transferMintToken(address _recipient) public payable {
        // ensure sender has the NFT, and recipient did not exceed their limits
        require(walletMints[msg.sender] >= 1, "Insufficient tokens");
        require(walletMints[_recipient] < maxPerWallet, "Recipient can't exceed maximum allowed limit");

        walletMints[msg.sender] -= 1;
        walletMints[_recipient] += 1;
        // transfer the NFT
        safeMintTransfer(_recipient);
        emit nftTransferred(msg.sender, _recipient);
    }

    /** Function to safely transfer. Marked as 'internal' so it can't be invoked explicitly */
    function safeMintTransfer(address _to) internal {
        // invoke ERC721's safeTransferFrom to transfer the 'tokenID'
        safeTransferFrom(msg.sender, _to, walletMints[msg.sender]);
    }

    /***
    * This is another important function. If someone wish to invalidate their NFT for whatever reason (such as going off social media).
    * TODO: This function is futuristic to delinks image and audio from the NFT
    */
    function unmintMyMints() public view returns (uint256) {
        return walletMints[msg.sender];
    }

    /**
    * Return caller's NamerKorectlyToken. If user owns multiple NFTs, it returns the last one minted NFT. To get specific token use "getAnyMints(_tokenId)" function
    */
    function getMyWalletMints() public view returns (WhoAmI memory) {
        return humans[walletMints[msg.sender]];
    }

    /** Return anybody's NamerKorectlyToken */
    function getAnyMints(uint256 _tokenId) public view returns (WhoAmI memory) {
        return humans[_tokenId];
    }

    function getTotalNftsMinted() public view returns (uint256) {
        return totalMints.current();
    }

    /** Transfer contract's ethers to owner. Only owner can take this action. */
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
        emit withdrawalSuccess(msg.sender, "NamerKorectly NFT bank emptied & ethers sent to the owner");
    }

    /** Owner can view contract balance */
    function getBalance() public onlyOwner view returns (uint) {
        return address(this).balance;
    }
    
    /** Owner can change mintPrice */
    function updateMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    /** Owner can change maxPerWallet limit */
    function changeWalletLimit(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }
    
    receive() external payable {
        emit charity(msg.sender, "Hurray, you have got a donation :) ");
    }

    fallback() external payable {
        emit charity(msg.sender, "Hurray, you have got a donation :) ");
    }

    event nftPurchased(address purchasor);
    event nftPurchaseFailed(address who, string cause);
    event nftTransferred(address sender, address recipient);
    event withdrawalSuccess(address who, string value);
    event withdrawalFailed(address who, uint value, string cause);
    event charity(address sender, string msg);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

}
