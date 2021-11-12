const truffleAssert = require('truffle-assertions');

const combineApp = artifacts.require("pancakeApp");
const combine_beacon = artifacts.require("combine_beacon");
const base_proxy = artifacts.require("combine_proxy");

function amt(val) {
    return val.toString() + "000000000000000000";
}

contract('combineApp', accounts => {
    it("Should deploy with proper logic contract", async() => {
        const base = await combineApp.deployed();
        const beacon = await combine_beacon.deployed();

        await beacon.setExchange("PANCAKESWAP", base.address, 0);
        beacon_logic_contract = await beacon.getExchange('PANCAKESWAP');
        assert(beacon_logic_contract == base.address, "Logic Contract not set");
        console.log("BLC", beacon_logic_contract);
    });

    it("Should set the pool ID", async() => {
        const app = await combineApp.at(base_proxy.address);
        assert(app.address == base_proxy.address, "App does not equal proxy address");

        let poolId = await app.poolId();
        assert(poolId == 0, "Initial Pool ID not 0: " + poolId.toString());

        await app.initialize(451, accounts[1], accounts[2]);
        poolId = await app.poolId();
        assert(poolId == 451, "Initial Pool ID not 451");
    });

    it("Fee should be immediately set", async() => {
        const app = await combine_beacon.deployed();
        let amt = (10 * (10 ** 18)).toString();
        await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
        fee = await app.getFee('PANCAKESWAP', 'HARVEST', accounts[0]);
        assert(fee == amt, "Fee Not Set");
    });


    it("Should handle deposit", async() => {
        const app = await combineApp.at(base_proxy.address);
        console.log("Balance before deposit:", await web3.eth.getBalance(accounts[0]));

        await app.deposit({ value: amt(125) });
        console.log("Balance after deposit:", await web3.eth.getBalance(accounts[0]));
        console.log("Userinfo:",JSON.stringify(await app.userInfo()));
        assert(userinfo[0] > 0, "Initial value should not be 0");
    });

    it("Should handle harvest", async() => {
        const app = await combineApp.at(base_proxy.address);
        let pc = await app.pendingReward();
        assert(pc == 0, "Initial Pending Cake should be 0 showing: " + pc.toString());

        await app.updatePool();
        pc = await app.pendingReward();
        assert(pc > 0, "Pending Cake should not be 0");

        fee0 = await web3.eth.getBalance(accounts[2]);
        await app.harvest();
        pc = await app.pendingReward();
        assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

        fee1 = await web3.eth.getBalance(accounts[2]);
        assert(fee1 > fee0, "Fee balance should have increased");
        console.log("Balance after harvest:", await web3.eth.getBalance(accounts[0]));
        
    });


    it("Should allow a liquidate from owner or admin only", async() => {
        const app = await combineApp.at(base_proxy.address);
        await app.updatePool();
        pc = await app.pendingReward();
        assert(pc > 0, "Pending Cake should not be 0");
        console.log("Balance before Liquidate:", await web3.eth.getBalance(accounts[0]));
        console.log("Userinfo:",JSON.stringify(await app.userInfo()));

        try {
            await app.liquidate({ from: accounts[1] });
            assert(false, "Allows liquidation from user not owner");
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows liquidation from user not owner");
        }

        let balance0 = await web3.eth.getBalance(accounts[0]);
        // console.log(accounts[0], balance);
        await app.liquidate();

        let balance1 = await web3.eth.getBalance(accounts[0]);

        console.log("Balance after Liquidate:", await web3.eth.getBalance(accounts[0]));
        console.log("Userinfo:",JSON.stringify(await app.userInfo()));
        assert(balance1 > balance0, "Funds not liquidated");
    });

});