var SplitterLite = artifacts.require("./SplitterLite.sol");

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
    var fromBalBefore = eth.getBalance(u.alice);
    var to1BalBefore = eth.getBalance(u.bob);
    var to2BalBefore = eth.getBalance(u.carol);

    return contract.split(
      u.bob,
      u.carol,
      {from: u.alice, value: testValueEven})
    .then(function(txn) {
      return contract.balances(u.bob);
      
      // compute expected balances
      var value = testValueEven;
      var valueTo1 = Math.floor(value / 2);
      var valueTo2 = value - valueTo1;
      var fromBalAfter = fromBalBefore.minus(value);
      var to1BalAfter = to1BalBefore.minus(valueTo1);
      var to2BalAfter = to1BalBefore.minus(valueTo2);

      assert.strictEqual(eth.getBalance(u.alice), fromBalAfter, "Alice's expected balance doesn't match");
      assert.strictEqual(eth.getBalance(u.alice), fromBalAfter, "Alice's expected balance doesn't match");
      assert.strictEqual(eth.getBalance(u.alice), fromBalAfter, "Alice's expected balance doesn't match");

      // compute expected balances, handling case where test value is an odd number
      var user2ExpectedBalance = Math.floor(testValueEven / 2);
      var user1ExpectedBalance = testValueEven - user2ExpectedBalance;

      var _fromUserAddr = v[0];
      var _fromUserName = v[1];
      var _toUser1Addr = v[2];
      var _toUser1Name = v[3];
      var _toUser1Balance = v[4];
      var _toUser2Addr = v[5];
      var _toUser2Name = v[6];
      var _toUser2Balance = v[7];

      assert.equal(_fromUserAddr.toString(10), u.alice.addr.toString(10), "Incorrect from user address");
      assert.equal(_fromUserName, u.alice.name, "Incorrect from user name");
      assert.equal(_toUser1Addr.toString(10), u.bob.addr.toString(10), "Incorrect to user 1 address");
      assert.equal(_toUser1Name, u.bob.name, "Incorrect to user 1 name");
      assert.equal(_toUser1Balance.toString(10), user1ExpectedBalance, "Incorrect to user 1 balance");
      assert.equal(_toUser2Addr.toString(10), u.carol.addr.toString(10), "Incorrect to user 2 address");
      assert.equal(_toUser2Name, u.carol.name, "Incorrect to user 2 name");
      assert.equal(_toUser2Balance.toString(10), user2ExpectedBalance, "Incorrect to user 2 balance");
    });
  });

  // For handling throws with geth via Truffle, see: https://stackoverflow.com/a/40386159/3649726
  // Note that this eventually will not (reliably) work once Solidity is updated so that 
  // revert() behaves differently from throw and returns unused gas to caller.
  it("should refuse to add a duplicate splitter (same 'from' address)", function () {
    return contract.insertSplitter(
      u.alice.addr, 
      u.alice.name, 
      u.bob.addr, 
      u.bob.name, 
      u.carol.addr, 
      u.carol.name,
      {from: u.alice.addr, value: testValueEven})
    .then(function(txn) {
      return contract.insertSplitter(
        u.alice.addr, 
        u.alice.name, 
        u.bob.addr, 
        u.bob.name, 
        u.carol.addr, 
        u.carol.name,
        {from: u.alice.addr, value: testValueEven});
    })
    .then(function(txn) {
      var tx = web3.eth.getTransaction(txn.tx);
      var txr = txn.receipt;
      assert.strictEqual(txr.gasUsed, tx.gas, "Not all gas was used up, transaction did not throw.");
    });
  });

  it("should add a valid splitter with Alice, Bob and Carol, then a second one with Bob, David and Emma, with an odd amount of wei", function () {
    return contract.insertSplitter(
      u.alice.addr, 
      u.alice.name, 
      u.bob.addr, 
      u.bob.name, 
      u.carol.addr, 
      u.carol.name,
      {from: u.alice.addr, value: testValueEven})
    .then(function(txn) {
        return contract.insertSplitter(
          u.bob.addr, 
          u.bob.name, 
          u.david.addr, 
          u.david.name, 
          u.emma.addr, 
          u.emma.name,
          {from: u.bob.addr, value: testValueOdd});
      })
    .then(function(txn) {
      return contract.getSplitterAtIndex(1);
    })
    .then(function(v) {
      // compute expected balances, handling case where test value is an odd number
      var user2ExpectedBalance = Math.floor(testValueOdd / 2);
      var user1ExpectedBalance = testValueOdd - user2ExpectedBalance;

      var _fromUserAddr = v[0];
      var _fromUserName = v[1];
      var _toUser1Addr = v[2];
      var _toUser1Name = v[3];
      var _toUser1Balance = v[4];
      var _toUser2Addr = v[5];
      var _toUser2Name = v[6];
      var _toUser2Balance = v[7];

      assert.equal(_fromUserAddr.toString(10), u.bob.addr.toString(10), "Incorrect from user address");
      assert.equal(_fromUserName, u.bob.name, "Incorrect from user name");
      assert.equal(_toUser1Addr.toString(10), u.david.addr.toString(10), "Incorrect to user 1 address");
      assert.equal(_toUser1Name, u.david.name, "Incorrect to user 1 name");
      assert.equal(_toUser1Balance.toString(10), user1ExpectedBalance, "Incorrect to user 1 balance");
      assert.equal(_toUser2Addr.toString(10), u.emma.addr.toString(10), "Incorrect to user 2 address");
      assert.equal(_toUser2Name, u.emma.name, "Incorrect to user 2 name");
      assert.equal(_toUser2Balance.toString(10), user2ExpectedBalance, "Incorrect to user 2 balance");
    });
  });
});