var beaconApp = artifacts.require("combine_beacon");
var proxyFactory = artifacts.require("proxyFactory");

module.exports = async function(deployer, network, accounts) {

    var beacon = await beaconApp.deployed();
    // let beacon = {address:"0x8422d0922d3bde86a8A96461Bcd3c301b8588860"}; 

    console.log("Beacon: ", beacon.address);
    await deployer.deploy(proxyFactory,beacon.address,accounts[0]);

    let proxyFactoryInstance = await proxyFactory.deployed();
    console.log("proxyFactoryInstance: ", proxyFactoryInstance.address);
}
