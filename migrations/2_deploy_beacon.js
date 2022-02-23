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


  console.log("Setting Pancakeswap");
  await beacon.setExchangeInfo('PANCAKESWAP',
      '0x73feaa1eE314F8c655E354234017bE2193C9E24E', //chefContract
      '0x10ED43C718714eb63d5aA57B78B54704E256024E', //routerContract
      '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', //rewardToken
      'pendingCake(uint256,address)',
      '0x0000000000000000000000000000000000000000',
      'MULTIEXCHANGE',
  );

  console.log("Setting Babyswap");
  await beacon.setExchangeInfo('BABYSWAP', // really BABYSWAP
      '0xdfaa0e08e357db0153927c7eabb492d1f60ac730', //chefContract
      '0x325E343f1dE602396E256B67eFd1F61C3A6B38Bd', //routerContract
      '0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95', //rewardToken
      'pendingCake(uint256,address)', //pendingCall
      '0x55d398326f99059ff775485246999027b3197955', //intermediateToken
      'MULTIEXCHANGE',
  );

  console.log("Setting Apeswap");
  await beacon.setExchangeInfo('APESWAP', // really BABYSWAP
      '0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9', //chefContract
      '0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7', //routerContract
      '0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95', //rewardToken
      'pendingCake(uint256,address)', //pendingCall
      '0x0000000000000000000000000000000000000000', //intermediateToken
      'MULTIEXCHANGE',
  );


  await beacon.setFee('DEFAULT','HARVESTSOLOGAS',7339,0);
  await beacon.setFee('DEFAULT','HARVESTPOOLGAS',7339,0);

  if (config.network == "development") {
      console.log("Setting HARVEST/COLLECTOR");
      await beacon.setAddress("HARVESTER",accounts[2]);
      console.log("HARVESTER");
      await beacon.setAddress("ADMINUSER",accounts[2]);
      console.log("ADMINUSER");
      await beacon.setAddress("FEECOLLECTOR",accounts[2]);
      console.log("FEECOLLECTOR");
      
      // console.log("Setting up PROXY App for testing");
      // await deployer.deploy(252, proxyApp, 'MULTIEXCHANGE', beaconApp.address, accounts[0]);
  }
  else {        
      console.log("Setting HARVEST/COLLECTOR");
      await beacon.setAddress("HARVESTER","0x0e0435B1aB9B9DCddff2119623e25be63ef5CB6e");
      await beacon.setAddress("ADMINUSER","0x0e0435B1aB9B9DCddff2119623e25be63ef5CB6e");
      await beacon.setAddress("FEECOLLECTOR","0x42a515c1EDB651F4c69c56E05578D2805D6451eB");
  }
  console.log("Setting fee");
  await beacon.setFee('DEFAULT', 'HARVEST', amt(19), 0);    
};

