pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = .5 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  event Stake(address, uint256);


  modifier exceededDeadline() {
    require(block.timestamp >= deadline, "DeadLine not reached. Patience is a virtue!");
    _;
  }

  modifier preDeadline() {
    require(block.timestamp < deadline, "DeadLine passed, can't execute stake or withdraw!");
    _;
  }


  modifier thresholdReached() {
    require(address(this).balance >= threshold, "Takes money to make money!");
    _;
  }


  modifier thresholdNotReached() {
    require(address(this).balance < threshold, "Stake it!");
    _;
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Staking already completed!");
    _;

  }

  // Collect fund in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  /*I don't understand why the `notCompleted` modifier doesn't prevent post ... oh now I think I do... 
  if there wasn't enough staked the contract isn't completed. */
  function stake() public payable preDeadline {
      balances[msg.sender] += msg.value;
      emit Stake(msg.sender, msg.value);

  }
  // After some `deadline` allow anyone to call an `execute()` function
  /*If the address(this).balance of the contract is over the threshold by the deadline, 
  (SO CALL DEADLINE FIRST. Still shocked by the backwards I get and don't get. Sigh.)
  you will want to call: exampleExternalContract.complete{value: address(this).balance}()
  Also, Solidity is magic, as is all programming.*/
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  /*Moved `notCompleted` modifier to the first so that the proper error message shows when attempting to re-execute.
  Once executed the amount in the contract resets to 0 so it was showing "Threshold not reached" instead of "Staking completed".*/

  function execute() public notCompleted exceededDeadline thresholdReached  {
      exampleExternalContract.complete{value: address(this).balance}();
  }

  
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address payable user) external exceededDeadline thresholdNotReached notCompleted {
      require(balances[user] != 0, "User's balance is 0, can't withdraw.");
      uint256 withdrawAmount = balances[user];
      balances[user] = 0;
      user.transfer(withdrawAmount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    return block.timestamp >= deadline ? 0 : (deadline - block.timestamp);
  }



  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable  {
    stake();
  }

  function totalBalance() public view returns (uint256) {
    return address(this).balance;
  }


}
