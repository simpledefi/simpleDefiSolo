// const { iterator } = require('core-js/fn/symbol');
const truffleAssert = require('truffle-assertions');
const { default: Web3 } = require('web3');

const combineApp = artifacts.require("combineApp");
const combine_beacon = artifacts.require("combine_beacon");
const proxyFactory = artifacts.require("proxyFactory");

const base_proxy = artifacts.require("combine_proxy");
const ERC20 = artifacts.require("ERC20");
let OWNER_ADDR = "0x0e0435b1ab9b9dcddff2119623e25be63ef5cb6e";

function amt(val) {
    // return val.toString() + "000000000000000000";
    return  parseFloat(val).toFixed(18).replace(".","").toString();
}

function check_revert(e,fSignature) {
    rv = e.data[Object.keys(e.data)[0]]['return'].substring(0,10);
    sig = web3.eth.abi.encodeFunctionSignature(fSignature)
    console.log("ERROR:",rv,sig);
    return  rv == sig;
}

function errorSig(e,sig,hex="") {
    let functionSig = hex?hex:web3.eth.abi.encodeFunctionSignature(sig);

    let rv = e.data[Object.keys(e.data)[0]].return;
    console.log(functionSig,rv.substring(0,functionSig.length),rv);
    return functionSig == rv.substring(0,functionSig.length);
}

let app;

