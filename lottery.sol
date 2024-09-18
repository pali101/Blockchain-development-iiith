// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Lottery {
    address public owner;
    address[] public players;
    uint16 public maxInput;
    uint64 public maxPlayers;
    uint64 ticketPrice = 0.01 ether;

    // Custom error to notify the user about the incorrect ticket price and sending correct ticket price back
    error IncorrectTicketPrice(uint256 sentAmount, uint256 requiredAmount);

    // Event to log the bet placed by a player
    event BetPlaced(address indexed player, uint16 predictedNumber);

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

    constructor(
        uint16 _maxInput,
        uint64 _maxPlayers,
        uint64 _ticketPrice
    ) payable {
        owner = msg.sender;
        maxInput = _maxInput;
        maxPlayers = _maxPlayers;
        ticketPrice = _ticketPrice;
    }

    // Function to place a bet
    function placeBet(uint16 _predictedNumber) public payable {
        // require(msg.value == ticketPrice, "Incorrect ticket price");

        if (msg.value != ticketPrice) {
            revert IncorrectTicketPrice(msg.value, ticketPrice);
        }

        require(
            players.length < maxPlayers,
            "Max number of players reached. Try again later"
        );
        require(
            _predictedNumber >= 0 && _predictedNumber <= maxInput,
            "Predicted number should be between 0 and maxInput"
        );

        players.push(msg.sender);
        emit BetPlaced(msg.sender, _predictedNumber);
    }
}
