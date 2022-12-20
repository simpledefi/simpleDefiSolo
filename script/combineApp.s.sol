// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/combineApp.sol";

contract combineAppScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("privateKey");
        vm.startBroadcast(deployerPrivateKey);

        combineApp app = new combineApp();

        vm.stopBroadcast();    
    }
}
