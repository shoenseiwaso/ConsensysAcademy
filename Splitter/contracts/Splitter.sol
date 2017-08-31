pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 4: Splitter
//
// With thanks to Rob Hitchens' article on Solidity CRUD at:
// https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a

contract Splitter {
	struct ToUserStruct {
		address addr;
		string name;
		uint balance;
	}

	struct SplitterStruct {
		string fromUserName;
		ToUserStruct toUser1;
		ToUserStruct toUser2;
		uint index;
	}

	mapping (address => SplitterStruct) private splitterStructs;
	address[] private splitterIndex;

	// global state variables will be assigned on contract creation
	address public owner = msg.sender;
	bool public enabled = true;

	event InsertedSplitter(uint index);

	// TBD: do we need this to prevent some kind of weird overriding scenario?
	function Splitter() {
	}

	// additions or updates can only be made by transaction originator or contract owner
	modifier onlyByAuthorized(address _account)
	{
		require(msg.sender == _account || msg.sender == owner);
		_;
	}

	// only the owner can kill the whole contract
	modifier onlyByOwner()
	{
		require(msg.sender == owner);
		_;
	}

	// based on: https://ethereum.stackexchange.com/questions/11039/how-can-you-check-if-a-string-is-empty-in-solidity
	function isEmptyString(string s) private constant returns(bool success) {
		bytes memory b = bytes(s);

		if (b.length == 0) {
			return true;
		}

		return false;
	}

	function insertSplitter(
		address fromUserAddr,
		string fromUserName, 
		address toUser1Addr,
		string toUser1Name,
		address toUser2Addr,
		string toUser2Name)
		public
		payable
		onlyByAuthorized(fromUserAddr)
		returns(bool success)
	{
		require(enabled);
		require(msg.value > 0);
		require(!isEmptyString(fromUserName));
		require(!isEmptyString(toUser1Name));
		require(!isEmptyString(toUser2Name));
		require(!isSplitter(fromUserAddr));		// disallow updates (duplicate from address)

		// divide value between the two users, favouring the first user in the case of an odd amount of wei
		uint valueSplit2 = msg.value / 2;
		uint valueSplit1 = msg.value - valueSplit2;

		ToUserStruct memory toUser1 = ToUserStruct(toUser1Addr, toUser1Name, valueSplit1);
		ToUserStruct memory toUser2 = ToUserStruct(toUser2Addr, toUser2Name, valueSplit2);

		splitterStructs[fromUserAddr].fromUserName = fromUserName;
		splitterStructs[fromUserAddr].toUser1 = toUser1;
		splitterStructs[fromUserAddr].toUser2 = toUser2;

		// update index array and index of new splitter struct in one step, saving on gas
		splitterStructs[fromUserAddr].index = splitterIndex.push(fromUserAddr) - 1;

		InsertedSplitter(splitterIndex.length - 1);

		return true;
	}

	function kill() onlyByOwner() {
		enabled = false;
	}

	// check if this splitter exists
	function isSplitter(address fromUserAddr)
		public
		constant
		returns (bool exists)
	{
		if (splitterIndex.length == 0) {
			return false;
		}

		if (splitterIndex[splitterStructs[fromUserAddr].index] == fromUserAddr) {
			return true;
		}

		return false;
	}

	function getSplitterCount()
		public
		constant
		returns(uint count)
	{
		return splitterIndex.length;
	}

	function getSplitterAtIndex(uint index)
		public
		constant
		returns(
			address fromUserAddr,
			string fromUserName, 
			address toUser1Addr,
			string toUser1Name,
			uint toUser1Balance,
			address toUser2Addr,
			string toUser2Name,
			uint toUser2Balance)
	{
		// ensure this splitter entry exists
		require(index < splitterIndex.length);

		SplitterStruct memory s = splitterStructs[splitterIndex[index]];

		return (
			splitterIndex[index], 
			s.fromUserName, 
			s.toUser1.addr, 
			s.toUser1.name, 
			s.toUser1.balance, 
			s.toUser2.addr, 
			s.toUser2.name, 
			s.toUser2.balance
		);
	}
}
