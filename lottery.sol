// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Lottery {
    address public owner;
    address[] public players;
    uint16 public maxInput;
    uint256 public maxPlayers;

    // Event to log the bet placed by a player
    event BetPlaced(
        address indexed player,
        uint256 amount,
        uint16 predictedNumber
    );

    // Event to log the winner of the lottery
    event WinnerDecided(
        address indexed winner,
        uint16 winningNumber,
        uint256 amount
    );

    // Modifier - only owner can call the function
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(uint16 _maxInput, uint256 _maxPlayers) payable {
        maxInput = _maxInput;
        maxPlayers = _maxPlayers;
    }
}
