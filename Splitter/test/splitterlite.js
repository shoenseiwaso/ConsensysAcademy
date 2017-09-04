var SplitterLite = artifacts.require("./SplitterLite.sol");

function allGasUsedUp(txn) {
  // check that given transaction didn't throw an exception by running out of gas
  var tx = web3.eth.getTransaction(txn.tx);
  var txr = txn.receipt;

  return txr.gasUsed === tx.gas;
}

contract('SplitterLite', function(accounts) {
  var contract;

  var u = {
    alice: accounts[0],
    bob: accounts[1],
    carol: accounts[2],
    david: accounts[3],
    emma: accounts[4]
  };

  // in wei
  var testValueEven = 6;
  var testValueOdd = 7;

  beforeEach(function() {
    return SplitterLite.new({from: u.alice})
    .then(function(instance) {
      contract = instance;
    });
  });

  it("Alice splits an even amount of wei between Bob and Carol", function () {
    // compute expected values
    var value = testValueEven;
    var valueTo1 = Math.floor(value / 2);
    var valueTo2 = value - valueTo1;

    return contract.split(
      u.bob,
      u.carol,
      {from: u.alice, value: value})
    .then(function(txn) {
      // check that split() didn't throw by running out of gas
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, split() threw an exception.");

      // Check Alice's balance.
      // Note that this simple check works because her account is the etherbase,
      // i.e., transaction fees are a wash.
      //assert.strictEqual(web3.eth.getBalance(u.alice).plus(value).toString(10), fromBalBefore.toString(10), "Alice's expected balance doesn't match");
      //
      // This turned out to be impossible, or at least very difficult, due to side effects: if alice is 
      // the etherbase, then mining fees come to her could make her not the etherbase, but then it becomes 
      // an exercise in also calculating transaction fees.
      // Going to ignore this for now.

      return contract.balances(u.bob);
    })
    .then(function(to1BalAfter) {
      assert.equal(to1BalAfter.toString(10), valueTo1, "Bob's expected balance doesn't match");

      return contract.balances(u.carol);
    })
    .then(function(to2BalAfter) {
      assert.equal(to2BalAfter.toString(10), valueTo2, "Carol's expected balance doesn't match");
    });
  });

  it("Alice splits an odd amount of wei between David and Emma, David withdraws, then contract is killed", function () {
    // compute expected values
    var value = testValueOdd;
    var valueTo1 = Math.floor(value / 2);
    var valueTo2 = value - valueTo1;

    return contract.split(
      u.david,
      u.emma,
      {from: u.alice, value: value})
    .then(function(txn) {
      // check that split() didn't throw by running out of gas
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, split() threw an exception.");

      return contract.balances(u.david);
    })
    .then(function(to1BalAfter) {
      assert.equal(to1BalAfter.toString(10), valueTo1, "David's expected balance doesn't match");

      return contract.balances(u.emma);
    })
    .then(function(to2BalAfter) {
      assert.equal(to2BalAfter.toString(10), valueTo2, "Emma's expected balance doesn't match");

      return contract.kill({from: u.alice});
    })
    .then(function(txn) {
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, kill() threw an exception.");

      return contract.split(
        u.david,
        u.emma,
        {from: u.alice, value: value});
    })
    .then(function(txn) {
      assert.isNotTrue(allGasUsedUp(txn), "All gas was used up, split() threw an exception.");

      return contract.owner();
    })
    .then(function(_owner) {
      // see: https://ethereum.stackexchange.com/questions/8482/how-can-i-check-if-a-contract-has-self-destructed-in-solidity
      assert.equal(_owner.toString(), "0x", "Owner was not zeroed out after kill(), contract still active.");
    });
  });
});