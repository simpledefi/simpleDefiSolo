var beaconApp = artifacts.require("combine_beacon");
var combineApp = artifacts.require("combineApp");
var slotsLib = artifacts.require("slotsLib");

function amt(val) {
    return val.toString() + "000000000000000000";
}


module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(slotsLib);
    await deployer.link(slotsLib,combineApp);
    await deployer.deploy(combineApp);

    var beacon = await beaconApp.deployed();
    
    await beacon.setExchange('MULTIEXCHANGE', combineApp.address, 0);
}
