var Remittance = artifacts.require("./Remittance.sol");

function allGasUsedUp(txn) {
  // check that given transaction didn't throw an exception by running out of gas
  var tx = web3.eth.getTransaction(txn.tx);
  var txr = txn.receipt;

  return txr.gasUsed === tx.gas;
}

contract('Remittance', function(accounts) {
  var contract;
  
  var u = {
    alice: accounts[0],
    bob: accounts[1],
    carol: accounts[2],
    david: accounts[3],
    emma: accounts[4]
  };

  // in wei
  var testValue = web3.toWei(1, "ether");
  var pw = "random phrase";
  
  var pwHash = "0xdadde2699200ad2b8a51ccaa19bcb954043c85bbf6d60020951db5166064aff6"
  // web3.sha3(pw); didn't work, so just used a dummy contract in Remix to get this value
  // see: https://ethereum.stackexchange.com/questions/12667/how-to-sha3-strings-and-integers-with-javascript
  
  var longTimeout = 24 * 60 * 60;
  var shortTimeout = 0;

  beforeEach(function() {
    return Remittance.new({from: u.alice})
    .then(function(instance) {
      contract = instance;
    });
  });

  it("Alice sends funds to Bob via Carol's Exchange shop", function () {
    return contract.remit(
      u.carol,
      pwHash,
      longTimeout,
      {from: u.alice, value: testValue})
    .then(function(txn) {
      // check that an exception wasn't thrown
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, remit() threw an exception.");

      return web3.eth.getBalance(contract.address);
    })
    .then(function(bal) {
      assert.equal(bal, testValue, "Remittance contract does not have the expected balance.")

      return contract.withdraw(pw, {from: u.carol});
    })
    .then(function(txn) {
      // check that an exception wasn't thrown
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, withdraw() threw an exception.");

      return web3.eth.getBalance(contract.address);
    })
    .then(function(bal) {
      assert.equal(bal, 0, "Remittance contract still has a balance left on it.")
    });
  });

  it("David tries to send funds to Emma, but it times out and David claims the funds back", function () {
    return contract.remit(
      u.emma,
      pwHash,
      shortTimeout,
      {from: u.david, value: testValue})
    .then(function(txn) {
      // check that an exception wasn't thrown
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, remit() threw an exception.");

      return web3.eth.getBalance(contract.address);
    })
    .then(function(bal) {
      assert.equal(bal, testValue, "Remittance contract does not have the expected balance.")

      return contract.withdraw(pw, {from: u.david});
    })
    .then(function(txn) {
      // check that an exception wasn't thrown
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, withdraw() threw an exception.");

      return web3.eth.getBalance(contract.address);
    })
    .then(function(bal) {
      assert.equal(bal, 0, "Remittance contract still has a balance left on it.")
    });
  });
});