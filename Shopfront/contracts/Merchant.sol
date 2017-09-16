pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 5: Shopfront
//
// With thanks to Rob Hitchens' article on Solidity CRUD at:
// https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a

import "./Shopfront.sol";

contract Merchant {
	struct Product {
		uint256 price;
		string desc;
		uint256 refCount;
		bytes32 ph;
	}

	// The "primary key" for a product is hash(price + desc).
	// If a merchant wants to change the price of an item,
	// they need to remove it and add it with the new price.
	mapping (bytes32 => uint256) public productHashToId;
	Product[] public catalog;

	// global state variables
	address public owner;
	Shopfront public sf;

	event AddedProduct(uint256 id, uint256 price, string desc, uint256 refCount, bytes32 ph);
	event RemovedProduct(uint256 id, uint256 price, string desc, uint256 refCount, bytes32 ph);

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

	function addProduct(uint256 price, string desc) 
		public
		onlyByAuthorized()
	{
		bool exists = false;
		uint256 id = 0;
		bytes32 ph = productHash(price, desc);
		
		(exists, id) = getProductId(ph);

		if (exists) {
			// product already exists, just update the reference counter
			catalog[id].refCount++;
		} else {
			Product memory p = Product(price, desc, 1, ph);

			// update index array and catalog in one step, saving on gas
			productHashToId[ph] = catalog.push(p) - 1;
			id = catalog.length - 1;
		}

		AddedProduct(id, price, desc, catalog[id].refCount, ph);
	}

	function removeProduct(uint256 id)
		public
		onlyByAuthorized()
	{
		require(productExists(id));
		require(catalog[id].refCount > 0);

		// Verify that this merchant stocks this product.
		// Accounting is done on the merchant contract on purpose
		// to simplify stock quantity accounting.
		Merchant m = Merchant(msg.sender);
		require(m.productExists(id));

		catalog[id].refCount--;

		RemovedProduct(id, catalog[id].price, catalog[id].desc, catalog[id].refCount, catalog[id].ph);
	}

	function kill() onlyByOwner() {
		selfdestruct(owner);
	}

	function productHash(uint256 price, string desc)
		public
		constant
		returns (bytes32 ph)
	{
		return keccak256(price, desc);
	}

	// check if this product exists
	function productExists(uint256 id)
		public
		constant
		returns (bool exists)
	{
		if (catalog.length == 0) {
			return false;
		}

		if (productHashToId[catalog[id].ph] == id) {
			return true;
		}

		return false;
	}

	// check if this product exists and if so, return its id
	function getProductId(bytes32 ph)
		public
		constant
		returns (bool exists, uint256 id)
	{
		if (catalog.length == 0) {
			return (false, 0);
		}

		id = productHashToId[ph];

		if (catalog[id].ph == ph) {
			return (true, id);
		}

		return (false, 0);
	}

	function getProductCount()
		public
		constant
		returns(uint count)
	{
		return catalog.length;
	}

	function getProductById(uint id)
		public
		constant
		returns(
			uint256 price,
			string desc,
			uint256 refCount,
			bytes32 ph)
	{
		// ensure this catalog entry exists
		require(id < catalog.length);

		Product memory p = catalog[id];

		return (
			p.price,
			p.desc,
			p.refCount,
			p.ph
		);
	}
}
