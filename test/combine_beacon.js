const combine_beacon = artifacts.require("combine_beacon");

contract('combine_beacon', accounts => {
    // it("Should start with 0 fee", async() => {
    //     const app = await combine_beacon.deployed();
    //     fee = await app.getFee('PANCAKESWAP', 'HARVEST');
    //     // console.log(fee);
    //     assert(fee == 0, "Initial fee not 0");

    // });

    // it("Fee should be immediately set", async() => {
    //     const app = await combine_beacon.deployed();
    //     let amt = (10 * (10 ** 18)).toString();
    //     await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
    //     fee = await app.getFee('PANCAKESWAP', 'HARVEST');
    //     // console.log(fee);
    //     assert(fee == amt, "Fee Not Set");
    // });

    // it("Different exchange should return 0", async() => {
    //     const app = await combine_beacon.deployed();
    //     fee = await app.getFee('APESWAP', 'HARVEST');
    //     // console.log(fee.toString());
    //     assert(fee == 0, "New Exchange Fee not 0");
    // });

    // it("Different exchanges, should show different fees", async() => {
    //     const app = await combine_beacon.deployed();
    //     await app.setFee('APESWAP', 'HARVEST', (2 * (10 ** 18)).toString(), 0);
    //     fee0 = await app.getFee('PANCAKESWAP', 'HARVEST');
    //     fee1 = await app.getFee('APESWAP', 'HARVEST');
    //     // console.log(fee0.toString(), fee1.toString());
    //     assert(fee0 != fee1, "Fees should not match");
    // });

    // it("Reverts on overflow", async() => {
    //     const app = await combine_beacon.deployed();
    //     let amt = (10 * (10 ** 18)).toString() + "00000000000000000";
    //     try {
    //         await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
    //         assert(false, "Should revert on overflow");
    //     } catch (e) {
    //         assert(true, "Reverts on overflow");
    //     }
    // });

    // it("Fee should change after 5 seconds", async() => {
    //     const app = await combine_beacon.deployed();
    //     amt = (10 * (10 ** 18)).toString();
    //     result = await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
    //     fee0 = await app.getFee('PANCAKESWAP', 'HARVEST');

    //     amt = (20 * (10 ** 18)).toString();
    //     result = await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
    //     console.log("\tWaiting....");
    //     await new Promise(r => setTimeout(r, 10000));
    //     await app.updateBlock();

    //     fee1 = await app.getFee('PANCAKESWAP', 'HARVEST');
    //     assert(fee1.toString() == amt && fee1.toString() != fee0.toString(), "Fee not properly set");
    //     // assert(fee0 == fee1, "Fees should not match");
    // });

    // it("Should not allow discounts over 100%", async() => {
    //     const app = await combine_beacon.deployed();
    //     amt = (110 * (10 ** 18)).toString();
    //     try {
    //         result = await app.setDiscount(accounts[1], amt, 30);
    //         assert(false, "Allowed fee over 100%");
    //     } catch (e) {
    //         assert(e.message.includes("Cannot exceed 100%"), "Allowed fee over 100%");
    //     }
    // });

    // it("Should allow proper discount to be set", async() => {
    //     const app = await combine_beacon.deployed();
    //     amt = (50 * (10 ** 18)).toString();
    //     result = await app.setDiscount(accounts[1], amt, 30);

    //     fee = await app.mDiscounts(accounts[1]);
    //     assert(fee.discount_amount == amt, "Discount not set: " + amt)
    // });

    it("Should apply discounts to proper accounts", async() => {
        const app = await combine_beacon.deployed();
        amt = (20 * (10 ** 18)).toString();
        await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
        fee = await app.getFee("PANCAKESWAP", "HARVEST");
        console.log(fee.toString());
        assert(fee.toString() == amt, "Fee not properly set");
        amt = (10 * (10 ** 18)).toString();
        console.log(1);
        try {
            fee = await app.getFee("PANCAKESWAP", "HARVEST", accounts[1]);
        } catch (e) {
            console.log(e.message);
        }
        console.log(2);
        console.log(fee);
        assert(fee.toString() == amt, "Discount not properly applied");
    });


    // it("", async() => {
    //     const app = await combine_beacon.deployed();
    // });

});