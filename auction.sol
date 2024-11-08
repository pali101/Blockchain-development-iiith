// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Auction is ReentrancyGuard {
    address payable public owner;
    uint256 public startBlock;
    uint256 public endBlock;

    enum State {
        Started,
        Running,
        Ended,
        Canceled
    }
    State public auctionState;

    uint256 public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint256) public bids;
    uint256 public bidIncrement;

    constructor(uint256 _bidIncrement, uint256 _auctionDuration) {
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + _auctionDuration;
        bidIncrement = _bidIncrement;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this");
        _;
    }

    modifier onlyBidder() {
        require(msg.sender != owner, "Owner is not allowed to bid");
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a < b) ? a : b;
    }

    function placeBid() public payable onlyBidder {
        require(block.number >= startBlock, "Auction hasn't started yet");
        require(block.number < endBlock, "Auction has already ended");
        require(auctionState == State.Running, "Auction is not running");
        require(msg.value >= 0.001 ether, "Require at least 0.001 ETH");

        uint256 currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "Insufficient bid amount");

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(
                currentBid + bidIncrement,
                bids[highestBidder]
            );
        } else {
            highestBindingBid = min(
                currentBid,
                bids[highestBidder] + bidIncrement
            );
            highestBidder = payable(msg.sender);
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function finalizeAuction() public nonReentrant {
        require(
            auctionState == State.Canceled || block.number > endBlock,
            "Auction not yet ended or canceled"
        );
        require(
            msg.sender == owner || bids[msg.sender] > 0,
            "You have no funds to withdraw"
        );

        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if (msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;
            } else if (msg.sender == highestBidder) {
                recipient = highestBidder;
                value = bids[highestBidder] - highestBindingBid;
            } else {
                recipient = payable(msg.sender);
                value = bids[msg.sender];
            }
        }

        bids[recipient] = 0;
        (bool success, ) = recipient.call{value: value}("");
        require(success, "Transfer failed");
    }
}
