// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "hardhat/console.sol";

contract PlaceYourBets {
    struct BetPool {
        address creator;
        string title;
        string description;
        string choice1;
        string choice2;
        BetStatus status;
        // assume even 1:1 odds for now
        // have a set bet amount for now
        uint256 betAmount;
        uint256 totalPot;
        uint8 winningOption; // 1 or 2
        address[] choice1Bets;
        address[] choice2Bets;
    }

    struct Bet {
        address bettor_addr;
        uint256 amount;
        uint8 choice; // must be 1 or 2
    }

    // errors
    error BET_AMOUNT_MUST_BE_GREATER_THAN_ZERO();

    /* state variables */
    mapping(uint256 => BetPool) public pools;
    uint256 pool_count;

    enum BetStatus {
        OPEN,
        IN_PROGRESS,
        COMPLETED
    }

    /* events */
    event PoolCreated(address indexed creator);

    function createBetPool(
        string memory _title,
        string memory _description,
        string memory _choice1,
        string memory _choice2,
        uint256 _betAmount
    ) public {
        if (_betAmount <= 0) {
            revert BET_AMOUNT_MUST_BE_GREATER_THAN_ZERO();
        }
        BetPool memory newPool = BetPool(msg.sender, _title, _description, _choice1, _choice2, BetStatus.OPEN, _betAmount, 0, 0, new address[](0), new address[](0));

        pools[pool_count] = newPool;
        pool_count++;

        emit PoolCreated(msg.sender);
    }

    // function createBet(){}

    // function availableBets(){}
    // function getBetDetails(){}
    // function getBetStatus(){}
}
