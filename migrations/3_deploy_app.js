var beaconApp = artifacts.require("combine_beacon");
var combineApp = artifacts.require("combineApp");
var slotsLib = artifacts.require("slotsLib");
let OWNER_ADDR = "0x0e0435b1ab9b9dcddff2119623e25be63ef5cb6e";

function amt(val) {
    return val.toString() + "000000000000000000";
}


module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(slotsLib);
    await deployer.link(slotsLib,combineApp);
    await deployer.deploy(combineApp);

    // var beacon = await beaconApp.deployed();
    let beacon_addr = "0x6d2A307e32aE2D33181Dd6A955386d872836B610";
    var beacon = await beaconApp.at(beacon_addr);
    
    await beacon.setExchange('MULTIEXCHANGE', combineApp.address, 0,{from: OWNER_ADDR});
}
