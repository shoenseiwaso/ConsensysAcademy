pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 5: Shopfront
//
// With thanks to Rob Hitchens' article on Solidity CRUD at:
// https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a

import "./Shopfront.sol";
import "./Merchant.sol";

contract SKULibrary {
	struct SKU {
		string desc;
		uint256 refCount;
		bytes32 ph;
	}

	// The "primary key" for a SKU is hash(desc).
	// If a merchant wants to change the price of an item,
	// they need to remove it and add it with the new price.
	mapping (bytes32 => uint256) public skuHashToId;
	SKU[] public catalog;

	// global state variables
	address public owner;
	Shopfront public sf;

	event AddedSKU(uint256 id, string desc, uint256 refCount, bytes32 ph);
	event RemovedSKU(uint256 id, string desc, uint256 refCount, bytes32 ph);

	// additions or updates can only be made by owner or an authorized merchant
	modifier onlyByAuthorized()
	{
		require(sf.isMerchant(msg.sender) || msg.sender == owner);
		_;
	}

	// only the owner can kill the whole contract
	modifier onlyByOwner()
	{
		require(msg.sender == owner);
		_;
	}

	function SKULibrary(address sfAddress) {
		owner = msg.sender;
		sf = Shopfront(sfAddress);
	}

	// based on: https://ethereum.stackexchange.com/questions/11039/how-can-you-check-if-a-string-is-empty-in-solidity
	function isEmptyString(string s) private constant returns(bool success) {
		bytes memory b = bytes(s);

		if (b.length == 0) {
			return true;
		}

		return false;
	}

	function addSKU(string desc) 
		public
		onlyByAuthorized()
		returns(uint256 id)
	{
		bool exists = false;
		bytes32 ph = skuHash(desc);
		
		(exists, id) = getSKUIdFromPH(ph);

		if (exists) {
			// SKU already exists, just update the reference counter
			catalog[id].refCount++;
		} else {
			SKU memory s = SKU(desc, 1, ph);

			// update index array and catalog in one step, saving on gas
			skuHashToId[ph] = catalog.push(s) - 1;
			id = catalog.length - 1;
		}

		AddedSKU(id, desc, catalog[id].refCount, ph);

		return id;
	}

	function removeSKU(uint256 id)
		public
		onlyByAuthorized()
	{
		require(skuExists(id));
		require(catalog[id].refCount > 0);

		// Verify that this merchant stocks this SKU.
		// Accounting is done on the merchant contract on purpose
		// to simplify stock quantity accounting.
		Merchant m = Merchant(msg.sender);
		require(m.skuExists(id));

		catalog[id].refCount--;

		SKU memory s = catalog[id];

		RemovedSKU(id, s.desc, s.refCount, s.ph);
	}

	function kill() public onlyByOwner() {
		selfdestruct(owner);
	}

	function skuHash(string desc)
		public
		constant
		returns(bytes32 ph)
	{
		return keccak256(desc);
	}

	// check if this SKU exists
	function skuExists(uint256 id)
		public
		constant
		returns(bool exists)
	{
		if (catalog.length == 0) {
			return false;
		}

		if (skuHashToId[catalog[id].ph] == id) {
			return true;
		}

		return false;
	}

	// check if this SKU exists by hash and if so, return its id
	function getSKUIdFromPH(bytes32 ph)
		public
		constant
		returns(bool exists, uint256 id)
	{
		if (catalog.length == 0) {
			return (false, 0);
		}

		id = skuHashToId[ph];

		if (catalog[id].ph == ph) {
			return (true, id);
		}

		return (false, 0);
	}

	// check if this SKU exists by description and if so, return its id
	function getSKUIdFromDesc(string desc)
		public
		constant
		returns(bool exists, uint256 id)
	{
		bytes32 ph = skuHash(desc);

		if (catalog.length == 0) {
			return (false, 0);
		}

		id = skuHashToId[ph];

		if (catalog[id].ph == ph) {
			return (true, id);
		}

		return (false, 0);
	}

	function getSKUCount()
		public
		constant
		returns(uint count)
	{
		return catalog.length;
	}

	function getSKUById(uint id)
		public
		constant
		returns(
			string desc,
			uint256 refCount,
			bytes32 ph)
	{
		// ensure this catalog entry exists
		require(id < catalog.length);

		SKU memory s = catalog[id];

		return (s.desc, s.refCount, s.ph);
	}
}
