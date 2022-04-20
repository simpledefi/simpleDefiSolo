var beaconApp = artifacts.require("combine_beacon");
var proxyFactory = artifacts.require("proxyFactory");

module.exports = async function(deployer, network, accounts) {

    var beacon = await beaconApp.deployed();
    console.log("Beacon: ", beacon.address);
    await deployer.deploy(proxyFactory,beacon.address,accounts[0]);

    let proxyFactoryInstance = await proxyFactory.deployed();
    console.log("proxyFactoryInstance: ", proxyFactoryInstance.address);
}
