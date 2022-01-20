var beaconApp = artifacts.require("combine_beacon");
var combineApp = artifacts.require("combineApp");
var proxyFactory = artifacts.require("proxyFactory");
var slotsLib = artifacts.require("slotsLib");

if (config.network == "development") var proxyApp = artifacts.require("combine_proxy");

module.exports = async function(deployer, network, accounts) {
    if (config.network == "development") {
        accounts = await web3.eth.getAccounts();
        console.log("accounts: ", accounts);
    }

    await deployer.deploy(beaconApp);
    await deployer.deploy(slotsLib);
    await deployer.link(slotsLib,combineApp);
    await deployer.deploy(combineApp);
    
    let beacon = await beaconApp.deployed();
    await beacon.setExchange('MULTIEXCHANGE', combineApp.address, 0);

    console.log("Deploying Proxy Factory");
    await deployer.deploy(proxyFactory,beacon.address);
    let proxyFactoryInstance = await proxyFactory.deployed();
    console.log("proxyFactoryInstance: ", proxyFactoryInstance.address);
    
    console.log(`Deploy to: ${config.network}`);
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
        '0x53E562b9B7E5E94b81f10e96Ee70Ad06df3D2657', //rewardToken
        'pendingCake(uint256,address)', //pendingCall
        '0x55d398326f99059ff775485246999027b3197955', //intermediateToken
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
    
    // let ea = await beacon.getExchangeInfo('PANCAKESWAP');
    // console.log(ea);
    // console.log(config);
    
    // proxyInst.initialize(411, 10000000000000000000, '0x2320738301305c892B01f44E4E9854a2D19AE19e', '0x2320738301305c892B01f44E4E9854a2D19AE19e');
};