var combineApp = artifacts.require("combineApp");
var proxyApp = artifacts.require("combine_proxy");
module.exports = function(deployer, network, accounts) {
    deployer.deploy(combineApp);
    deployer.deploy(proxyApp, combineApp.address, accounts[1]);
    // proxyInst.initialize(411, 10000000000000000000, '0x2320738301305c892B01f44E4E9854a2D19AE19e', '0x2320738301305c892B01f44E4E9854a2D19AE19e');
};