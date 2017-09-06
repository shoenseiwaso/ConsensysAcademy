pragma solidity ^0.4.4;

// Consensys Academy 2017
// Jeff Wentworth (github: shoenseiwaso)
// Module 4: Remittance
//
// This is setup as a contract which can be re-used by the owner multiple times to facilitate three
// way transactions, where the owner takes a cut each time.

contract Remittance {
	// state variables
	address public owner = msg.sender;
	uint public trackedBalance = 0;
	address public remitter;
	address public recipient = address(0);
	bytes32 public pwHash;
	uint public deadline;

	uint constant MAX_DEADLINE = 7 days;

	// This should be set to a value smaller than the gas estimate required to deploy the contract,
	// in order for it to make economic sense for the remitter to use this contract vs. deploy their own.
	// Making this a constant makes the contract deployment and operation slightly less expensive, 
	// at the cost of it being fixed for the duration of the contract.
	uint constant OWNER_FEE = 1000 wei;

	event Remit(address indexed _remitter, address indexed _recipient, bytes32 _pwHash, uint _deadline, uint _value);
	event Withdraw(address indexed _withdrawer, uint _value, uint _fee);

	// Go straight to stretch goal and make one password the recipient's address.
	// Security hole is that cleartext passwords can be read by anyone on the blockchain, and a 
	// race condition could even exist where a pending transaction that is propagated before included in a mined
	// block is intercepted by a bad actor and they in turn create an equivalent transaction with higher gas
	// to steal the funds.
	//
	// A better but more expensive gas-wise option for this would be to have the remitter positively 
	// sign the transaction.
	function remit(address _recipient, bytes32 _pwHash, uint _timeout) public payable returns (bool success) {
		require(recipient == address(0));
		require(_timeout <= MAX_DEADLINE);
		require(msg.value > OWNER_FEE); // must be able to at least pay the owner fee
		require(trackedBalance == 0); // ensure contract is not currently in use (balance before this call was 0)

		trackedBalance = msg.value;
		remitter = msg.sender;
		recipient = _recipient;
		pwHash = _pwHash;
		deadline = now + _timeout;

		Remit(msg.sender, _recipient, _pwHash, deadline, msg.value);

		return true;
	}

	// Use the preferred withdrawal pattern rather than the send pattern.
	// see: http://solidity.readthedocs.io/en/develop/common-patterns.html#withdrawal-from-contracts
	//
	// Callable by the recipient, or by the remitter once the deadline has passed.
	function withdraw(bytes32 _pw) public returns (bool success) {
		require(trackedBalance > 0); // ensure remit() has been called
		require(msg.sender == recipient || (msg.sender == remitter && now > deadline));
		require(pwHash == keccak256(_pw));

		uint amount = trackedBalance - OWNER_FEE;

		// Effectively reset the contract so it can be used again.
		// Do this before transfer() to mitigate rentrant attack vector.
		trackedBalance = 0;

        msg.sender.transfer(amount); // send the recipient (or refund the remitter) the balance less the owner's fee
		owner.transfer(this.balance); // pay the owner their fee

		// Reset the contract in a gas-efficient way.
		// Do this to avoid a re-entrant attack vector where the recipient called remit() during msg.sender.transfer()
		recipient = address(0);

		Withdraw(msg.sender, amount, OWNER_FEE);

		return true;
    }

	// Kill the contract and return remaining balance back to the remitter.
	function kill() public returns (bool success) { 
		require(msg.sender == owner);
		selfdestruct(remitter);

		return true;
	}
}
