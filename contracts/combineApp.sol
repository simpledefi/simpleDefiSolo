//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./Interfaces.sol";
import "./Storage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract combineApp is Storage, Ownable, AccessControl {
    event uintLog( string message, uint value);
    event uintLog( string message, uint[] value);
    event Deposit(uint amount);
    event HoldBack(uint amount, uint total);
    event FeeSent(uint amount,uint total);
    event Received(address sender, uint amount);
    event NewPool(uint oldPool, uint newPool);
    event LiquidityProvided(uint256 farmIn, uint256 wethIn, uint256 lpOut);
    event Initialized(uint64 poolId, address lpContract);

    modifier lockFunction() {
        require(_locked == false,"Function locked");
        _locked = true;
        _;
        _locked = false;
    }
     
    modifier allowAdmin() {
        require(hasRole(HARVESTER,msg.sender) || owner() == msg.sender,"Restricted Function");
        _;
    }

    modifier clearPool() {
        if (poolId > 0) {
            (uint a, ) = iMasterChef(chefContract).userInfo(poolId,address(this));
            require(a == 0, "Currently invested in a pool, unable to change");
        }
        _;
    }

    function initialize(uint64 _poolId, address _beacon, string memory _exchangeName) public payable {
        require(_initialized == false,"Already Initialized");
        _initialized = true;
        beaconContract = _beacon;

        address harvester = iBeacon(beaconContract).getAddress("HARVESTER");
        feeCollector = iBeacon(beaconContract).getAddress("FEECOLLECTOR");

        _setupRole(HARVESTER, harvester);
        _setupRole(DEFAULT_ADMIN_ROLE,owner());

        holdBack = 0; 
        // chefContract = 0x73feaa1eE314F8c655E354234017bE2193C9E24E; //_chefContract;
        // routerContract = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //_routerContract;
        // rewardToken = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //_rewardToken;

        setup(_poolId,_exchangeName);
    }

    function addHarvester(address _address) public onlyOwner {
        _setupRole(HARVESTER,_address);
    }

    function removeHarvester(address _address) public onlyOwner{
        revokeRole(HARVESTER,_address);
    }
    function newExchange(uint64 _poolId, string memory _exchangeName) public onlyOwner clearPool {
        require(beaconContract != address(0),"Beacon Contract not configured");
        require(bytes(_exchangeName).length > 0,"Exchange Name cannot be empty");

        setup(_poolId, _exchangeName);
    }

    function setup(uint64 _poolId, string memory _exchangeName) private {
        (chefContract, routerContract, rewardToken, pendingCall, intermediateToken) = iBeacon(beaconContract).getExchangeInfo(_exchangeName);
        require(chefContract != address(0),"Exchange not configured");
        exchange = _exchangeName;

        setLP(_poolId);
        ERC20(rewardToken).approve(address(this),MAX_INT);
        ERC20(rewardToken).approve(routerContract,MAX_INT);

        if (msg.value > 0) {
            addFunds(msg.value);
            emit Deposit(msg.value);
        }
        emit Initialized(_poolId,lpContract);
    }
    
    receive() external payable {}

    function deposit() external onlyOwner payable  {
        uint deposit_amount = msg.value;
        uint pendingReward_val =  pendingReward();
        if (pendingReward_val > 0) {
            deposit_amount = deposit_amount + do_harvest(0);
        }
        addFunds(deposit_amount);
        emit Deposit(deposit_amount);
    }

    function setLP(uint64 _poolId) private {
        poolId = _poolId;
        (address _lpContract,uint _alloc,,) = iMasterChef(chefContract).poolInfo(_poolId);
        require(_lpContract != address(0),"LP Contract not found");
        require(_alloc > 0,"Pool must be active");

        lpContract =  _lpContract;
        token0 = iLPToken(lpContract).token0();
        token1 = iLPToken(lpContract).token1();

        ERC20(token0).approve(routerContract,MAX_INT);
        ERC20(token1).approve(routerContract,MAX_INT);
        
        iLPToken(lpContract).approve(address(this),MAX_INT);
        iLPToken(lpContract).approve(chefContract,MAX_INT);        
        iLPToken(lpContract).approve(routerContract,MAX_INT);                
    }

    function setPool(uint64 _poolId) public allowAdmin clearPool payable {
        setLP(_poolId);
        if (msg.value > 0) {
            addFunds(msg.value);
            emit Deposit(msg.value);
        }
    }

    function swapPool(uint64 _newPool) public allowAdmin {
        require(_newPool != poolId,"New pool required");
        uint64 oldPool = poolId;
        
        removeLiquidity();
        revertBalance();
        
        uint _bal = address(this).balance;
        require(_bal>0,"Balance required before swap");
        
        setLP(_newPool);
        addFunds(_bal);
        
        emit NewPool(oldPool,_newPool);
    }
    
    function pendingReward() public view returns (uint) {        
        // uint pendingReward_val =  iMasterChef(chefContract).pendingCake(poolId,address(this));
        (, bytes memory data) = chefContract.staticcall(abi.encodeWithSignature(pendingCall, poolId,address(this)));
        uint pendingReward_val = abi.decode(data,(uint256));
        if (pendingReward_val == 0) {
            pendingReward_val = ERC20(rewardToken).balanceOf(address(this));
        }
        return pendingReward_val;
    }
    
    function liquidate() public onlyOwner lockFunction {
        do_harvest(0);
        removeLiquidity();
        revertBalance();        
        uint _total = address(this).balance;
        
        payable(owner()).transfer(_total);
        emit uintLog("Liquidate Total",_total);
    }
    
    function setHoldBack(uint64 _holdback) public onlyOwner {
        holdBack = _holdback;
        emit uintLog("holdback",_holdback);
    }
    
    function sendHoldBack() public onlyOwner lockFunction{
        uint bal = address(this).balance;
        require(bal > 0,"Nothing to send");
        payable(owner()).transfer(bal);
        emit HoldBack(bal,bal);
    }
    
    function harvest() public lockFunction allowAdmin {
        uint startGas = gasleft() + 21000 + 7339;
        uint split = do_harvest(1);
        
        addFunds(split);
        if (msg.sender != owner()) {
            lastGas = startGas - gasleft();
        }
    }
    
    function tokenBalance() private view returns (uint _bal0,uint _bal1) {
        _bal0 = ERC20(token0).balanceOf(address(this));
        _bal1 = ERC20(token1).balanceOf(address(this));
    }    
    
    function rescueToken(address token) public onlyOwner{
        uint _bal = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(owner(),_bal);
    }

    function addFunds(uint inValue) private {
        require(inValue > 0,"Deposit amount must be greater than 0");

        uint amount0;
        uint amount1;
        uint split = (inValue*50)/100;
        
        if (token0 != WBNB_ADDR) {
            address[] memory path1 = new address[](2);
            path1[0] = WBNB_ADDR;
            path1[1] = token0;
            amount0 = swap(split,path1);
        }
        else{
            amount0 = split;
        }
        
        if (token1 != WBNB_ADDR) {
            address[] memory path2 = new address[](2);
            path2[0] = WBNB_ADDR;
            path2[1] = token1;
            amount1 = swap(split,path2);
        }       
        else{
            amount1 = split;
        }
        addLiquidity(amount0,amount1);
    }

    function addLiquidity(uint amount0, uint amount1) private {
        uint amountA;
        uint amountB;
        uint liquidity;

        if (token1 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(routerContract).addLiquidityETH{value: amount1}(token0, amount0, 0,0, address(this), block.timestamp);
        }
        else if (token0 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(routerContract).addLiquidityETH{value: amount0}(token1, amount1, 0,0, address(this), block.timestamp);
        }
        else {
            ( amountA,  amountB, liquidity) = iRouter(routerContract).addLiquidity(token0, token1, amount0, amount1, 0, 0, address(this), block.timestamp);
        }

        iMasterChef(chefContract).deposit(poolId,liquidity);
        emit LiquidityProvided(amountA, amountB, liquidity);
    }
    
    function swap(uint amountIn, address[] memory path) private returns (uint){
        require(amountIn > 0, "Amount for swap required");
        uint pathLength = (intermediateToken != address(0) && path[0] != intermediateToken && path[1] != intermediateToken) ? 3 : 2;
        address[] memory swapPath = new address[](pathLength);
        
        if (pathLength == 2) {
            swapPath[0] = path[0];
            swapPath[1] = path[1];
        }
        else {
            swapPath[0] = path[0];
            swapPath[1] = intermediateToken;
            swapPath[2] = path[1];
        }

        uint[] memory amounts;

        uint deadline = block.timestamp + 600;
        uint _bal = path[0] == WBNB_ADDR ? ERC20(WBNB_ADDR).balanceOf(address(this)) : 0;

        if (_bal > 0) {
            iWBNB(WBNB_ADDR).withdraw(_bal);
            return _bal;
        }
        else {
            if (path[path.length - 1] == WBNB_ADDR) {
                amounts = iRouter(routerContract).swapExactTokensForETH(amountIn, 0,  swapPath, address(this), deadline);
            } else if (path[0] == WBNB_ADDR) {
                amounts = iRouter(routerContract).swapExactETHForTokens{value: amountIn}(0,swapPath,address(this),deadline);
            }
            else {
                amounts = iRouter(routerContract).swapExactTokensForTokens(amountIn, 0,swapPath,address(this),deadline);
            }
            return amounts[swapPath.length-1];
        }
    }
    
    function do_harvest(uint revert_trans) private returns (uint) {
        uint pendingCake = 0;
        pendingCake = pendingReward();
        if (pendingCake == 0) {
            if (revert_trans == 1) {
                revert("Nothing to harvest");
            }
            else {
                    return 0;
            }
        }
        
        iMasterChef(chefContract).deposit(poolId,0);
        pendingCake = ERC20(rewardToken).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = rewardToken;
        path[1] = WBNB_ADDR;

        pendingCake = swap(pendingCake,path);
        
        uint64 fee = iBeacon(beaconContract).getFee('PANCAKESWAP','HARVEST',address(this));
        uint feeAmount = ((pendingCake * fee)/100e18) + ((lastGas * tx.gasprice)*10e8);

        if (feeAmount > pendingCake) {
            feeAmount = pendingCake;
        }

        uint _bal = address(this).balance;

        if(feeAmount > 0 && _bal > 0) {
            payable(address(feeCollector)).transfer(feeAmount);
            emit FeeSent(feeAmount,pendingCake);
        }

        uint finalReward = pendingCake - feeAmount;

        if (holdBack > 0) {
            uint holdbackAmount = (finalReward/100) * (holdBack/10**18);
            finalReward = finalReward - holdbackAmount;
            payable(owner()).transfer(holdbackAmount);
            emit HoldBack(holdbackAmount,finalReward);

        }
        return finalReward;
    }
    
    function removeLiquidity() private {
        uint amountTokenA;
        uint amountTokenB;
        uint deadline = block.timestamp + 600;

        (uint _lpBal,) = iMasterChef(chefContract).userInfo(poolId,address(this));
        iMasterChef(chefContract).withdraw(poolId,_lpBal);
        
        uint _removed = ERC20(lpContract).balanceOf(address(this));
        emit uintLog("_removed",_removed);
        
        if (token1 == WBNB_ADDR)
            (amountTokenA, amountTokenB) = iRouter(routerContract).removeLiquidityETH(token0,_removed,0,0,address(this), deadline);
        else
            (amountTokenA, amountTokenB) = iRouter(routerContract).removeLiquidity(token0,token1,_removed,0,0,address(this), deadline);
    }

    function revertBalance() private {
        address[] memory path = new address[](2);
        path[1] = WBNB_ADDR;
        uint amount0 = 0;

        uint _rewards = ERC20(rewardToken).balanceOf(address (this));
        if (_rewards > 0 ){
            path[0] = rewardToken;
            amount0 = swap(_rewards, path);
        }

        (uint _bal0, uint _bal1) = tokenBalance();
        
        if (_bal0 > 0) {
            path[0] = token0;
            amount0 += swap(_bal0, path);
        }
        
        if (_bal1 > 0) {
            path[0] = token1;
            amount0 += swap(_bal1, path);
        }
    }
    
    function cakePerBlock() public view returns(uint) {
        return iMasterChef(chefContract).cakePerBlock();
    }    
    
    function updatePool() public {
        iMasterChef(chefContract).updatePool(poolId);
    }
    
    function userInfo() public view allowAdmin returns (uint,uint,uint,uint,uint,uint) {
        (uint a, uint b) = iMasterChef(chefContract).userInfo(poolId,address(this));
        (uint c, uint d) = tokenBalance();
        uint e = ERC20(rewardToken).balanceOf(address(this));
        uint f = address(this).balance;
        return (a,b,c,d,e,f);
    }
//$20 aprox:
//63973400000000000
//2120000000000000000
//dev testing
//"411","10000000000000000000","0x2320738301305c892B01f44E4E9854a2D19AE19e","0x2320738301305c892B01f44E4E9854a2D19AE19e"
//live testing
//"354","10000000000000000000","0x42a515c1EDB651F4c69c56E05578D2805D6451eB","0x42a515c1EDB651F4c69c56E05578D2805D6451eB"
// Swap to 427
//cake test
//"251","10000000000000000000","0x2320738301305c892B01f44E4E9854a2D19AE19e","0x2320738301305c892B01f44E4E9854a2D19AE19e"

    
}

