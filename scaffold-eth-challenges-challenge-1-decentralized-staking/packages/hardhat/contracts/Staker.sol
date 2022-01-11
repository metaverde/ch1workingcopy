pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = .001 ether;
  uint256 public deadline = block.timestamp + 240 seconds;
  event Stake(address, uint256);


  modifier exceededDeadline() {
    require(block.timestamp >= deadline, "DeadLine not reached. Patience is a virtue!");
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
  function stake() public payable notCompleted {
      balances[msg.sender] += msg.value;
      emit Stake(msg.sender, msg.value);

  }
  // After some `deadline` allow anyone to call an `execute()` function
  /*If the address(this).balance of the contract is over the threshold by the deadline, 
  (SO CALL DEADLINE FIRST. Still shocked by the backwards I get and don't get. Sigh.)
  you will want to call: exampleExternalContract.complete{value: address(this).balance}()
  Also, Solidity is magic, as is all programming.*/
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  function execute() public exceededDeadline thresholdReached notCompleted {
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