contract('combineApp', accounts => {
    let pool_ID = 251; //BUSD-BNB
    let exchangeName = "PANCAKESWAP";
    let new_Pool = 252;
    let swap_ID = 252;
    let beacon; 
    let FEE_COLLECTOR;
    it ("Should set fee Collector", async () => {
        beacon = await combine_beacon.deployed();
        FEE_COLLECTOR  = await beacon.getAddress("FEECOLLECTOR");
        console.log("FEE_COLLECTOR:",FEE_COLLECTOR);
    });

    // pool_ID = swap_ID
    it("Fee should be immediately set", async() => {
        let feeAmt = amt(19);
        await beacon.setFee('DEFAULT', 'HARVEST', feeAmt, 0);
        let fee = await beacon.getFee('DEFAULT', 'HARVEST', accounts[0]);
        fee = fee[0].toString();
        console.log("Fee Set:",feeAmt,fee);
        assert(fee == feeAmt, "Fee Not Set");
    });

    it('should deploy combineApp with initial deposit of 125', async () => {
        let pF = await proxyFactory.deployed();
        console.log("proxyFactory: ", pF.address);
        let addr = await pF.getAddress(pool_ID);

        console.log("Pre:",addr);

        await pF.initialize(pool_ID,exchangeName,0,{value: amt(.0125)});
        let proxyAddr = await pF.getLastProxy(accounts[0]);
        app = await combineApp.at(proxyAddr);

        console.log("LP :", proxyAddr);
        console.log("Done deploy")
        let userinfo = await app.userInfo(pool_ID, exchangeName);
        console.log("Init ID:", JSON.stringify(userinfo));
    });    

    it("Should handle deposit", async() => {
        await app.deposit(pool_ID, exchangeName,{ value: amt(.005) });
        let userinfo = await app.userInfo(new_Pool, exchangeName);
        console.log("AFTER:", JSON.stringify(userinfo));
    });


    it("Should not allow reinitialization", async() => {
        try {
            console.log("start", app.address);
            
            let rv = await app.initialize(pool_ID-1, beacon.address, exchangeName, accounts[0]);
            assert(false, "Allowed Reinitialization");
        } catch (e) {
            assert(check_revert(e,"sdInitializedError()"), "Allowed Reinitialization");
        }
    });

    it("Should restrict admin functions", async() => {
        try {
            await app.harvest( pool_ID, exchangeName,{ from: accounts[3] });
            assert(1 == 2, "Harvest Function  should be restricted");
        } catch (e) {
            assert(e.message.includes("Restricted Function"), "Harvest function should be restricted");
        }

        try {
            await app.swapPool(pool_ID, exchangeName, pool_ID+1, exchangeName, { from: accounts[3] });
            assert(1 == 2, "swapPool Function  should be restricted");
        } catch (e) {        
            console.log(e.message);    
            assert(e.message.includes("Restricted Function"), "swapPool function should be restricted");
        }
    });

    it("Should handle deposit", async() => {
        let userinfo = await app.userInfo(pool_ID, exchangeName);
        console.log("Before:",JSON.stringify(userinfo));
        assert(userinfo[0] != 0, "Initial value should not be 0");
        let startval = userinfo[0]
        await app.deposit(pool_ID, exchangeName,{ value: amt(125) });
        userinfo = await app.userInfo(pool_ID, exchangeName);
        console.log("AFTER:", JSON.stringify(userinfo));
        console.log(userinfo[0],startval);
        assert(BigInt(userinfo[0]) > BigInt(startval),"Value Should increase");
    });

    it("Should handle harvest", async() => {
        let pc = await app.pendingReward(pool_ID, exchangeName);
        console.log("Pending:",pc);
        assert(pc == 0, "Initial Pending Cake should be 0 showing: " + pc.toString());

        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        pc = await app.pendingReward(pool_ID, exchangeName);
        console.log("PC", pc.toString());
        assert(pc != 0, "Pending Cake should not be 0");

        let fee0 = await web3.eth.getBalance(FEE_COLLECTOR);
        await app.harvest(pool_ID, exchangeName);
        pc = await app.pendingReward(pool_ID, exchangeName);
        console.log("PC after:", pc.toString());
        assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

        let fee1 = await web3.eth.getBalance(FEE_COLLECTOR);
        console.log("FEE:", fee1.toString(), fee0.toString());
        assert(parseInt(fee1) > parseInt(fee0), `Fee balance should have increased ${fee1} ${fee0}`);
    });

    it("Should clear out cake after deposit", async() => {
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        let pc0 = await app.pendingReward(pool_ID, exchangeName);
        await app.deposit(pool_ID, exchangeName,{ value: amt(1) });
        let pc1 = await app.pendingReward(pool_ID, exchangeName);
        assert(pc1 < pc0 && pc0>0, `Pending cake not cleared out ${pc1} ${pc0}`);
    });

    it("Should allow a liquidate from owner or admin only", async() => {
        await app.updatePool(pool_ID, exchangeName);
        let pc = await app.pendingReward(pool_ID, exchangeName);
        assert(pc != 0, "Pending Cake should not be 0");

        try {
            await app.liquidate(pool_ID, exchangeName,{ from: accounts[1] });
            assert(false, "Allows liquidation from user not owner");
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows liquidation from user not owner");
        }

        let balance0 = await web3.eth.getBalance(accounts[0]);
        // console.log(accounts[0], balance);
        await app.liquidate(pool_ID, exchangeName);

        let balance1 = await web3.eth.getBalance(accounts[0]);
        assert(balance1 > balance0, "Funds not liquidated");
    });

    it("Should allow pool swap", async() => {
        await app.deposit(pool_ID, exchangeName,{ value: amt(1) });
        try {
            let userinfo = await app.userInfo(pool_ID, exchangeName);
            console.log("POOL ID:", JSON.stringify(userinfo));
            await app.swapPool(pool_ID, exchangeName,swap_ID,exchangeName);
            userinfo = await app.userInfo(swap_ID, exchangeName);
            console.log("SWAP ID:", JSON.stringify(userinfo));
        }
        catch (e) {
            console.log(e);
            if (e) assert(errorSig(e,"InactivePool(uint _poolID)","0xc54c27fc"), "Allowed Reinitialization");
        }
    });

    it("Should allow deposit into new pool", async() => {
        let userinfo = await app.userInfo(swap_ID, exchangeName);
        let balance0 = userinfo[0];
        console.log("Before Deposit:",JSON.stringify(balance0));
        await app.deposit(swap_ID, exchangeName,{ value: amt(1) });
        userinfo = await app.userInfo(swap_ID, exchangeName);
        console.log("After Deposit:",JSON.stringify(userinfo[0]));
        assert(parseInt(userinfo[0],16) > parseInt(balance0,16), "Balance should have increased");
        pool_ID = swap_ID;
    });

    it("Should handle handle harvest in new pool", async() => {
        pc0 = await app.pendingReward(pool_ID, exchangeName);
        console.log("PC0", JSON.stringify(pc0));
        for (i=0; i<10; i++) 
            await app.updatePool(pool_ID, exchangeName);
        pc1 = await app.pendingReward(pool_ID, exchangeName);
        console.log("Cake:",parseInt(pc1,16), parseInt(pc0,16));
        assert(parseInt(pc1,16) > parseInt(pc0,16), "Pendings Cake should increase");

        fee0 = await web3.eth.getBalance(FEE_COLLECTOR);
        await app.harvest(pool_ID, exchangeName);
        pc = await app.pendingReward(pool_ID, exchangeName);
        assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

        fee1 = await web3.eth.getBalance(FEE_COLLECTOR);
        console.log("FEE:", fee1.toString(), fee0.toString());
        assert(parseInt(fee1) > parseInt(fee0), `Fee balance should have increased ${fee1} ${fee0}`);
    });

    it("Should reject deposit from 3rd party", async() => {
        try {
            await app.deposit(pool_ID, exchangeName,{ value: amt(1), from: accounts[2] });
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows deposit from 3rd party");
        }
    });

    it("Should disallow allow 3rd Party to set holdback", async() => {
        try {
            await app.setHoldBack((amt(1)).toString(), { from: accounts[2] });
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows setHoldBack from 3rd party");
        }
    });

    it("Should disallow allow 3rd Party to call rescue token", async() => {
        try {
            await app.rescueToken('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', {
                from: accounts[2]
            });
        } catch (e) {
            assert(e.message.includes("caller is not the owner"), "Allows rescueToken from 3rd party");
        }
    });

    it("Should allow holdback and send BNB to parent account", async() => {
        await app.setHoldBack(amt(10));
        await app.deposit(pool_ID, exchangeName,{ value: amt(10) });
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        let result = await app.harvest(pool_ID, exchangeName);
        truffleAssert.eventEmitted(result, "sdHoldBack", (ev) => {
            return ev.amount > 0;
        });

        await app.setHoldBack(0);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        await app.updatePool(pool_ID, exchangeName);
        result = await app.harvest(pool_ID, exchangeName);
        truffleAssert.eventNotEmitted(result, "sdHoldBack");
    });

    it("Should have no WBNB left in the token", async() => {
        //web3 get erc20 token balance of user
        let erc20 = await ERC20.at("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c");
        let balance = await erc20.balanceOf(accounts[0]);
        console.log("WBNB Balance:",balance)
        assert(balance == 0, "Should not have any WBNB left");
    });

    if (1==1) {    
        it("should set new exchange",async() => {
            
            await app.liquidate(pool_ID, exchangeName);
            pool_ID = 132; //babyswap  
            new_Pool = 131;
            swap_ID = 134;            
            exchangeName = "APESWAP";
            console.log("Switching to",exchangeName)
        });
        
        it("Should handle deposit", async() => {
            let userinfo = await app.userInfo(pool_ID, exchangeName);
            console.log(JSON.stringify(userinfo));
            assert(userinfo[0] == 0, "Initial value should be 0");
            await app.deposit(pool_ID, exchangeName,{ value: amt(125) });
            console.log("DEPOSIT INFO:", pool_ID, exchangeName);
            userinfo = await app.userInfo(pool_ID, exchangeName);
            console.log(JSON.stringify(userinfo));
            assert(userinfo[0] > 0, "Initial value should not be 0");
        });

        it("Should handle harvest", async() => {
            let pc = await app.pendingReward(pool_ID, exchangeName);
            console.log("Pending:",pc);
            assert(pc == 0, "Initial Pending Cake should be 0 showing: " + pc.toString());

            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            pc = await app.pendingReward(pool_ID, exchangeName);
            console.log("PC", pc.toString());
            assert(pc != 0, "Pending Cake should not be 0");

            fee0 = await web3.eth.getBalance(FEE_COLLECTOR);
            await app.harvest(pool_ID, exchangeName);
            pc = await app.pendingReward(pool_ID, exchangeName);
            assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

            fee1 = await web3.eth.getBalance(FEE_COLLECTOR);
            assert(parseInt(fee1) > parseInt(fee0), `Fee balance should have increased ${fee1} ${fee0}`);
        });

        it("Should clear out reward after deposit", async() => {

            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            let pc0 = await app.pendingReward(pool_ID, exchangeName);
            await app.deposit(pool_ID, exchangeName,{ value: amt(1) });
            pc1 = await app.pendingReward(pool_ID, exchangeName);
            assert(pc1 < pc0 && pc0>0, `Pending cake not cleared out ${pc1} ${pc0}`);
        });

        it("Should allow a liquidate from owner or admin only", async() => {
            await app.updatePool(pool_ID, exchangeName);
            let pc = await app.pendingReward(pool_ID, exchangeName);
            assert(pc != 0, "Pending Cake should not be 0");

            try {
                await app.liquidate(pool_ID, exchangeName,{ from: accounts[1] });
                assert(false, "Allows liquidation from user not owner");
            } catch (e) {
                assert(e.message.includes("caller is not the owner"), "Allows liquidation from user not owner");
            }

            let balance0 = await web3.eth.getBalance(accounts[0]);
            // console.log(accounts[0], balance);
            await app.liquidate(pool_ID, exchangeName);

            let balance1 = await web3.eth.getBalance(accounts[0]);
            assert(balance1 > balance0, "Funds not liquidated");
        });

        it("Should allow pool swap", async() => {
            console.log("DEPOSIT INFO:", pool_ID, exchangeName);
            await app.deposit(pool_ID, exchangeName,{ value: amt(1) });
            await app.swapPool(pool_ID, exchangeName,swap_ID,exchangeName);
            pool_ID = swap_ID;
        });


        it("Should allow deposit into new pool", async() => {        
            let userinfo = await app.userInfo(pool_ID, exchangeName);
            let balance0 = userinfo[0];
            await app.deposit(pool_ID, exchangeName,{ value: amt(1) });
            userinfo = await app.userInfo(pool_ID, exchangeName);
            assert(userinfo[0] > balance0, "Balance should have increased");
        });

        it("Should handle handle harvest in new pool", async() => {
            pc0 = await app.pendingReward(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            pc1 = await app.pendingReward(pool_ID, exchangeName);
            assert(pc1 > pc0, "Pending Cake should increase");

            fee0 = await web3.eth.getBalance(FEE_COLLECTOR);
            await app.harvest(pool_ID, exchangeName);
            pc = await app.pendingReward(pool_ID, exchangeName);
            assert(pc == 0, "After Harvest Pending Cake should be 0 showing: " + pc.toString());

            fee1 = await web3.eth.getBalance(FEE_COLLECTOR);
            assert(parseInt(fee1) > parseInt(fee0), `Fee balance should have increased ${fee1} ${fee0}`);
        });

        it("Should reject deposit from 3rd party", async() => {
            try {
                await app.deposit(pool_ID, exchangeName,{ value: amt(1), from: accounts[2] });
            } catch (e) {
                assert(e.message.includes("caller is not the owner"), "Allows deposit from 3rd party");
            }
        });

        it("Should disallow allow 3rd Party to set holdback", async() => {
            try {
                await app.setHoldBack((amt(1)).toString(), { from: accounts[2] });
            } catch (e) {
                assert(e.message.includes("caller is not the owner"), "Allows setHoldBack from 3rd party");
            }
        });

        it("Should disallow allow 3rd Party to call rescue token", async() => {
            try {
                await app.rescueToken('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', {
                    from: accounts[2]
                });
            } catch (e) {
                assert(e.message.includes("caller is not the owner"), "Allows rescueToken from 3rd party");
            }
        });

        it("Should allow holdback and send BNB to parent account", async() => {
            await app.setHoldBack(amt(10));
            await app.deposit(pool_ID, exchangeName,{ value: amt(10) });
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            let result = await app.harvest(pool_ID, exchangeName);
            truffleAssert.eventEmitted(result, "sdHoldBack", (ev) => {
                return ev.amount > 0;
            });

            await app.setHoldBack(0);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            await app.updatePool(pool_ID, exchangeName);
            result = await app.harvest(pool_ID, exchangeName);
            truffleAssert.eventNotEmitted(result, "sdHoldBack");
        });

        it("Should have no WBNB left in the token", async() => {
            //web3 get erc20 token balance of user
            let erc20 = await ERC20.at("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c");
            let balance = await erc20.balanceOf(accounts[0]);
            console.log("WBNB Balance:",balance)
            assert(balance == 0, "Should not have any WBNB left");
        });

        it('should deploy new instance of combineApp and swap', async () => {
            let pF = await proxyFactory.deployed();
            console.log("proxyFactory: ", pF.address);
            let addr = await pF.getAddress(pool_ID);
    
            console.log("Pre:",addr);
            let n_exchangeName = 'BABYSWAP';
            let n_pool_ID = 28;
            await pF.initialize(n_pool_ID,n_exchangeName,0,{value: amt(0)});
            let proxyAddr = await pF.getLastProxy(accounts[0]);
            let app2 = await combineApp.at(proxyAddr);
    
            console.log("LP :", proxyAddr);
            console.log("Done deploy");
            app.swapContractPool(pool_ID, exchangeName, app2.address,n_pool_ID,n_exchangeName);
            console.log("Done swap");
            let userinfo = await app2.userInfo(n_pool_ID, n_exchangeName);
            console.log("Init ID:", JSON.stringify(userinfo));
    
        });        
    }
});