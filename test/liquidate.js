// const { iterator } = require('core-js/fn/symbol');
const truffleAssert = require('truffle-assertions');
const { default: Web3 } = require('web3');

const combineApp = artifacts.require("combineApp");
const proxyFactory = artifacts.require("proxyFactory");


function amt(val) {
    return val.toString() + "000000000000000000";
}

let app;

contract('combineApp', accounts => {
    let pool_ID = 251; //BUSD-BNB

    it('should deploy combineApp with initial deposit of 125', async () => {
        let pF = await proxyFactory.at("0x93aB5B17739c25D836a949e7F74daD8bDBb0Ec62");
        console.log("proxyFactory: ", pF.address);
        let proxyApp = await pF.initialize(pool_ID,"PANCAKESWAP",{value: amt(66)});
        let proxyAddr = await pF.getLastProxy(accounts[0]);
        app = await combineApp.at(proxyAddr);

        let logProxy =  proxyApp['logs'][1]['args']['0'];
        assert(logProxy == proxyAddr,"Proxy Address missmatch");

        console.log("lastProxy: ", proxyAddr);
        let userinfo = await app.userInfo();
        console.log('after:', JSON.stringify(userinfo));

        console.log("Done deploy")
    });    

    it("Should handle harvest", async() => {
        let pc = await app.pendingReward();
        console.log("Pending:",pc);
        assert(pc == 0, "Initial Pending Cake should be 0 showing: " + pc.toString());

        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        pc = await app.pendingReward();
        console.log("PC", pc.toString());
        assert(pc != 0, "Pending Cake should not be 0");

        await app.harvest();
        pc = await app.pendingReward();
        assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());
    });

    
    it("Should allow a liquidate from owner or admin only", async() => {
        await app.updatePool();
        let pc = await app.pendingReward();
        assert(pc != 0, "Pending Cake should not be 0");

        try {
            await app.liquidate({ from: accounts[1] });
            assert(false, "Allows liquidation from user not owner");
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows liquidation from user not owner");
        }

        let userinfo = await app.userInfo();
        console.log('before:', userinfo[0].toString());
        let balance0 = await web3.eth.getBalance(accounts[0]);

        await app.liquidate();

        userinfo = await app.userInfo();
        console.log('after:', userinfo[0].toString());

        assert(userinfo[0].toString() == 0, "Liquidate should set userInfo to 0");

        let balance1 = await web3.eth.getBalance(accounts[0]);
        assert(balance1 > balance0, "Funds not liquidated");
    });
});