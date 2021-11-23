var beaconApp = artifacts.require("combine_beacon");
var combineApp = artifacts.require("combineApp");
var proxyApp = artifacts.require("combine_proxy");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(beaconApp);
    await deployer.deploy(combineApp);
    let ba = await beaconApp.deployed();
    await ba.setExchange('PANCAKESWAP', combineApp.address, 0);
    await deployer.deploy(proxyApp, 'PANCAKESWAP', beaconApp.address, accounts[1]);
    // proxyInst.initialize(411, 10000000000000000000, '0x2320738301305c892B01f44E4E9854a2D19AE19e', '0x2320738301305c892B01f44E4E9854a2D19AE19e');
};