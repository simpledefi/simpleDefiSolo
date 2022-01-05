// const { iterator } = require('core-js/fn/symbol');
const truffleAssert = require('truffle-assertions');

const proxyFactory = artifacts.require("proxyFactory");
const combineApp = artifacts.require("combineApp");

function amt(val) {
    return val.toString() + "000000000000000000";
}
let proxyAddr = "";

contract ("proxyFactory",(accounts) => {
    it('should deploy combineApp', async () => {
        let pF = await proxyFactory.deployed();
        console.log("proxyFactory: ", pF.address);
        proxyApp = await pF.initialize(252,"MULTIEXCHANGE","PANCAKESWAP",{value: amt(125)});
        proxyAddr = await pF.getLastProxy(accounts[0]);
        console.log("proxyApp: ", proxyApp);
        console.log("lastProxy: ", proxyAddr);
        console.log("Done deploy")
    });

    // let proxyApp;
    it("should get last proxy address", async () => {
        console.log("Current Proxy: ", proxyAddr);

        let app = await combineApp.at(proxyAddr);
        let ui = await app.userInfo();
        console.log("userInfo: ", ui);
    });

});
console.log("DONE");