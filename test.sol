// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract NamerKorectlyToken {

    uint256 public totalMints = 0;
    uint256 public maxPerWallet = 2;
    mapping(address => uint256) public walletMints;

    function testing() public {
        emit test1(walletMints[msg.sender]);
        if(walletMints[msg.sender] + 1 > maxPerWallet) {
            emit test1(walletMints[msg.sender]);
        }
        
        walletMints[msg.sender] += 1;
        emit test1(walletMints[msg.sender]);
    }

    event test1(uint256);
    event test2();
}