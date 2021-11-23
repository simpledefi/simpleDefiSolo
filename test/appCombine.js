const truffleAssert = require('truffle-assertions');

const combineApp = artifacts.require("combineApp");
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

    it("Should not allow reinitialization", async() => {
        const app = await combineApp.at(base_proxy.address);
        try {
            await app.initialize(412, '0x2320738301305c892B01f44E4E9854a2D19AE19e', '0x2320738301305c892B01f44E4E9854a2D19AE19e');
            assert(false, "Allowed Reinitialization");
        } catch (e) {
            assert(e.message.includes("Already Initialized"), "Allowed Reinitialization");
        }
    });

    // it("Should have proper token addresses", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     let lp = await app.lpContract();
    //     let token0 = await app.token0();
    //     let token1 = await app.token1();
    //     // console.log(lp, token0, token1);
    //     assert(lp.toLowerCase() == '0x7759283571Da8c0928786A96AE601944E10461Ff'.toLowerCase(), "Invalid Liquidity Pool address");
    //     assert(token0.toLowerCase() == '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56'.toLowerCase(), "Invalid Token 0 address");
    //     assert(token1.toLowerCase() == '0xee9801669c6138e84bd50deb500827b776777d28'.toLowerCase(), "Invalid Token 1 address");
    // });

    it("Should restrict admin functions", async() => {
        const app = await combineApp.at(base_proxy.address);
        try {
            await app.harvest({ from: accounts[3] });
            assert(1 == 2, "Harvest Function  should be restricted");
        } catch (e) {
            assert(e.message.includes("Restricted Function"), "Harvest function should be restricted");
        }

        try {
            await app.setPool(400, { from: accounts[3] });
            assert(1 == 2, "setPool Function  should be restricted");
        } catch (e) {
            assert(e.message.includes("Restricted Function"), "setPool function should be restricted");
        }

        try {
            await app.swapPool(400, { from: accounts[3] });
            assert(1 == 2, "swapPool Function  should be restricted");
        } catch (e) {
            assert(e.message.includes("Restricted Function"), "swapPool function should be restricted");
        }
    });

    it("Should handle deposit", async() => {
        const app = await combineApp.at(base_proxy.address);
        let userinfo = await app.userInfo();
        console.log(JSON.stringify(userinfo));
        assert(userinfo[0] == 0, "Initial value should be 0");
        await app.deposit({ value: amt(125) });
        userinfo = await app.userInfo();
        console.log(JSON.stringify(userinfo));
        assert(userinfo[0] > 0, "Initial value should not be 0");
    });

    it("Should handle harvest", async() => {
        const app = await combineApp.at(base_proxy.address);
        let pc = await app.pendingReward();
        assert(pc == 0, "Initial Pending Cake should be 0 showing: " + pc.toString());

        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        pc = await app.pendingReward();
        console.log("PC", pc.toString());
        assert(pc == 0, "Pending Cake should not be 0");

        fee0 = await web3.eth.getBalance(accounts[2]);
        await app.harvest();
        pc = await app.pendingReward();
        assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

        fee1 = await web3.eth.getBalance(accounts[2]);
        assert(fee1 > fee0, "Fee balance should have increased");
    });

    it("Should clear out cake after deposit", async() => {
        const app = await combineApp.at(base_proxy.address);

        await app.updatePool();
        await app.updatePool();
        let pc0 = await app.pendingReward().stringify();
        await app.deposit({ value: 1 * (10 ** 18) });
        pc1 = await app.pendingReward();
        assert(pc1 < pc0 && pc0>0, `Pending cake not cleared out ${pc1} ${pc0}`);
    });



    it("Should allow a liquidate from owner or admin only", async() => {
        const app = await combineApp.at(base_proxy.address);
        await app.updatePool();
        pc = await app.pendingReward();
        assert(pc == 0, "Pending Cake should not be 0");

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
        assert(balance1 > balance0, "Funds not liquidated");
    });

    it("Should allow pool swap", async() => {
        const app = await combineApp.at(base_proxy.address);

        await app.deposit({ value: 1 * (10 ** 18) });
        await app.swapPool(427);
        let pid = await app.poolId();
        assert(pid == 427, "Pool did not swap");
    });

    it("Should allow set pool without balance", async() => {
        const app = await combineApp.at(base_proxy.address);
        let userinfo = await app.userInfo();
        assert(userinfo[0] > 0, "Initial value should not be 0");
        try {
            await app.setPool(411);
        } catch (e) {
            assert(e.message.includes("Currently invested in a pool, unable to change"), "Should not be able to set pool id with balance");
        }
        await app.liquidate();

        try {
            await app.setPool(411);
        } catch (e) {
            assert(e.message.includes("Currently invested in a pool, unable to change"), "Liquidation did not clear balance");
        }
        let pid = await app.poolId();

        assert(pid == 411, "Pool id did not get properly set");
    });

    it("Should allow deposit into new pool", async() => {
        const app = await combineApp.at(base_proxy.address);
        let userinfo = await app.userInfo();
        let balance0 = userinfo[0];
        await app.deposit({ value: 1 * (10 ** 18) });
        userinfo = await app.userInfo();
        assert(userinfo[0] > balance0, "Balance should have increased");

    });

    it("Should handle handle harvest in new pool", async() => {
        const app = await combineApp.at(base_proxy.address);
        pc0 = await app.pendingReward();
        await app.updatePool();
        pc1 = await app.pendingReward();
        assert(pc1 > pc0, "Pending Cake should increase");

        fee0 = await web3.eth.getBalance(accounts[2]);
        await app.harvest();
        pc = await app.pendingReward();
        assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

        fee1 = await web3.eth.getBalance(accounts[2]);
        assert(fee1 > fee0, "Fee balance should have increased");
    });

    it("Should reject deposit from 3rd party", async() => {
        const app = await combineApp.at(base_proxy.address);
        try {
            await app.deposit({ value: 1 * (10 ** 18), from: accounts[2] });
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows deposit from 3rd party");
        }
    });

    it("Should disallow allow 3rd Party to set holdback", async() => {
        const app = await combineApp.at(base_proxy.address);
        try {
            await app.setHoldBack((1 * (10 ** 18)).toString(), { from: accounts[2] });
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows setHoldBack from 3rd party");
        }
    });

    it("Should disallow allow 3rd Party to call rescue token", async() => {
        const app = await combineApp.at(base_proxy.address);
        try {
            await app.rescueToken('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', {
                from: accounts[2]
            });
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows rescueToken from 3rd party");
        }
    });

    it("Should allow holdback and send BNB to parent account", async() => {
        const app = await combineApp.at(base_proxy.address);
        await app.setHoldBack(amt(10));
        await app.deposit({ value: amt(10) });
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        result = await app.harvest();
        truffleAssert.eventEmitted(result, "HoldBack", (ev) => {
            return ev.amount > 0;
        });

        await app.setHoldBack(0);
        await app.updatePool();
        await app.updatePool();
        await app.updatePool();
        result = await app.harvest();
        truffleAssert.eventNotEmitted(result, "HoldBack");
    });
});