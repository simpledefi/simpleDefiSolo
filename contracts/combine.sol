//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface iMasterChef{
     function pendingCake(uint256 _pid, address _user) external view returns (uint256);
     function poolInfo(uint _poolId) external view returns (address, uint,uint,uint);
     function userInfo(uint _poolId, address _user) external view returns (uint,uint);
     function deposit(uint poolId, uint amount) external;
     function withdraw(uint poolId, uint amount) external;
     function cakePerBlock() external view returns (uint);
     function updatePool(uint poolId) external;
}

interface iRouter { 
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);    
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function addLiquidityETH(address token,uint amountTokenDesired ,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidityETH(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidity(address tokenA,address tokenB, uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountToken, uint amountETH);
}

interface iLPToken{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);    
}

contract combineApp is Ownable, AccessControl{
    uint public poolId;
    address private chefContract;
    address private routeContract;
    address private factoryContract;
    address private rewardToken;
    address private feeCollector;
    address public lpContract;
    address public token0;
    address public token1;
    
    uint public holdBack;
    uint fee;

    uint256 constant MAX_INT = type(uint).max;
    address WBNB_ADDR = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
   
    bool _locked = false;
   
    event uintLog( string message, uint value);
    event uintLog( string message, uint[] value);
    event Deposit(uint amount);
    event Received(address sender, uint amount);
    event NewPool(uint oldPool, uint newPool);
    event LiquidityProvided(uint256 farmIn, uint256 wethIn, uint256 lpOut);

    bytes32 public constant HARVESTER = keccak256("HARVESTER");

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

    constructor(uint _poolId, uint _fee, address _harvester, address _feeCollector) //, uint _holdback, address _chefContract, address _factoryContract, address _routeContract, address _rewardToken) 
    payable {
        require(fee < 20 *(10**18),"Invalid Fee");
        address harvester = (_harvester == address(0)) ? msg.sender : _harvester;
        feeCollector = (_feeCollector == address(0)) ? msg.sender : _feeCollector;
        fee = (_fee == 0) ? 2 * (10**18) : _fee;

        _setupRole(HARVESTER, harvester);
        _setupRole(DEFAULT_ADMIN_ROLE,owner());

        holdBack = 0; 
        
        chefContract = 0x73feaa1eE314F8c655E354234017bE2193C9E24E; //_chefContract;
        routeContract = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //_routeContract;
        factoryContract = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73; //_factoryContract;
        rewardToken = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //_rewardToken;
        
        setLP(_poolId);
        ERC20(rewardToken).approve(address(this),MAX_INT);
        ERC20(rewardToken).approve(routeContract,MAX_INT);

        if (msg.value > 0) {
            addFunds(msg.value);
            emit Deposit(msg.value);
        }
    }
    
    receive() external payable {
        addFunds(msg.value);
        emit Received(msg.sender, msg.value);
    }

    function deposit() external payable  {
        addFunds(msg.value);
        emit Deposit(msg.value);
    }

    function setLP(uint _poolId) private {
        address _lpContract;
        poolId = _poolId;
        (_lpContract,,,) = iMasterChef(chefContract).poolInfo(_poolId);
        require(_lpContract != address(0),"LP Contract not found");
        lpContract =  _lpContract;
        token0 = iLPToken(lpContract).token0();
        token1 = iLPToken(lpContract).token1();

        ERC20(token0).approve(routeContract,MAX_INT);
        ERC20(token1).approve(routeContract,MAX_INT);
        
        iLPToken(lpContract).approve(address(this),MAX_INT);
        iLPToken(lpContract).approve(chefContract,MAX_INT);        
        iLPToken(lpContract).approve(routeContract,MAX_INT);        
    }

    function setPool(uint _poolId) public allowAdmin {
        (uint a, uint b) = iMasterChef(chefContract).userInfo(poolId,address(this));
        require(a == 0, "Currently invested in a pool, unable to change");
        setLP(_poolId);
    }

    function swapPool(uint _newPool) public allowAdmin {
        uint oldPool = poolId;
        
        removeLiquidity();
        revertBalance();
        
        uint _bal = address(this).balance;
        require(_bal>0,"Balance required before swap");
        
        setLP(_newPool);
        addFunds(_bal);
        
        emit NewPool(oldPool,_newPool);
    }
    
    function pendingReward() public view returns (uint) {
        
        uint pendingReward_val =  iMasterChef(chefContract).pendingCake(poolId,address(this));
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
    
    function setHoldBack(uint _holdback) public onlyOwner {
        holdBack = _holdback;
        emit uintLog("holdback",_holdback);
    }
    
    function sendHoldBack() public onlyOwner lockFunction{
        uint bal = address(this).balance;
        require(bal > 0,"Nothing to send");
        payable(owner()).transfer(bal);
        emit uintLog("Transferred holdback",bal);
    }
    
    function harvest() public lockFunction allowAdmin {
        uint split = do_harvest(1);
        
        addFunds(split);
    }
    
    function tokenBalance() internal returns (uint _bal0,uint _bal1) {
        _bal0 = ERC20(token0).balanceOf(address(this));
        _bal1 = ERC20(token1).balanceOf(address(this));
    }    

    function addFunds(uint inValue) internal {
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

    function addLiquidity(uint amount0, uint amount1) internal {
        uint amountA;
        uint amountB;
        uint liquidity;

        if (token1 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(routeContract).addLiquidityETH{value: amount1}(token0, amount0, 0,0, address(this), block.timestamp);
        }
        else if (token0 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(routeContract).addLiquidityETH{value: amount0}(token1, amount1, 0,0, address(this), block.timestamp);
        }
        else {
            ( amountA,  amountB, liquidity) = iRouter(routeContract).addLiquidity(token0, token1, amount0, amount1, 0, 0, address(this), block.timestamp);
        }

        iMasterChef(chefContract).deposit(poolId,liquidity);
        emit LiquidityProvided(amountA, amountB, liquidity);
    }
    
    function swap(uint amountIn, address[] memory path) internal returns (uint){
        require(amountIn > 0, "Amount for swap required");

        uint[] memory amounts;

        uint deadline = block.timestamp + 600;

        if (path[path.length - 1] == WBNB_ADDR) {
            amounts = iRouter(routeContract).swapExactTokensForETH(amountIn, 0,  path, address(this), deadline);
        } else if (path[0] == WBNB_ADDR ) {
            amounts = iRouter(routeContract).swapExactETHForTokens{value: amountIn}(0,path,address(this),deadline);
        }
        else {
            amounts = iRouter(routeContract).swapExactTokensForTokens(amountIn, 0,path,address(this),deadline);
        }
        
        return amounts[1];
    }
    
    function do_harvest(uint revert_trans) internal returns (uint) {
        uint pendingCake = 0;
        pendingCake = iMasterChef(chefContract).pendingCake(poolId, address(this));
        if (pendingCake == 0) {
            if (revert_trans == 1) {
                revert("Nothing to harvest");
            }
            else {
                pendingCake = ERC20(rewardToken).balanceOf(address(this));
                if (pendingCake == 0) {
                    return 0;
                }
            }
        }
        else  {
            iMasterChef(chefContract).deposit(poolId,0);
            pendingCake = ERC20(rewardToken).balanceOf(address(this));
        }

        address[] memory path = new address[](2);
        path[0] = rewardToken;
        path[1] = WBNB_ADDR;

        pendingCake = swap(pendingCake,path);

        uint feeAmount = (pendingCake/100) * (fee/10**18);

        payable(address(feeCollector)).transfer(feeAmount);

        uint finalReward = pendingCake - feeAmount;

        if (holdBack > 0) {
            uint holdbackAmount = (finalReward/100) * (holdBack/10**18);
            finalReward = finalReward - holdbackAmount;
            payable(owner()).transfer(holdbackAmount);
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
            (amountTokenA, amountTokenB) = iRouter(routeContract).removeLiquidityETH(token0,_removed,0,0,address(this), deadline);
        else
            (amountTokenA, amountTokenB) = iRouter(routeContract).removeLiquidity(token0,token1,_removed,0,0,address(this), deadline);
    }

    function revertBalance() private {
        (uint _bal0, uint _bal1) = tokenBalance();
        
        address[] memory path = new address[](2);
        path[1] = WBNB_ADDR;
        uint amount0 = 0;
        
        if (token0 != WBNB_ADDR) {
            path[0] = token0;
            amount0 += swap(_bal0, path);
        }
        
        if (token1 != WBNB_ADDR) {
            path[0] = token1;
            amount0 += swap(_bal1, path);
        }

        tokenBalance();
    }
    
    function cakePerBlock() public view returns(uint) {
        return iMasterChef(chefContract).cakePerBlock();
    }    
    
    
    function addReward() public payable onlyOwner returns(uint) {
        address[] memory path = new address[](2);
        path[0] = WBNB_ADDR;
        path[1] = rewardToken;
        uint amount = swap(msg.value, path);
        return amount;
    }

    function testHarvest() public onlyOwner lockFunction {
        uint tmp = do_harvest(0);
        if (tmp > 0){
            addFunds(tmp);
        }
    }
    
    function updatePool() public {
        iMasterChef(chefContract).updatePool(poolId);
    }
    
    function userInfo() public view allowAdmin returns (uint,uint) {
        (uint a, uint b) = iMasterChef(chefContract).userInfo(poolId,address(this));
        return (a,b);
    }
    
    function myBalance() public view returns(uint) {
        return address(this).balance;
    }
//$20 aprox:
//63973400000000000
//dev testing
//"411","10000000000000000000","0x2320738301305c892B01f44E4E9854a2D19AE19e","0x2320738301305c892B01f44E4E9854a2D19AE19e"
//live testing
//"354","10000000000000000000","0x42a515c1EDB651F4c69c56E05578D2805D6451eB","0x42a515c1EDB651F4c69c56E05578D2805D6451eB"
// Swap to 427
}

