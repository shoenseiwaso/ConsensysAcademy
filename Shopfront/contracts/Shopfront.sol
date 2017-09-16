pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 5: Shopfront
//
// With thanks to Rob Hitchens' article on Solidity CRUD at:
// https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a

contract Shopfront {
	struct ToUserStruct {
		address addr;
		string name;
		uint balance;
	}

	struct ShopfrontStruct {
		string fromUserName;
		ToUserStruct toUser1;
		ToUserStruct toUser2;
		uint index;
	}

	mapping (address => ShopfrontStruct) private ShopfrontStructs;
	address[] private ShopfrontIndex;

	// global state variables will be assigned on contract creation
	address public owner = msg.sender;
	bool public enabled = true;

	event InsertedShopfront(uint index);

	// TBD: do we need this to prevent some kind of weird overriding scenario?
	function Shopfront() {
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

	function isMerchant(address merchAddress) public returns (bool exists) {
		return true;
	}

	// based on: https://ethereum.stackexchange.com/questions/11039/how-can-you-check-if-a-string-is-empty-in-solidity
	function isEmptyString(string s) private constant returns(bool success) {
		bytes memory b = bytes(s);

		if (b.length == 0) {
			return true;
		}

		return false;
	}

	function insertShopfront(
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
		require(!isShopfront(fromUserAddr));		// disallow updates (duplicate from address)

		// divide value between the two users, favouring the first user in the case of an odd amount of wei
		uint valueSplit2 = msg.value / 2;
		uint valueSplit1 = msg.value - valueSplit2;

		ToUserStruct memory toUser1 = ToUserStruct(toUser1Addr, toUser1Name, valueSplit1);
		ToUserStruct memory toUser2 = ToUserStruct(toUser2Addr, toUser2Name, valueSplit2);

		ShopfrontStructs[fromUserAddr].fromUserName = fromUserName;
		ShopfrontStructs[fromUserAddr].toUser1 = toUser1;
		ShopfrontStructs[fromUserAddr].toUser2 = toUser2;

		// update index array and index of new Shopfront struct in one step, saving on gas
		ShopfrontStructs[fromUserAddr].index = ShopfrontIndex.push(fromUserAddr) - 1;

		InsertedShopfront(ShopfrontIndex.length - 1);

		return true;
	}

	function kill() onlyByOwner() {
		enabled = false;
	}

	// check if this Shopfront exists
	function isShopfront(address fromUserAddr)
		public
		constant
		returns (bool exists)
	{
		if (ShopfrontIndex.length == 0) {
			return false;
		}

		if (ShopfrontIndex[ShopfrontStructs[fromUserAddr].index] == fromUserAddr) {
			return true;
		}

		return false;
	}

	function getShopfrontCount()
		public
		constant
		returns(uint count)
	{
		return ShopfrontIndex.length;
	}

	function getShopfrontAtIndex(uint index)
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
		// ensure this Shopfront entry exists
		require(index < ShopfrontIndex.length);

		ShopfrontStruct memory s = ShopfrontStructs[ShopfrontIndex[index]];

		return (
			ShopfrontIndex[index], 
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
