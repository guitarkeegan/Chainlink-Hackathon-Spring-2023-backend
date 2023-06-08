// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract PlaceYourBets is AutomationCompatibleInterface {
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

    // errors
    error PlaceYourBets__BetAmountMustBeGreaterThanZero();
    error PlaceYourBets__BetNotEqualToBetPoolAmount();
    error PlaceYourBets__Choose1Or2();
    error PlaceYourBets__PoolNotOpen();
    error PlaceYourBets__UpkeepNotNeeded();
    error PlaceYourBets__NotOwner();
    error PlaceYourBets__BetInProgress();
    error PlaceYourBets__TransferFailed();
    error PlaceYourBets__WinnerNotChosen();
    error PlaceYourBets__PoolNotCompleted();
    error PlaceYourBets__NotPoolOwner();
    /* state variables */
    BetPool s_betPool;
    BetPool[] s_pastBets;

    enum BetStatus {
        NO_BET,
        OPEN,
        IN_PROGRESS,
        COMPLETED
    }

    /* events */
    event PoolCreated(address indexed creator);
    event BetPlaced(address indexed bettor);
    event WinnerSelected(uint8 indexed winningChoice);
    address i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert PlaceYourBets__NotOwner();
        _;
    }

    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert PlaceYourBets__UpkeepNotNeeded();
        }
        uint8 winningChoice = s_betPool.winningOption;
        if (winningChoice != 0) {
            BetPool memory completedPool = s_betPool;
            if (winningChoice == 1) {
                uint256 numOfWinners = completedPool.choice1Bets.length;
                for (uint256 i = 0; i < completedPool.choice1Bets.length; i++) {
                    (bool success, ) = completedPool.choice1Bets[i].call{
                        value: completedPool.totalPot / numOfWinners
                    }("");
                    if (!success) {
                        revert PlaceYourBets__TransferFailed();
                    }
                }
                s_betPool.status = BetStatus.COMPLETED;
                resetBetPool();
            } else {
                uint256 numOfWinners = completedPool.choice2Bets.length;
                for (uint256 i = 0; i < completedPool.choice2Bets.length; i++) {
                    (bool success, ) = completedPool.choice2Bets[i].call{
                        value: completedPool.totalPot / numOfWinners
                    }("");
                    if (!success) {
                        revert PlaceYourBets__TransferFailed();
                    }
                }
                s_betPool.status = BetStatus.COMPLETED;
                resetBetPool();
            }
        } else {
            revert PlaceYourBets__WinnerNotChosen();
        }
    }

    function checkUpkeep(
        bytes memory
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory )
    {
        BetPool memory curBet = s_betPool;
        if (curBet.winningOption > 0 ) {
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;
        }
    }

    function createBetPool(
        string memory _title,
        string memory _description,
        string memory _choice1,
        string memory _choice2,
        uint256 _betAmount
    ) public {
        if (_betAmount <= 0) {
            revert PlaceYourBets__BetAmountMustBeGreaterThanZero();
        }
        if (s_betPool.status == BetStatus.OPEN ||
         s_betPool.status == BetStatus.IN_PROGRESS ||
         s_betPool.status == BetStatus.COMPLETED) {
            revert PlaceYourBets__BetInProgress();
        }
        BetPool memory newPool = BetPool(
            msg.sender,
            _title,
            _description,
            _choice1,
            _choice2,
            BetStatus.OPEN,
            _betAmount,
            0,
            0,
            new address[](0),
            new address[](0)
        );
        s_betPool = newPool;
        emit PoolCreated(msg.sender);
    }

    // check if address has already made a bet?
    function placeBet(uint8 _choice) public payable {
        if (msg.value != s_betPool.betAmount) {
            revert PlaceYourBets__BetNotEqualToBetPoolAmount();
        }
        // problem here with forcing 1 or 2
        if (_choice > 2) {
            revert PlaceYourBets__Choose1Or2();
        }
        if (s_betPool.status != BetStatus.OPEN) {
            revert PlaceYourBets__PoolNotOpen();
        }
        if (_choice == 1) {
            s_betPool.choice1Bets.push(payable(msg.sender));
        }
        if (_choice == 2) {
            s_betPool.choice2Bets.push(payable(msg.sender));
        }
        s_betPool.totalPot += msg.value;
        address bettor = msg.sender;
        emit BetPlaced(bettor);
    }

    function startBet() public {
        if (msg.sender != s_betPool.creator){
            revert PlaceYourBets__NotPoolOwner();
        }
        s_betPool.status = BetStatus.IN_PROGRESS;
    }

    function selectWinner(uint8 _winningChoice) public onlyOwner {
        s_betPool.winningOption = _winningChoice;
        emit WinnerSelected(s_betPool.winningOption);
    }

    function resetBetPool() public {
        if (s_betPool.status == BetStatus.COMPLETED){
            
            BetPool memory poolToStore = s_betPool;
            s_pastBets.push(poolToStore);
           // this might be expensive...
            s_betPool.title = "";
            s_betPool.description = "";
            s_betPool.choice1 = "";
            s_betPool.choice2 = "";
            s_betPool.status = BetStatus.NO_BET;
            s_betPool.betAmount = 0;
            s_betPool.totalPot = 0;
            s_betPool.winningOption = 0;
            s_betPool.choice1Bets = new address[](0);
            s_betPool.choice2Bets = new address[](0);
        } else {
            revert PlaceYourBets__PoolNotCompleted();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getBetAmount() public view returns (uint256) {
        return s_betPool.betAmount;
    }

    function getTotalPot() public view returns (uint256) {
        return s_betPool.totalPot;
    }

    function getChoice1NumOfBettors() public view returns (uint256) {
        return s_betPool.choice1Bets.length;
    }

    function getChoice2NumOfBettors() public view returns (uint256) {
        return s_betPool.choice2Bets.length;
    }

    function getBetTotalForChoice1() public view returns (uint256) {
        return s_betPool.choice1Bets.length * s_betPool.betAmount;
    }

    function getBetTotalForChoice2() public view returns (uint256) {
        return s_betPool.choice2Bets.length * s_betPool.betAmount;
    }

    function getNumberOfPastPools() public view returns (uint256) {
        return s_pastBets.length;
    }
}
