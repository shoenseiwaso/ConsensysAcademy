pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 4: Splitter, the lightweight version
//
// Based on feedback from Rob:
// 1. No need for a Splitter struct. 
// 2. No need for a User struct. 
// 3. No need for user profile concerns (name)
// 4. Include a way to withdraw funds
//
// Basic data mapping: mapping(address => uint) balances;
//
// Can you do it the fewest line of code possible?
//
// Make it a public utility by allowing anyone to send to it

contract SplitterLite {
	mapping (address => uint) public balances;

	// global state variables will be set on contract creation
	address public owner = msg.sender;

	// accept funds from owner 
	function split(address to1, address to2) public payable {
		uint amount1 = msg.value / 2;
		balances[to1] += amount1;
		balances[to2] += msg.value - amount1;
	}

	// use the preferred withdrawal pattern rather than the send pattern
	// see: http://solidity.readthedocs.io/en/develop/common-patterns.html#withdrawal-from-contracts
	function withdraw() {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

	// Kill the contract and return remaining balance to the owner.
	// Clearly this will disenfranchise anyone with an outstanding balance,
	// so either the owner needs to be a trusted party or this function should be 
	// expanded with safeguards.
	function kill() public { 
		require(msg.sender == owner);
		selfdestruct(owner);
	}
}
