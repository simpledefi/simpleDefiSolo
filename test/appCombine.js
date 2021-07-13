const appCombine = artifacts.require("appCombine");

contract('appCombine', accounts => {
  it("it should deploy", () =>
    appCombine.deploy()
  ); 
});