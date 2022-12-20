var beaconApp = artifacts.require("combine_beacon");
var proxyFactory = artifacts.require("proxyFactory");

module.exports = async function(deployer, network, accounts) {

    // var beacon = await beaconApp.deployed();
    let beacon = {address:"0x6d2A307e32aE2D33181Dd6A955386d872836B610"}; 

    console.log("Beacon: ", beacon.address);
    await deployer.deploy(proxyFactory,beacon.address,accounts[0]);

    let proxyFactoryInstance = await proxyFactory.deployed();
    console.log("proxyFactoryInstance: ", proxyFactoryInstance.address);
}
