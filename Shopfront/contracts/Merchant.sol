pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 5: Shopfront
//
// With thanks to Rob Hitchens' article on Solidity CRUD at:
// https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a

import "./Shopfront.sol";
import "./SKULibrary.sol";

contract Merchant {
	struct Product {
		uint256 skuId;
		uint256 price;
		uint256 stock;
	}

	mapping (uint256 => bool) productActive;
	Product[] public catalog;

	// global state variables
	address public owner;
	address public merch;
	Shopfront public sf;
	SKULibrary public sl;

	event AddedProduct(uint256 id, string desc, uint256 price, uint256 stock);
	event RemovedProduct(uint256 id, string desc, uint256 price, uint256 stock);

	// additions or updates can only be made by owner or the merchant
	modifier onlyByAuthorized()
	{
		require(msg.sender == merch || msg.sender == owner);
		_;
	}

	// only the owner can kill the whole contract
	modifier onlyByOwner()
	{
		require(msg.sender == owner);
		_;
	}

	function Merchant(address mAddress, address sfAddress, address slAddress) {
		owner = msg.sender;
		merch = mAddress;
		sf = Shopfront(sfAddress);
		sl = SKULibrary(slAddress);
	}

	// based on: https://ethereum.stackexchange.com/questions/11039/how-can-you-check-if-a-string-is-empty-in-solidity
	function isEmptyString(string s) private constant returns(bool success) {
		bytes memory b = bytes(s);

		if (b.length == 0) {
			return true;
		}

		return false;
	}

	function purchase() public payable {

	}

	function coPurchase() public constant {

	}

	function coPay() public payable {

	}

	function withdraw() public {

	}

	function addProduct(string desc, uint256 price, uint256 stock) 
		public
		onlyByAuthorized()
	{
		// get SKU id from description
		bool exists = false;
		uint256 id = 0;
		(exists, id) = sl.getSKUIdFromDesc(desc);

		// if SKU id not present in library, add
		if (!exists) {
			id = sl.addSKU(desc);
		}

		// if we have this SKU id already in our catalog, simply update the price and stock


		// otherwise add the product to our catalog

		bool exists = false;
		uint256 id = 0;
		bytes32 ph = productHash(price, desc);
		
		(exists, id) = sl.getProductId(ph);

		if (exists) {
			// product already exists, just update the reference counter
			// catalog[id].refCount++;
		} else {
			Product memory p = Product(price, desc, 1, ph);

			// update index array and catalog in one step, saving on gas
			catalog.push(p);
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

		Product memory p = catalog[id];

		RemovedProduct(id, p.price, p.desc, p.refCount, p.ph);
	}

	function kill() public onlyByOwner() {
		selfdestruct(merch);
	}

	function productHash(uint256 price, string desc)
		public
		constant
		returns(bytes32 ph)
	{
		return keccak256(price, desc);
	}

	// check if this product exists
	function productExists(uint256 id)
		public
		constant
		returns(bool exists)
	{
		if (catalog.length == 0) {
			return false;
		}

		// if (productHashToId[catalog[id].ph] == id) {
		// 	return true;
		// }

		return false;
	}

	// check if this product exists and if so, return its id
	function getProductId(bytes32 ph)
		public
		constant
		returns(bool exists, uint256 id)
	{
		if (catalog.length == 0) {
			return (false, 0);
		}

		// id = productHashToId[ph];

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

		return (p.price, p.desc, p.refCount, p.ph);
	}
}
