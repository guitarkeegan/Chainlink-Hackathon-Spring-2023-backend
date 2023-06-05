// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract PlaceYourBets is ChainlinkClient, AutomationCompatibleInterface, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    
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
    error NO_BET_POOL_AT_THAT_INDEX();
    error BET_NOT_EQUAL_TO_POOL_BET_AMOUNT();
    error CHOOSE_1_OR_2();
    error POOL_NOT_OPEN();
    error NOT_OWNER();
    error UpkeepNotNeeded();
    /* state variables */
    BetPool[] public pools;

    enum BetStatus {
        OPEN,
        IN_PROGRESS,
        COMPLETED
    }

    /* events */
    event PoolCreated(address indexed creator);
    event BetCreated(address indexed bettor);
    event RequestFirstId(bytes32 indexed requestId, string id);

    string public id;

    address i_owner;
    bytes32 private jobId;
    uint256 private fee;
    bytes32 public rank;
    bytes32 public tier;
    
    event RequestMultipleFullfilled(
        bytes32 indexed requestId,
        bytes32 rank,
        bytes32 tier
    );

    constructor() ConfirmedOwner(msg.sender){
        i_owner = msg.sender;
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    function performUpkeep(bytes calldata /* performData */) external override{
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded){
            revert UpkeepNotNeeded();
        }
    }

    function checkUpkeep(bytes memory /* checkData */) public override returns (bool upkeepNeeded, bytes memory /* performData */){
        BetPool[] memory curBets = pools;
        bool result = false;
        for (uint256 i=0;i<curBets.length;i++){
            // check status
            if (curBets[i].status == BetStatus.COMPLETED){
                result = true;
                break;
            }
        }
        upkeepNeeded = result;
    }

    function requestFirstId() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        // riotgames api
        // dev key
        req.add(
            "get",
            "https://na1.api.riotgames.com/lol/league/v4/entries/by-summoner/1Y4w2fpEzxMONISK2M3MNPudYdDgd_bAtq-g0EE-KZ76qsE?api_key=RGAPI-1ad43d58-3ddb-4396-909e-8d4183224e4f"
        );

        // Set the path to find the desired data in the API response, where the response format is:
        // [{
        //  "id": "bitcoin",
        //  "symbol": btc",
        // ...
        // },
        //{
        // ...
        // .. }]
        // request.add("path", "0.id"); // Chainlink nodes prior to 1.0.0 support this format
        req.add("path", "0,rank"); // Chainlink nodes 1.0.0 and later support this format
        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of string
     */
    function fulfill(
        bytes32 _requestId,
        string memory _id
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestFirstId(_requestId, _id);
        id = _id;
    } 

     /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
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

        pools.push(newPool);

        emit PoolCreated(msg.sender);
    }

    function placeBet(uint256 _poolIndex, uint8 _choice) public payable {
        bool exists = poolExists(_poolIndex);
        if (!exists) {
            revert NO_BET_POOL_AT_THAT_INDEX();
        }
        if (msg.value != pools[_poolIndex].betAmount) {
            revert BET_NOT_EQUAL_TO_POOL_BET_AMOUNT();
        }
        // problem here with forcing 1 or 2
        if (_choice > 2) {
            revert CHOOSE_1_OR_2();
        }
        if (pools[_poolIndex].status != BetStatus.OPEN) {
            revert POOL_NOT_OPEN();
        }
        if (_choice == 1) {
            pools[_poolIndex].choice1Bets.push(payable(msg.sender));
        }
        if (_choice == 2) {
            pools[_poolIndex].choice2Bets.push(payable(msg.sender));
        }
        address bettor = msg.sender;
        emit BetCreated(bettor);
    }

    function getWinningBet(
        uint256 poolIndex,
        uint8 winningBet
    ) private {
        pools[poolIndex].winningOption = winningBet;
        pools[poolIndex].status = BetStatus.COMPLETED;
        // call payout function
    }

    function poolExists(uint256 _poolIndex) public view returns (bool) {
        if (_poolIndex >= pools.length) {
            return false;
        }
        return true;
    }

    /* modifiers */

    //TODO:
    // function availableBets(){}

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getBetAmount(uint256 _poolIndex) public view returns (uint256) {
        if (!poolExists(_poolIndex)) {
            revert NO_BET_POOL_AT_THAT_INDEX();
        }
        return pools[_poolIndex].betAmount;
    }

    function getOpenBets(
        uint256 numOfBetsToReturn
    ) public view returns (uint256[] memory) {
        // return all open bets
        // can't push to memory array, so return an array of indecies instead
        uint256[] memory openBetPoolsIndex = new uint256[](numOfBetsToReturn);

        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].status == BetStatus.OPEN) {
                openBetPoolsIndex[i] = i;
            }
        }
        // generally returning arrays should be avoided but...
        return openBetPoolsIndex;
    }

    function getBetPoolData(
        uint256 _index
    ) public view returns (BetPool memory) {
        if (!poolExists(_index)) {
            revert NO_BET_POOL_AT_THAT_INDEX();
        }
        return pools[_index];
    }
}
