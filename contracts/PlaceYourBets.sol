// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PlaceYourBets {

    struct BetPool {
        string title;
        string description;
        string choice1;
        string choice2;
        BET_STATUS status;
        // assume even 1:1 odds for now
        // have a set bet amount for now
        uint256 bet_amount;
        uint8 winning_option; // 1 or 2
        mapping(address => Bet) bets;
    }

    struct Bet {
        address bettor_addr;
        uint256 amount;
        uint8 choice; // must be 1 or 2
    }

    mapping(uint256 => BetPool) public pools;
    uint256 pool_count;

    enum BET_STATUS {
        OPEN,
        IN_PROGRESS,
        COMPLETED,
    }

    function createBet(){}
    function takeBet(){}
    // views 
    function availableBets(){}
    function getBetDetails(){}
    function getBetStatus(){}
}