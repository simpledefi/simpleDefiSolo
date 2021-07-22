const combine_beacon = artifacts.require("combine_beacon");

contract('combine_beacon', accounts => {
    it("Should start with 0 fee", async() => {
        const app = await combine_beacon.deployed();
        fee = await app.getFee('PANCAKESWAP', 'HARVEST');
        assert(fee == 0, "Initial fee not 0");
    });

    it("Fee should be immediately set", async() => {
        const app = await combine_beacon.deployed();
        let amt = (10 * (10 ** 18)).toString();
        await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
        fee = await app.getFee('PANCAKESWAP', 'HARVEST');
        assert(fee == amt, "Fee Not Set");
    });

    it("Different exchange should return 0", async() => {
        const app = await combine_beacon.deployed();
        fee = await app.getFee('APESWAP', 'HARVEST');
        console.log(fee.toString());
        assert(fee == 0, "New Exchange Fee not 0");
    });

    it("Different exchanges, should show different fees", async() => {
        const app = await combine_beacon.deployed();
        await app.setFee('APESWAP', 'HARVEST', (2 * (10 ** 18)).toString(), 0);
        fee0 = await app.getFee('PANCAKESWAP', 'HARVEST');
        fee1 = await app.getFee('APESWAP', 'HARVEST');
        console.log(fee0.toString(), fee1.toString());
        assert(fee0 != fee1, "Fees should not match");
    });

    it("Reverts on overflow", async() => {
        const app = await combine_beacon.deployed();
        let amt = (10 * (10 ** 18)).toString() + "00000000000000000";
        try {
            await app.setFee('PANCAKESWAP', 'HARVEST', amt, 0);
            assert(false, "Should revert on overflow");
        } catch (e) {
            assert(true, "Reverts on overflow");
        }
    });

    it("Fee should change after 5 seconds", async() => {
        const app = await combine_beacon.deployed();
        let amt = (2 * (10 ** 18)).toString();
        fee0 = await app.getFee('PANCAKESWAP', 'HARVEST');
        console.log(fee0.toString());

        await app.setFee('PANCAKESWAP', 'HARVEST', amt, 5);
        await new Promise(r => setTimeout(r, 10000));
        fee1 = await app.getFee('PANCAKESWAP', 'HARVEST');
        console.log(fee1.toString());
        assert(fee0 == fee1, "Fees should not match");
    });

    // it("", async() => {
    //     const app = await combine_beacon.deployed();
    // });

});