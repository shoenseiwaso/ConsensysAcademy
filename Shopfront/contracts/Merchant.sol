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
		bool active;
	}

	mapping (uint256 => uint256) skuIdToProdId;
	Product[] public products;

	// global state variables
	address public owner;
	address public merch;
	Shopfront public sf;
	SKULibrary public sl;

	event IssueReceipt(address merch, address customer, uint skuId, uint256 quantity, uint256 price, uint256 totalDue, uint256 changeDue);
	event AddedProduct(uint256 id, uint256 skuId, string desc, uint256 price, uint256 stock);
	event RemovedProduct(uint256 id, uint256 skuId, uint256 price, uint256 stock);

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

	function purchase(uint256 skuId, uint256 quantity) public payable {
		bool exists = false;
		uint256 id = 0;

		(exists, id) = getProductId(skuId);

		require(exists);
		require(products[id].active);
		require(products[id].stock >= quantity);

		uint256 totalDue = products[id].price * quantity;

		require(msg.value >= totalDue);

		uint256 changeDue = msg.value - totalDue;

		products[id].stock -= quantity;

		// "ship" the product; presumably an off-chain oracle would be watching
		// these events and initiate the fulfillment process
		IssueReceipt(msg.sender, merch, skuId, quantity, products[id].price, totalDue, changeDue);
		FulfillOrder(skuId, quantity, msg.sen);

		if (change > 0) {
			msg.sender.transfer(changeDue);
		}
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
		uint256 skuId = 0;
		uint256 id = 0;
		(exists, skuId) = sl.getSKUIdFromDesc(desc);

		// if SKU id not present in library, add
		if (!exists) {
			skuId = sl.addSKU(desc);
		}

		(exists, id) = getProductId(skuId);

		if (exists) {
			// if we have this SKU id already in our catalog, simply update the price and stock	
			products[id].price = price;
			products[id].stock = stock;
		} else {
			// otherwise add the product to our catalog
			Product memory p = Product(skuId, price, stock, true);

			// slight gas savings by doing this in one step
			skuIdToProdId[skuId] = products.push(p) - 1;

			id = products.length - 1;
		}

		AddedProduct(id, skuId, desc, price, stock);
	}

	function removeProduct(uint256 skuId)
		public
		onlyByAuthorized()
	{
		bool exists = false;
		uint256 id = 0;

		(exists, id) = getProductId(skuId);

		require(exists);
		require(products[id].active);

		sl.removeSKU(skuId);

		products[id].active = false;

		// Verify that this merchant stocks this product.
		// Accounting is done on the merchant contract on purpose
		// to simplify stock quantity accounting.
		Merchant m = Merchant(msg.sender);
		require(m.productExists(id));

		Product memory p = products[id];

		RemovedProduct(id, skuId, p.price, p.stock);
	}

	function kill() public onlyByOwner() {
		selfdestruct(merch);
	}

	// check if this product exists
	function productExists(uint256 skuId)
		public
		constant
		returns(bool exists)
	{
		if (products.length == 0) {
			return false;
		}

		uint256 id = skuIdToProdId[skuId];

		if (products[id].skuId == skuId && products[id].active) {
		 	return true;
		}

		return false;
	}

	// check if this product exists and if so, return its id
	function getProductId(uint256 skuId)
		public
		constant
		returns(bool exists, uint256 id)
	{
		if (products.length == 0) {
			return (false, 0);
		}

		id = skuIdToProdId[skuId];

		if (products[id].skuId == skuId && products[id].active) {
		 	return (true, id);
		}

		return (false, 0);
	}

	function getProductCount()
		public
		constant
		returns(uint count)
	{
		return products.length;
	}

	function getProductById(uint id)
		public
		constant
		returns(
			uint256 skuId,
			uint256 price,
			uint256 stock,
			bool active)
	{
		// ensure this catalog entry exists
		require(id < products.length);

		Product memory p = products[id];

		return (p.skuId, p.price, p.stock, p.active);
	}
}
