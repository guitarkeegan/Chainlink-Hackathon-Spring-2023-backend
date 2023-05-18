// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PlaceYourBets {

    struct Bet {
        title: string,
        description: string,
        choice1: string,
        choince2: string,
        status: BET_STATUS,
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