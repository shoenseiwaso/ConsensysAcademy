var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  var contract;

  var owner = accounts[0];

  var u = {
    alice: {name: "Alice", addr: accounts[0]},
    bob: {name: "Bob", addr: accounts[1]},
    carol: {name: "Carol", addr: accounts[2]},
    david: {name: "David", addr: accounts[3]},
    emma: {name: "Emma", addr: accounts[4]}
  };

  // in wei
  var testValueEven = 6;
  var testValueOdd = 7;

  beforeEach(function() {
    return Splitter.new({from: owner})
    .then(function(instance) {
      contract = instance;
    });
  });

  it("should add a valid splitter with Alice, Bob and Carol", function () {
    return contract.insertSplitter(
      u.alice.addr, 
      u.alice.name, 
      u.bob.addr, 
      u.bob.name, 
      u.carol.addr, 
      u.carol.name,
      {from: u.alice.addr, value: testValueEven})
    .then(function(txn) {
      return contract.getSplitterAtIndex(0);
    })
    .then(function(v) {
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