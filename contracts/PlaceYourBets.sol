// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PlaceYourBets {

    struct BetPool {
        string title;
        string description;
        uint256 choice1;
        uint256 choice2;
        BET_STATUS status;
        // assume even 1:1 odds for now
        uint256 min_buy_in;
    }

    struct Bet {
        address addr;
        uint256 bet_amount;
        
    }

    enum BET_STATUS {
        CREATED,
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