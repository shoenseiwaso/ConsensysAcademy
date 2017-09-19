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

	struct CoPay {
		address initiator;
		uint256 skuId;
		uint256 quantity;
		uint256 price;
		uint256 totalDue;
		uint256 paid;
	}

	mapping (bytes32 => CoPay) coPays;

	// global state variables
	address public owner;
	address public merch;
	Shopfront public sf;
	SKULibrary public sl;
	uint256 public sfFee;

	event IssueReceipt(address merchant, address customer, uint skuId, uint256 quantity, uint256 price, uint256 totalDue, uint256 changeDue);
	event FulfillOrder(address merchant, address customer, uint skuId, uint256 quantity);
	event NewCoPay(address merchant, address initiator, bytes32 coPayId, uint256 skuId, uint256 quantity, uint256 totalDue);
	event CoPayment(address merchant, address payer, bytes32 coPayId, uint256 amount, uint256 paid);
	event AddedProduct(uint256 id, uint256 skuId, string desc, uint256 price, uint256 stock);
	event RemovedProduct(uint256 id, uint256 skuId, uint256 price, uint256 stock);
	event MerchWithdraw(address merchant, uint256 amount);

	// additions or updates can only be made by owner or the merchant
	modifier onlyByAuthorized()
	{
		require(msg.sender == merch || msg.sender == owner);
		_;
	}

	// only the merchant can withdraw funds
	modifier onlyByMerchant()
	{
		require(msg.sender == merch);
		_;
	}

	// only the owner can kill the whole contract, via the Shopfront contract
	modifier onlyByShopfront()
	{
		require(msg.sender == address(sf));
		_;
	}

	function Merchant(address sfOwner, address mAddress, address slAddress, uint256 _sfFee) {
		owner = sfOwner;
		merch = mAddress;
		sf = Shopfront(msg.sender);
		sl = SKULibrary(slAddress);
		sfFee = _sfFee;
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
		require(quantity > 0);
		require(products[id].stock >= quantity);

		uint256 totalDue = products[id].price * quantity;

		require(msg.value >= totalDue);

		uint256 changeDue = msg.value - totalDue;

		// do this now to avoid reentrant risk from msg.sender.transfer() below
		products[id].stock -= quantity;

		// Pay the Shopfront owner fee directly now.
		// Avoids the owner having to poll all merchant contracts to collect fees.
		// Unsigned integer math so just divide by the sfFee amount and perform a couple of checks.
		// If the owner set a nonsensical fee they don't get paid.
		uint256 sfFeeDue = totalDue / sfFee;
		if (sfFeeDue >= msg.value - changeDue && sfFeeDue > 0) {
			owner.transfer(sfFeeDue);
		}

		// Issue a receipt and "ship" the product; presumably an off-chain oracle would be watching
		// these events and initiate the fulfillment process
		IssueReceipt(merch, msg.sender, skuId, quantity, products[id].price, totalDue, changeDue);
		FulfillOrder(merch, msg.sender, skuId, quantity);

		if (changeDue > 0) {
			msg.sender.transfer(changeDue);
		}
	}

	// Create a new co-payment on a quantity of items.
	// Needed to split this out into a different function due to stack depth issues.
	// Returns a unit co-pay ID, based on the current block number and item details. This 
	// allows an initiator to co-purchase the same item multiple times (although not 
	// multiple times on the same block.)
	function newCoPay(
		uint256 skuId, 
		uint256 quantity)
		public  
		returns(bytes32 coPayId)
	{
		// generate a new, unique co-pay ID
		coPayId = keccak256(msg.sender, skuId, quantity, block.number);

		// ensure this co-pay ID not already taken (i.e., duplicate calls in the same block)
		require(coPays[coPayId].initiator == address(0));

		// ensure the product exists and there is sufficient stock
		bool exists = false;
		uint256 id = 0;

		(exists, id) = getProductId(skuId);

		require(exists);
		require(products[id].active);
		require(quantity > 0);
		require(products[id].stock >= quantity);

		// deduct this stock from the inventory to reserve it
		products[id].stock -= quantity;

		uint256 totalDue = products[id].price * quantity;

		coPays[coPayId] = CoPay(msg.sender, skuId, quantity, products[id].price, totalDue, 0);

		NewCoPay(merch, msg.sender, coPayId, skuId, quantity, totalDue);
	}

	// Make payment against existing co-payment.
	// Item is purchased when enough money has been paid to this co-payment ID.
	function coPay(
		address initiator, 
		bytes32 coPayId)
		public 
		payable
	{
		// validate coPayId (implicitly) and passed parameters
		require(coPays[coPayId].initiator == initiator);

		// ensure co-pay has not been completed
		require(coPays[coPayId].totalDue - coPays[coPayId].paid > 0);

		// We're okay if there's actually no value transferred (usually only if new co-pay).
		// Could be someone setting up a gift registry, for example.
		if (msg.value > 0) {
			// partial payment; credit it and return
			if (msg.value + coPays[coPayId].paid < coPays[coPayId].totalDue) {
				coPays[coPayId].paid += msg.value;

				CoPayment(merch, msg.sender, coPayId, msg.value, coPays[coPayId].paid);
			}

			// last payment, complete the purchase
			uint256 changeDue = msg.value - (coPays[coPayId].totalDue - coPays[coPayId].paid);

			// Pay the Shopfront owner fee directly now.
			// See above for additional comments.
			uint256 sfFeeDue = coPays[coPayId].totalDue / sfFee;
			if (sfFeeDue >= msg.value - changeDue && sfFeeDue > 0) {
				owner.transfer(sfFeeDue);
			}

			// Issue a receipt and "ship" the product; presumably an off-chain oracle would be watching
			// these events and initiate the fulfillment process
			IssueReceipt(merch, coPays[coPayId].initiator, coPays[coPayId].skuId, coPays[coPayId].quantity, coPays[coPayId].price, coPays[coPayId].totalDue, changeDue);
			FulfillOrder(merch, coPays[coPayId].initiator, coPays[coPayId].skuId, coPays[coPayId].quantity);

			if (changeDue > 0) {
				msg.sender.transfer(changeDue);
			}
		}
	}

	// Merchant uses this to collect funds.
	function withdraw() public onlyByMerchant() {
		require(this.balance > 0);

		MerchWithdraw(merch, this.balance);

		merch.transfer(this.balance);
	}

	function addProduct(string desc, uint256 price, uint256 stock) 
		public
		onlyByAuthorized()
	{
		// get SKU id from description
		bool skuExists = false;
		bool prodExists = false;
		uint256 skuId = 0;
		uint256 id = 0;
		(skuExists, skuId) = sl.getSKUIdFromDesc(desc);

		// if SKU id not present in library, add
		if (!skuExists) {
			skuId = sl.addSKU(desc);
		}

		(prodExists, id) = getProductId(skuId);

		if (prodExists) {
			// if we have this SKU id already in our catalog, simply update the price and stock	
			products[id].price = price;
			products[id].stock = stock;
		} else {
			// update SKU reference counter only if product didn't exist
			if (!prodExists && skuExists) {
				skuId = sl.addSKU(desc);
			}
			
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

		Product memory p = products[id];

		RemovedProduct(id, skuId, p.price, p.stock);
	}

	function removeMerchant() public onlyByShopfront() {
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
