// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "forge-std/Test.sol";
import "src/combineApp.sol";
import "src/combine_proxy.sol";

interface tBeacon {
    function setExchange(string memory _exchange, address _replacement_logic_contract, uint256 _start) external;
}

interface tMasterchef {
    struct PoolInfo {
        uint256 accCakePerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
    }    
    function updatePool(uint _pid) external returns (PoolInfo memory);
    function userInfo(uint _pid, address _user) external returns (uint, uint, uint);
}

contract combineAppTest is Test {
    combineApp app;
    proxyFactory pr;
    address appAddr;
    address beacon = 0xd94d32a4a79ddE20CB7D58aBcEC697f20Ed0D3d2;
    address primeOwner = 0x0e0435B1aB9B9DCddff2119623e25be63ef5CB6e;
    address masterchef = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address invalidUser = makeAddr("invaliduser");


    constructor() {
        pr = new proxyFactory(beacon, owner);       
        app = new combineApp();
        vm.prank(primeOwner);
        tBeacon(beacon).setExchange("MULTIEXCHANGE",address(app),0);
        vm.deal(user,10 ether);
        vm.prank(user);
        appAddr = pr.initialize{value: 5 ether}(2, "PANCAKESWAP", 0, 1234);
    }

    function setUp() public {
    }

    function test000_Deposit() public {
        vm.startPrank(user);
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
        combineApp(payable(appAddr)).deposit{value:.5 ether}(2, "PANCAKESWAP");        
        (uint bal2,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
        console.log("Deposit Balance  :",bal2);
        vm.stopPrank();
        assertGt(bal2,bal1);
    }

    function test001_ReInit() public {
        vm.startPrank(user);
        vm.expectRevert(combineApp.sdInitializedError.selector);
        combineApp(payable(appAddr)).initialize(3, beacon, "PANCAKESWAP", user);
    }

    function test002_LockedFunctions() public {
        vm.startPrank(invalidUser);

        vm.expectRevert(combineApp.sdLocked.selector);
        combineApp(payable(appAddr)).harvest(2, "PANCAKESWAP");

        vm.expectRevert(combineApp.sdLocked.selector);
        combineApp(payable(appAddr)).swapPool(2, "PANCAKESWAP",3,"PANCAKESWAP");

        vm.stopPrank();
    }

    function test003_harvest() public {
        vm.startPrank(user);
        combineApp(payable(appAddr)).deposit{value:.5 ether}(2, "PANCAKESWAP");     
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
   
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);
        
        combineApp(payable(appAddr)).harvest(2, "PANCAKESWAP");        
        (uint bal2,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
        console.log(bal2,bal1);
        assertGt(bal2,bal1);

        uint pc = combineApp(payable(appAddr)).pendingReward(2, "PANCAKESWAP");        
        console.log("Pending Reward:", pc);
        vm.stopPrank();
    }

    function test004_ClearCakeAfterDeposit() public {
        vm.startPrank(user);
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);
        combineApp(payable(appAddr)).deposit{value:.5 ether}(2, "PANCAKESWAP");     
        uint pc = combineApp(payable(appAddr)).pendingReward(2, "PANCAKESWAP");        
        assertEq(pc,0);
    }

    function test005_LiquidateFromOwnerOrAdmin() public {
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);
        vm.prank(invalidUser);
        vm.expectRevert(bytes('Ownable: caller is not the owner'));
        combineApp(payable(appAddr)).liquidate(2,"PANCAKESWAP");

        uint bal0 = address(user).balance;
        vm.prank(user);
        combineApp(payable(appAddr)).liquidate(2,"PANCAKESWAP");
        uint bal1 = address(user).balance;
        console.log(bal1,bal0);
        assertGt(bal1,bal0);
    }

    function test006_poolSwap() public {
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);
        vm.startPrank(user);
        combineApp(payable(appAddr)).swapPool(2,"PANCAKESWAP",3,"PANCAKESWAP");
        (uint bal0,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(3, "PANCAKESWAP");
        console.log(bal0,bal1);
        assertEq(bal0,0);
        assertGt(bal1,0);
        vm.stopPrank();
    }

    function test007_depositNewPool() public {
        uint64 newPool = 130;
        vm.startPrank(user);
        (uint bal0,,,,,) = combineApp(payable(appAddr)).userInfo(newPool, "PANCAKESWAP");
        combineApp(payable(appAddr)).deposit{value:.5 ether}(newPool, "PANCAKESWAP");     
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(newPool, "PANCAKESWAP");
        console.log(bal1,bal0);
        assertEq(bal0,0);
        assertGt(bal1,0);
        vm.stopPrank();
    }

    function test008_harvestNewPool() public {
        uint64 newPool = 130;
        vm.startPrank(user);
        combineApp(payable(appAddr)).deposit{value:.5 ether}(newPool, "PANCAKESWAP");     
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(newPool, "PANCAKESWAP");
   
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(newPool);
        
        combineApp(payable(appAddr)).harvest(newPool, "PANCAKESWAP");        
        (uint bal2,,,,,) = combineApp(payable(appAddr)).userInfo(newPool, "PANCAKESWAP");
        console.log(bal2,bal1);
        assertGt(bal2,bal1);

        uint pc = combineApp(payable(appAddr)).pendingReward(newPool, "PANCAKESWAP");        
        console.log("Pending Reward:", pc);
        vm.stopPrank();
    }

    function test009_disallowHoldback() public {
        vm.prank(invalidUser);
        vm.expectRevert(bytes('Ownable: caller is not the owner'));
        combineApp(payable(appAddr)).setHoldBack(1 ether);
    }    

    function test010_disallowRescueToken() public {
        vm.prank(invalidUser);
        vm.expectRevert(bytes('Ownable: caller is not the owner'));
        combineApp(payable(appAddr)).rescueToken(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    }

    function test011_setHoldback() public {
        vm.startPrank(user);

        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);

        uint bal0 = address(user).balance;
        combineApp(payable(appAddr)).harvest(2, "PANCAKESWAP");        
        uint bal1 = address(user).balance;
        console.log(bal1,bal0);
        assertEq(bal1,bal0);

        combineApp(payable(appAddr)).setHoldBack(10 ether);        
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);

        bal0 = address(user).balance;
        combineApp(payable(appAddr)).harvest(2, "PANCAKESWAP");        
        bal1 = address(user).balance;

        console.log(bal1,bal0);
        assertGt(bal1,bal0);
        
        vm.stopPrank();
    }

    function test012_depositNewExchange() public {
        vm.startPrank(user);
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(2, "APESWAP");
        combineApp(payable(appAddr)).deposit{value:.5 ether}(2, "APESWAP");        
        (uint bal2,,,,,) = combineApp(payable(appAddr)).userInfo(2, "APESWAP");
        console.log("Deposit Balance  :",bal2);
        vm.stopPrank();
        assertGt(bal2,bal1);
    }

    function test013_harvestNewExchange() public {
        vm.startPrank(user);
        combineApp(payable(appAddr)).deposit{value:.5 ether}(2, "APESWAP");     
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(2, "APESWAP");
   
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);
        
        combineApp(payable(appAddr)).harvest(2, "APESWAP");        
        (uint bal2,,,,,) = combineApp(payable(appAddr)).userInfo(2, "APESWAP");
        console.log(bal2,bal1);
        assertGt(bal2,bal1);

        uint pc = combineApp(payable(appAddr)).pendingReward(2, "APESWAP");        
        console.log("Pending Reward:", pc);
        vm.stopPrank();
    }

    function test014_swapBetweenExchanges() public {
        vm.roll(block.number + 1000);
        tMasterchef(masterchef).updatePool(2);
        vm.startPrank(user);
        combineApp(payable(appAddr)).swapPool(2,"PANCAKESWAP",2,"APESWAP");
        (uint bal0,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
        (uint bal1,,,,,) = combineApp(payable(appAddr)).userInfo(2, "APESWAP");
        console.log(bal0,bal1);
        assertEq(bal0,0);
        assertGt(bal1,0);
        vm.stopPrank();
    }


    function test015_swapBetweenContracts() public {
        vm.startPrank(user);
        address newAppAddr = pr.initialize{value: 1 ether}(2, "BABYSWAP", 0, 123456);
        (uint bal,,,,,) = combineApp(payable(newAppAddr)).userInfo(2, "BABYSWAP");
        
        combineApp(payable(appAddr)).swapContractPool(2, "PANCAKESWAP", newAppAddr,2,"BABYSWAP");
        (uint bal0,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
        (uint bal1,,,,,) = combineApp(payable(newAppAddr)).userInfo(2, "BABYSWAP");
        console.log(bal0,bal,bal1);
        assertEq(bal0,0);
        assertGt(bal1,bal);
        vm.stopPrank();
    }

    function test999_Setup() public {
        vm.prank(user);
        (uint bal,,,,,) = combineApp(payable(appAddr)).userInfo(2, "PANCAKESWAP");
        console.log("App Balance  :",bal);
        console.log("\tTS:", block.number);

    }
}
