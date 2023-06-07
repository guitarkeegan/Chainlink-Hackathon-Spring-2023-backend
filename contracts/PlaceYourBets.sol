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
    error BET_AMOUNT_MUST_BE_GREATER_THAN_ZERO();
    error BET_NOT_EQUAL_TO_POOL_BET_AMOUNT();
    error CHOOSE_1_OR_2();
    error POOL_NOT_OPEN();
    error UpkeepNotNeeded();
    error PlaceYourBets__NotOwner();
    error PlaceYourBets__BetInProgress();

    /* state variables */
    BetPool s_betPool;
    BetPool[] s_pastBets;

    enum BetStatus {
        OPEN,
        IN_PROGRESS,
        COMPLETED
    }

    /* events */
    event PoolCreated(address indexed creator);
    event BetCreated(address indexed bettor);
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
            revert UpkeepNotNeeded();
        }
        // TODO: check winner of bet and payout
        uint8 winningChoice = s_betPool.winningOption;
        if (winningChoice != 0) {
            BetPool memory completedPool = s_betPool;
            if (winningChoice == 1) {
                for (uint256 i = 0; i < completedPool.choice1Bets.length; i++) {
                    // TODO: pay winners
                }
            } else {
                for (uint256 i = 0; i < completedPool.choice2Bets.length; i++) {
                    // TODO: pay winners
                }
            }
        }
    }

    function checkUpkeep(
        bytes memory
    ) public returns (bool upkeepNeeded, bytes memory /* performData */) {
        BetPool[] memory curBet = s_betPool;
        bool result = false;
        if (curBet.status == BetStatus.COMPLETED) {
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
            revert BET_AMOUNT_MUST_BE_GREATER_THAN_ZERO();
        }
        if (s_betPool != 0) {
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

    function placeBet(uint256 _poolIndex, uint8 _choice) public payable {
        if (msg.value != s_betPool.betAmount) {
            revert BET_NOT_EQUAL_TO_POOL_BET_AMOUNT();
        }
        // problem here with forcing 1 or 2
        if (_choice > 2) {
            revert CHOOSE_1_OR_2();
        }
        if (s_betPool.status != BetStatus.OPEN) {
            revert POOL_NOT_OPEN();
        }
        if (_choice == 1) {
            s_betPool.choice1Bets.push(payable(msg.sender));
        }
        if (_choice == 2) {
            s_betPool.choice2Bets.push(payable(msg.sender));
        }
        s_betPool.totalPot += msg.value;
        address bettor = msg.sender;
        emit BetCreated(bettor);
    }

    function selectWinner(uint8 _winningChoice) private onlyOwner {
        s_betPool.winningOption = _winningChoice;
        emit WinnerSelected(s_betPool.winningOption);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getBetAmount(uint256 _poolIndex) public view returns (uint256) {
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
}
