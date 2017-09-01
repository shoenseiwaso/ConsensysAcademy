var Splitter = artifacts.require("./Splitter.sol");
var SplitterLite = artifacts.require("./SplitterLite.sol");

module.exports = function(deployer) {
  deployer.deploy(Splitter);
  deployer.deploy(SplitterLite);
};
