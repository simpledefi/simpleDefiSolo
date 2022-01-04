// const { iterator } = require('core-js/fn/symbol');
const truffleAssert = require('truffle-assertions');

const combineApp = artifacts.require("combineApp");
const combine_beacon = artifacts.require("combine_beacon");
const base_proxy = artifacts.require("combine_proxy");
const _proxyFactory = artifacts.require("proxyFactory");
const ERC20 = artifacts.require("ERC20");

function amt(val) {
    return val.toString() + "000000000000000000";
}

contract('combineApp', accounts => {
    let proxyApp;

    it('should deploy combineApp', async () => {
        let proxyFactory = await _proxyFactory.deployed();
        console.log("proxyFactory: ", proxyFactory.address);
        proxyApp = await proxyFactory.initialize(252,"MULTIEXCHANGE","PANCAKESWAP",{value: amt(125)});
        console.log("proxyApp: ", proxyApp);
    });
    // it("Should deploy with proper logic contract", async() => {
    //     const base = await combineApp.deployed();
    //     const beacon = await combine_beacon.deployed();


    //     await beacon.setExchange("MULTIEXCHANGE", base.address, 0);
    //     let beacon_logic_contract = await beacon.getExchange('MULTIEXCHANGE');
    //     assert(beacon_logic_contract == base.address, "Logic Contract not set");
    //     let rv = await beacon.getExchangeInfo('PANCAKESWAP');
    //     console.log(rv);
    //     // assert(rv['_chefContract'] == '0x73feaa1eE314F8c655E354234017bE2193C9E24E', "Chef Contract not set");
    //     // assert(rv['_routerContract'] == '0x10ED43C718714eb63d5aA57B78B54704E256024E', "Router Contract not set");
    //     // assert(rv['_rewardToken'] == '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', "Reward Token not set");
    //     console.log("BLC", beacon_logic_contract);
    // });

    // let pool_ID = 252; //BUSD-BNB
    // let new_Pool = 251;
    // let swap_ID = 447;

    // it("Should set the pool ID", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     const beacon = await combine_beacon.deployed();

    //     assert(app.address == base_proxy.address, "App does not equal proxy address");

    //     let poolId = await app.poolId();
    //     assert(poolId == 0, "Initial Pool ID not 0: " + poolId.toString());

    //     await app.initialize(pool_ID, beacon.address, "PANCAKESWAP");
    //     poolId = await app.poolId();
    //     assert(poolId == pool_ID, "Initial Pool ID not set");
    // });

    // it("Fee should be immediately set", async() => {
    //     const app = await combine_beacon.deployed();
    //     let amt = (10 * (10 ** 18)).toString();
    //     await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
    //     let fee = await app.getFee('PANCAKESWAP', 'HARVEST', accounts[0]);
    //     assert(fee == amt, "Fee Not Set");
    // });

    // it("Should not allow reinitialization", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     try {
    //         await app.initialize(pool_ID-1, '0x2320738301305c892B01f44E4E9854a2D19AE19e', '0x2320738301305c892B01f44E4E9854a2D19AE19e');
    //         assert(false, "Allowed Reinitialization");
    //     } catch (e) {
    //         assert(e.message.includes("Already Initialized"), "Allowed Reinitialization");
    //     }
    // });

    // it("Should restrict admin functions", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     try {
    //         await app.harvest({ from: accounts[3] });
    //         assert(1 == 2, "Harvest Function  should be restricted");
    //     } catch (e) {
    //         assert(e.message.includes("Restricted Function"), "Harvest function should be restricted");
    //     }

    //     try {
    //         await app.setPool(400, { from: accounts[3] });
    //         assert(1 == 2, "setPool Function  should be restricted");
    //     } catch (e) {
    //         assert(e.message.includes("Restricted Function"), "setPool function should be restricted");
    //     }

    //     try {
    //         await app.swapPool(400, { from: accounts[3] });
    //         assert(1 == 2, "swapPool Function  should be restricted");
    //     } catch (e) {
    //         assert(e.message.includes("Restricted Function"), "swapPool function should be restricted");
    //     }
    // });

    // it("Should handle deposit", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     let userinfo = await app.userInfo();
    //     console.log(JSON.stringify(userinfo));
    //     assert(userinfo[0] == 0, "Initial value should be 0");
    //     await app.deposit({ value: amt(125) });
    //     userinfo = await app.userInfo();
    //     console.log(JSON.stringify(userinfo));
    //     assert(userinfo[0] > 0, "Initial value should not be 0");
    // });

    // it("Should handle harvest", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     let pc = await app.pendingReward();
    //     console.log("Pending:",pc);
    //     assert(pc == 0, "Initial Pending Cake should be 0 showing: " + pc.toString());

    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     pc = await app.pendingReward();
    //     console.log("PC", pc.toString());
    //     assert(pc != 0, "Pending Cake should not be 0");

    //     fee0 = await web3.eth.getBalance(accounts[2]);
    //     await app.harvest();
    //     pc = await app.pendingReward();
    //     assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

    //     fee1 = await web3.eth.getBalance(accounts[2]);
    //     assert(fee1 > fee0, "Fee balance should have increased");
    // });

    // it("Should clear out cake after deposit", async() => {
    //     const app = await combineApp.at(base_proxy.address);

    //     await app.updatePool();
    //     await app.updatePool();
    //     let pc0 = await app.pendingReward();
    //     await app.deposit({ value: 1 * (10 ** 18) });
    //     pc1 = await app.pendingReward();
    //     assert(pc1 < pc0 && pc0>0, `Pending cake not cleared out ${pc1} ${pc0}`);
    // });

    // it("Should allow a liquidate from owner or admin only", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     await app.updatePool();
    //     let pc = await app.pendingReward();
    //     assert(pc != 0, "Pending Cake should not be 0");

    //     try {
    //         await app.liquidate({ from: accounts[1] });
    //         assert(false, "Allows liquidation from user not owner");
    //     } catch (e) {
    //         assert(e.message.includes("caller is not the owner"), "Allows liquidation from user not owner");
    //     }

    //     let balance0 = await web3.eth.getBalance(accounts[0]);
    //     // console.log(accounts[0], balance);
    //     await app.liquidate();

    //     let balance1 = await web3.eth.getBalance(accounts[0]);
    //     assert(balance1 > balance0, "Funds not liquidated");
    // });

    // it("Should allow pool swap", async() => {
    //     const app = await combineApp.at(base_proxy.address);

    //     await app.deposit({ value: 1 * (10 ** 18) });
    //     try {
    //         await app.swapPool(swap_ID);
    //         assert(false,`Allowed Swap Pool to inactive pool ${pool_ID} `);
    //     }
    //     catch (e) {
    //         assert(e.message.includes("Pool must be active"), "Allowed Reinitialization");
    //     }
    //     // let pid = await app.poolId();
    //     // assert(pid == swap_ID, "Pool did not swap");
    // });

    // it("Should allow set pool without balance", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     let userinfo = await app.userInfo();
    //     assert(userinfo[0] > 0, "Initial value should not be 0");
    //     try {
    //         await app.setPool(pool_ID - 11);
    //     } catch (e) {
    //         assert(e.message.includes("Currently invested in a pool, unable to change"), "Should not be able to set pool id with balance");
    //     }
    //     await app.liquidate();

    //     try {
    //         await app.setPool(new_Pool);
    //     } catch (e) {
    //         assert(e.message.includes("Currently invested in a pool, unable to change"), "Liquidation did not clear balance");
    //     }
    //     let pid = await app.poolId();

    //     assert(pid == new_Pool, "Pool id did not get properly set");
    // });

    // it("Should allow deposit into new pool", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     let userinfo = await app.userInfo();
    //     let balance0 = userinfo[0];
    //     await app.deposit({ value: 1 * (10 ** 18) });
    //     userinfo = await app.userInfo();
    //     assert(userinfo[0] > balance0, "Balance should have increased");

    // });

    // it("Should handle handle harvest in new pool", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     pc0 = await app.pendingReward();
    //     await app.updatePool();
    //     pc1 = await app.pendingReward();
    //     assert(pc1 > pc0, "Pending Cake should increase");

    //     fee0 = await web3.eth.getBalance(accounts[2]);
    //     await app.harvest();
    //     pc = await app.pendingReward();
    //     assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

    //     fee1 = await web3.eth.getBalance(accounts[2]);
    //     assert(fee1 > fee0, "Fee balance should have increased");
    // });

    // it("Should reject deposit from 3rd party", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     try {
    //         await app.deposit({ value: 1 * (10 ** 18), from: accounts[2] });
    //     } catch (e) {
    //         assert(e.message.includes("caller is not the owner"), "Allows deposit from 3rd party");
    //     }
    // });

    // it("Should disallow allow 3rd Party to set holdback", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     try {
    //         await app.setHoldBack((1 * (10 ** 18)).toString(), { from: accounts[2] });
    //     } catch (e) {
    //         assert(e.message.includes("caller is not the owner"), "Allows setHoldBack from 3rd party");
    //     }
    // });

    // it("Should disallow allow 3rd Party to call rescue token", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     try {
    //         await app.rescueToken('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', {
    //             from: accounts[2]
    //         });
    //     } catch (e) {
    //         assert(e.message.includes("caller is not the owner"), "Allows rescueToken from 3rd party");
    //     }
    // });

    // it("Should allow holdback and send BNB to parent account", async() => {
    //     const app = await combineApp.at(base_proxy.address);
    //     await app.setHoldBack(amt(10));
    //     await app.deposit({ value: amt(10) });
    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     result = await app.harvest();
    //     truffleAssert.eventEmitted(result, "HoldBack", (ev) => {
    //         return ev.amount > 0;
    //     });

    //     await app.setHoldBack(0);
    //     await app.updatePool();
    //     await app.updatePool();
    //     await app.updatePool();
    //     result = await app.harvest();
    //     truffleAssert.eventNotEmitted(result, "HoldBack");
    // });

    // it("Should have no WBNB left in the token", async() => {
    //     //web3 get erc20 token balance of user
    //     let erc20 = await ERC20.at("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c");
    //     let balance = await erc20.balanceOf(accounts[0]);
    //     console.log("WBNB Balance:",balance)
    //     assert(balance == 0, "Should not have any WBNB left");
    // });

    // if (1==1) {    
    //     it("should set new echange",async() => {
    //         console.log("Switching to babyswap")
    
    //         pool_ID = 132; //babyswap  
    //         new_Pool = 131;
    //         swap_ID = 130;
    //         const app = await combineApp.at(base_proxy.address);
    //         await app.liquidate();
    //         await app.newExchange(pool_ID,"BABYSWAP")
    //     });
        
    //     it("Should handle deposit", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         let userinfo = await app.userInfo();
    //         console.log(JSON.stringify(userinfo));
    //         assert(userinfo[0] == 0, "Initial value should be 0");
    //         await app.deposit({ value: amt(125) });
    //         userinfo = await app.userInfo();
    //         console.log(JSON.stringify(userinfo));
    //         assert(userinfo[0] > 0, "Initial value should not be 0");
    //     });

    //     it("Should handle harvest", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         let pc = await app.pendingReward();
    //         console.log("Pending:",pc);
    //         assert(pc == 0, "Initial Pending Cake should be 0 showing: " + pc.toString());

    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         pc = await app.pendingReward();
    //         console.log("PC", pc.toString());
    //         assert(pc != 0, "Pending Cake should not be 0");

    //         fee0 = await web3.eth.getBalance(accounts[2]);
    //         await app.harvest();
    //         pc = await app.pendingReward();
    //         assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

    //         fee1 = await web3.eth.getBalance(accounts[2]);
    //         assert(fee1 > fee0, "Fee balance should have increased");
    //     });

    //     it("Should clear out cake after deposit", async() => {
    //         const app = await combineApp.at(base_proxy.address);

    //         await app.updatePool();
    //         await app.updatePool();
    //         let pc0 = await app.pendingReward();
    //         await app.deposit({ value: 1 * (10 ** 18) });
    //         pc1 = await app.pendingReward();
    //         assert(pc1 < pc0 && pc0>0, `Pending cake not cleared out ${pc1} ${pc0}`);
    //     });

    //     it("Should allow a liquidate from owner or admin only", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         await app.updatePool();
    //         let pc = await app.pendingReward();
    //         assert(pc != 0, "Pending Cake should not be 0");

    //         try {
    //             await app.liquidate({ from: accounts[1] });
    //             assert(false, "Allows liquidation from user not owner");
    //         } catch (e) {
    //             assert(e.message.includes("caller is not the owner"), "Allows liquidation from user not owner");
    //         }

    //         let balance0 = await web3.eth.getBalance(accounts[0]);
    //         // console.log(accounts[0], balance);
    //         await app.liquidate();

    //         let balance1 = await web3.eth.getBalance(accounts[0]);
    //         assert(balance1 > balance0, "Funds not liquidated");
    //     });

    //     it("Should allow pool swap", async() => {
    //         const app = await combineApp.at(base_proxy.address);

    //         await app.deposit({ value: 1 * (10 ** 18) });
    //         await app.swapPool(swap_ID);
    //         let pid = await app.poolId();
    //         assert(pid == swap_ID, "Pool did not swap");
    //     });

    //     it("Should allow set pool without balance", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         let userinfo = await app.userInfo();
    //         assert(userinfo[0] > 0, "Initial value should not be 0");
    //         try {
    //             await app.setPool(pool_ID - 11);
    //         } catch (e) {
    //             assert(e.message.includes("Currently invested in a pool, unable to change"), "Should not be able to set pool id with balance");
    //         }
    //         await app.liquidate();

    //         try {
    //             await app.setPool(new_Pool);
    //         } catch (e) {
    //             assert(e.message.includes("Currently invested in a pool, unable to change"), "Liquidation did not clear balance");
    //         }
    //         let pid = await app.poolId();

    //         assert(pid == new_Pool, "Pool id did not get properly set");
    //     });

    //     it("Should allow deposit into new pool", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         let userinfo = await app.userInfo();
    //         let balance0 = userinfo[0];
    //         await app.deposit({ value: 1 * (10 ** 18) });
    //         userinfo = await app.userInfo();
    //         assert(userinfo[0] > balance0, "Balance should have increased");

    //     });

    //     it("Should handle handle harvest in new pool", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         pc0 = await app.pendingReward();
    //         await app.updatePool();
    //         pc1 = await app.pendingReward();
    //         assert(pc1 > pc0, "Pending Cake should increase");

    //         fee0 = await web3.eth.getBalance(accounts[2]);
    //         await app.harvest();
    //         pc = await app.pendingReward();
    //         assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

    //         fee1 = await web3.eth.getBalance(accounts[2]);
    //         assert(fee1 > fee0, "Fee balance should have increased");
    //     });

    //     it("Should reject deposit from 3rd party", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         try {
    //             await app.deposit({ value: 1 * (10 ** 18), from: accounts[2] });
    //         } catch (e) {
    //             assert(e.message.includes("caller is not the owner"), "Allows deposit from 3rd party");
    //         }
    //     });

    //     it("Should disallow allow 3rd Party to set holdback", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         try {
    //             await app.setHoldBack((1 * (10 ** 18)).toString(), { from: accounts[2] });
    //         } catch (e) {
    //             assert(e.message.includes("caller is not the owner"), "Allows setHoldBack from 3rd party");
    //         }
    //     });

    //     it("Should disallow allow 3rd Party to call rescue token", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         try {
    //             await app.rescueToken('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', {
    //                 from: accounts[2]
    //             });
    //         } catch (e) {
    //             assert(e.message.includes("caller is not the owner"), "Allows rescueToken from 3rd party");
    //         }
    //     });

    //     it("Should allow holdback and send BNB to parent account", async() => {
    //         const app = await combineApp.at(base_proxy.address);
    //         await app.setHoldBack(amt(10));
    //         await app.deposit({ value: amt(10) });
    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         result = await app.harvest();
    //         truffleAssert.eventEmitted(result, "HoldBack", (ev) => {
    //             return ev.amount > 0;
    //         });

    //         await app.setHoldBack(0);
    //         await app.updatePool();
    //         await app.updatePool();
    //         await app.updatePool();
    //         result = await app.harvest();
    //         truffleAssert.eventNotEmitted(result, "HoldBack");
    //     });

    //     it("Should have no WBNB left in the token", async() => {
    //         //web3 get erc20 token balance of user
    //         let erc20 = await ERC20.at("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c");
    //         let balance = await erc20.balanceOf(accounts[0]);
    //         console.log("WBNB Balance:",balance)
    //         assert(balance == 0, "Should not have any WBNB left");
    //     });
    // }
});