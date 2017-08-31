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
    .then(function(
      _fromUserAddr,
      _fromUserName,
      _toUser1Addr,
      _toUser1Name,
      _toUser1Balance,
      _toUser2Addr,
      _toUser2Name,
      _toUser2Balance
    ) {
      // compute expected balances, handling case where test value is an odd number
      var user2ExpectedBalance = testValueEven / 2;
      var user1ExpectedBalance = testValueEven - user2ExpectedBalance;

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
});