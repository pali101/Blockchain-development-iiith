// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Lottery {
    address public owner;
    uint16 public maxInput;
    uint64 public maxPlayers;
    uint64 ticketPrice;
    uint256 public endTime;
    bool public lotteryEnded;
    // Keep track of all participants
    address[] public players;
    // Keep track of prediction of each player
    mapping(address => uint16) public playerPredictions;
    // Keep track of winners
    address[] public winners;

    // Custom error to notify the user about the incorrect ticket price and sending correct ticket price info
    error IncorrectTicketPrice(uint256 sentAmount, uint256 requiredAmount);
    error LotteryNotEnded(uint256 endTime, uint256 remainingTime);

    // Event to log the bet placed by a player
    event BetPlaced(address indexed player, uint16 predictedNumber);

    // Event to log the winner of the lottery
    event WinnerDecided(
        address[] winner,
        uint16 winningNumber,
        uint256 winningPrize
    );

    // Modifier - only owner can call the function
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        uint16 _maxInput,
        uint64 _maxPlayers,
        uint64 _ticketPrice,
        uint256 _duration
    ) payable {
        owner = msg.sender;
        maxInput = _maxInput;
        maxPlayers = _maxPlayers;
        ticketPrice = _ticketPrice;
        endTime = block.timestamp + _duration;
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

        // add player to the list of players and store their prediction
        players.push(msg.sender);
        playerPredictions[msg.sender] = _predictedNumber;
        emit BetPlaced(msg.sender, _predictedNumber);
    }

    // Function to end the lottery and decide the winner
    function endLottery() public {
        if (block.timestamp < endTime) {
            revert LotteryNotEnded(endTime, endTime - block.timestamp);
        }

        require(!lotteryEnded, "Lottery already ended and winner picked");
        require(players.length > 0, "No players participated in the lottery");

        uint16 winningNumber = getRandomInt();
        uint256 totalPot = address(this).balance;
        uint256 callerReward = totalPot / 100;
        uint256 winnersReward = totalPot - callerReward;

        for (uint256 i = 0; i < players.length; i++) {
            if (playerPredictions[players[i]] == winningNumber) {
                winners.push(players[i]);
            }
        }

        lotteryEnded = true;
        payWinners(msg.sender, winnersReward, callerReward);
        emit WinnerDecided(winners, winningNumber, winnersReward);
    }

    function payWinners(
        address caller,
        uint256 winnersReward,
        uint256 callerReward
    ) private {
        if (winners.length > 0) {
            uint256 individualReward = winnersReward / winners.length;
            for (uint256 i = 0; i < winners.length; i++) {
                payable(winners[i]).transfer(individualReward);
            }
        }
        payable(caller).transfer(callerReward);
    }

    // Function to calculate random value
    function getRandomInt() private view returns (uint16) {
        // Using a simple random number generation logic for demo - THIS IS NOT SECURE
        // to use in production - utilize Chainlink VRF, drand or other secure random number generation services
        uint16 random = uint16(
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        msg.sender
                    )
                )
            ) % maxInput) + 1
        );

        return random;
    }
}
