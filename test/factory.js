// const { iterator } = require('core-js/fn/symbol');
const truffleAssert = require('truffle-assertions');

const _proxyFactory = artifacts.require("proxyFactory");

function amt(val) {
    return val.toString() + "000000000000000000";
}


contract ("proxyFactory",(accounts) => {
    it('should deploy combineApp', async (proxyApp) => {
        let proxyFactory = await _proxyFactory.deployed();
        console.log("proxyFactory: ", proxyFactory.address);
        proxyApp = await proxyFactory.initialize(252,"MULTIEXCHANGE","PANCAKESWAP",{value: amt(125)});
        console.log("proxyApp: ", proxyApp);
    });
});
console.log("DONE");