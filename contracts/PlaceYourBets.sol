// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PlaceYourBets {

    struct BetPool {
        string title;
        string description;
        string choice1;
        string choice2;
        BetStatus status;
        // assume even 1:1 odds for now
        // have a set bet amount for now
        uint256 bet_amount;
        uint256 total_pot;
        uint8 winning_option; // 1 or 2
        mapping(address => Bet) bets;
    }

    struct Bet {
        address bettor_addr;
        uint256 amount;
        uint8 choice; // must be 1 or 2
    }

    // errors
    error BET_AMOUNT_MUST_BE_GREATER_THAN_ZERO();

    mapping(uint256 => BetPool) public pools;
    uint256 pool_count;

    enum BetStatus {
        OPEN,
        IN_PROGRESS,
        COMPLETED
    }

    function createPool(string memory title, string memory description, string memory choice1, string memory choice2, uint256 bet_amount) public {
        // check 
        uint256 fixed_bet_amount;
        if (bet_amount > 0){
            fixed_bet_amount = bet_amount;
        } else {
            revert BET_AMOUNT_MUST_BE_GREATER_THAN_ZERO();
        }
        // create a new pool and add it to the pools
        
        // require whitelisted accounts?
        
    }

    // function createBet(){}
    
    // function availableBets(){}
    // function getBetDetails(){}
    // function getBetStatus(){}
}