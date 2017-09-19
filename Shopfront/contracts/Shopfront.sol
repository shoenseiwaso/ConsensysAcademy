pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 5: Shopfront
//
// With thanks to Rob Hitchens' article on Solidity CRUD at:
// https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a

import "./SKULibrary.sol";
import "./Merchant.sol";

contract Shopfront {
	struct MerchantStruct {
		address merchContract;
		bool active;
	}

	mapping (address => MerchantStruct) public merchants;

	// Reverse lookup needed by isMerchant() which is in turn used by SKULibrary.
	mapping (address => bool) public merchantContracts;

	// global state variables
	address public owner;
	SKULibrary public sl;
	uint256 public ownerFee;

	event AddedMerchant(address sender, address merchOwner, address merchContract, uint256 sfFee);
	event RemovedMerchant(address sender, address merchOwner, address merchContract);
	event OwnerWithdraw(address sender, uint256 amount);

	function Shopfront(uint256 _ownerFee) {
		owner = msg.sender;
		ownerFee = _ownerFee;

		// setup SKULibrary
		sl = new SKULibrary(owner);
	}

	// only the owner can kill the whole contract
	modifier onlyByOwner()
	{
		require(msg.sender == owner);
		_;
	}

	function isMerchantContract(address merchContract) public constant returns (bool exists) {
		return merchantContracts[merchContract];
	}

	function addMerchant(address merchOwner) public onlyByOwner() {
		// ensure merchant doesn't already exist
		require(merchants[merchOwner].merchContract == address(0));

		merchants[merchOwner].merchContract = new Merchant(owner, merchOwner, sl, ownerFee);
		merchants[merchOwner].active = true;

		// add reverse lookup entry
		merchantContracts[merchants[merchOwner].merchContract] = true;

		AddedMerchant(msg.sender, merchOwner, merchants[merchOwner].merchContract, ownerFee);
	}

	function removeMerchant(address merchOwner) public onlyByOwner() {
		// ensure merchant exists and is active
		require(merchants[merchOwner].merchContract != address(0));
		require(merchants[merchOwner].active);

		merchants[merchOwner].active = false;

		// deactivate reverse lookup entry
		merchantContracts[merchants[merchOwner].merchContract] = false;

		// this is quite destructive but at least it refunds the merchant
		Merchant m = Merchant(merchants[merchOwner].merchContract);
		m.removeMerchant();

		RemovedMerchant(msg.sender, merchOwner, merchants[merchOwner].merchContract);
	}

	// Owner uses this to collect funds.
	function withdraw() public onlyByOwner() {
		require(this.balance > 0);

		OwnerWithdraw(msg.sender, this.balance);

		owner.transfer(this.balance);
	}

	// Does nothing to kill any merchant contracts.
	function kill() onlyByOwner() {
		sl.kill();

		selfdestruct(owner);
	}
}
