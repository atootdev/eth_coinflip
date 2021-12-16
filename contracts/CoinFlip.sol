// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol"; // import chainlink

contract CoinFlip is VRFConsumerBase {

    struct CoinFlipStruct { // Struct for storing the coin flip
        uint256 ID;
        address payable betStarter;
        uint256 startingWager;
        address payable betEnder;
        uint256 endingWager;
        uint256 etherTotal;
        address payable winner;
        address payable loser;
    }

    // Variables for working with Chainlink's VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;


    uint256 numCoinFlips = 300; // Number of coin flips - this becomes the ID of the game
    mapping(uint256 => CoinFlipStruct) CoinFlipStructs; // Mapping to store all the coin flip games

    event CoinFlipped(uint256 indexed theCoinFlipID); // Create the event for the coin flip
    event CoinFinishedFlip(address indexed winner); // Create the event for player 2 to find out who the winner is
    // Events are similar to functions but they are not payable and do not return a value
    // Learn more about the difference here https://levelup.gitconnected.com/events-vs-functions-in-solidity-3d6e797f349e

    // testing with hard-coded values - do not use in production
    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18;
    }

    function getRandomNumber() public returns (bytes32 requestId) { // Callback function for VRF
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    // Sets the random number 
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override 
    {
        randomResult = randomness;
    }

    // Start the Ether coin flip
    function newCoinFlip() public payable returns (uint256 coinFlipID) {
        address theBetStarter = msg.sender; // Converting the sender to a payable address
        address payable player1 = payable(theBetStarter);

        coinFlipID = numCoinFlips++; // Increase number of coin flips by 1 every time a game is started

        CoinFlipStructs[coinFlipID] = CoinFlipStruct( // Create a new coin flip game identified by coinFlipID
            coinFlipID,
            player1,
            msg.value,
            player1,
            msg.value,
            0,
            player1,
            player1
        );
        emit CoinFlipped(coinFlipID); // Emit the event to tell the player the coinFlipID
    }

    // End the Ether coin flip
    function endCoinFlip(uint256 coinFlipID) public payable {
        CoinFlipStruct memory c = CoinFlipStructs[coinFlipID]; // Store the coin flip game in memory

        address theBetender = msg.sender; // Converting player 2 to payable address agai
        address payable player2 = payable(theBetender);

        // Require statements to make sure the coinFlipID is valid and player 2 sends an equal amount of Ether
        require(coinFlipID == c.ID);
        require(msg.value == c.startingWager);

        // Update variables inside the coin flip game
        c.betEnder = player2;
        c.endingWager = msg.value;
        c.etherTotal = c.startingWager + c.endingWager;

        fulfillRandomness(getRandomNumber(), coinFlipID); // Call the random function and pass in the coinFlipID as a parameter

        // Create a simple if else statement to determine the winner and send the Ether winnings
        if ((randomResult % 2) == 0) {
            c.winner = c.betStarter;
        } else {
            c.winner = c.betEnder;
        }

        c.winner.transfer(c.etherTotal);
        emit CoinFinishedFlip(c.winner); // Emit the event to tell player 2 the winner
    }
}