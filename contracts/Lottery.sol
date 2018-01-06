pragma solidity ^0.4.17;

/**
 * @title Ethereum-Lottery
 * @dev Simple lottery smart contract to run on the Ethereum
 * chain. Designed to (hopefully) work well with a web3 front-end.
 * Source of randomness comes from ethereum block hashes.
 *
 */

contract Lottery {

    event LotteryTicketPurchased(address indexed _purchaser, uint256 _ticketID);
    event LotteryAmountPaid(address indexed _winner, uint256 _amount);
    event OwnershipTransferred(address _old, address _new);


    // variables that I may want to change in the future
    uint64 ticketPrice = 10 finney;
    uint64 ticketMax = 5;

    // number of tickets is set to a hard 5, I hope I don't regret this
    // inb4 price of ethereum goes up to 10000 and funds are locked
    address[6] public ticketMapping;
    uint256 ticketsBought = 0;

    // greater than to prevent locked funds
    modifier allTicketsSold() {
      require(ticketsBought>=ticketMax);
      _;
    }

    function Lottery() public {
      // help i do not know if an empty constructor works
      uint x = 5;
    }

    function() payable public {
      // for now, have ticket purchasing only through functions
      // for sanity purposes
      revert();
    }

    function buyTicket(uint16 _ticket) payable public returns (bool) {
      // I'd prefer all tickets to just be 0.01 ether
      require(msg.value == ticketPrice);
      require(_ticket > 0 && _ticket < ticketMax+1);
      require(ticketMapping[_ticket]==address(0));
      require(ticketsBought < ticketMax);

      address purchaser = msg.sender;
      ticketsBought += 1;
      ticketMapping[_ticket] = purchaser;
      LotteryTicketPurchased(purchaser, _ticket);

      // placing "burden" of sendReward() on last ticket buyer
      // is okay, because the refund from destroying the arrays
      // makes it cost less than buying a regular ticket
      if(ticketsBought>=ticketMax) {
        sendReward();
      }

      return true;
    }

    // if a bad winner is chosen the first time, it's possible to just run
    // sendReward() again. But can this cause an attack?
    function sendReward() public allTicketsSold returns (address) {
      uint64 winningNumber = lotteryPicker();
      address winner = ticketMapping[winningNumber];

      // prevent locked funds by sending to bad address
      require(winner != address(0));
      uint256 totalAmount = ticketMax*ticketPrice;
      reset();
      winner.transfer(totalAmount);
      LotteryAmountPaid(winner, totalAmount);
      return winner;
    }

    // @return a random number based off of current block information
    function lotteryPicker() public allTicketsSold returns (uint64) {
      return uint64(sha256(block.timestamp, block.number)) % ticketMax;
    }

    // resets everything to work
    function reset() private allTicketsSold returns (bool) {
      ticketsBought = 0;
      for(uint x = 0; x < ticketMax; x++) {
        delete ticketMapping[x];
      }
      return true;
    }

    // Yes, I know there's a built-in getting function for this,
    // but I'd like to put it in anyways for readability for the
    // web3 part :)

    function getTicketsPurchased() public view returns(address[6]) {
      return ticketMapping;
    }
}
