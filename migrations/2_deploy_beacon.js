var beaconApp = artifacts.require("combine_beacon");

function amt(val) {
  return val.toString() + "000000000000000000";
}



module.exports = async function(deployer, network, accounts) {
  if (config.network == "development") {
    accounts = await web3.eth.getAccounts();
    console.log("accounts: ", accounts);
  }

  await deployer.deploy(beaconApp);
  var beacon = await beaconApp.deployed();
  console.log("Beacon: ", beacon.address);

};

