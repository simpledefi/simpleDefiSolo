// const { iterator } = require('core-js/fn/symbol');
const truffleAssert = require('truffle-assertions');

const proxyFactory = artifacts.require("proxyFactory");
const combineApp = artifacts.require("combineApp");

function amt(val) {
    return val.toString() + "000000000000000000";
}
let proxyAddr = "";
let proxyApp;

contract ("proxyFactory",(accounts) => {
    it('should deploy combineApp', async () => {
        let pF = await proxyFactory.deployed();
        console.log("proxyFactory: ", pF.address);
        proxyApp = await pF.initialize(3,"MULTIEXCHANGE","PANCAKESWAP",{value: amt(125)});
        proxyAddr = await pF.getLastProxy(accounts[0]);
        proxyApp = await combineApp.at(proxyAddr);

        console.log("proxyApp: ", proxyApp);
        console.log("lastProxy: ", proxyAddr);
        console.log("Done deploy")
    });

    // let proxyApp;
    it("should get last proxy address", async () => {
        let ui = await proxyApp.userInfo();
        console.log("userInfo: ", ui);
    });

});
console.log("DONE");