//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./Interfaces.sol";
import "./Storage.sol";

contract combineApp is Storage, Ownable, AccessControl {
    event sdUintLog( string message, uint value);
    event sdUintLog( string message, uint[] value);
    event sdDeposit(uint amount);
    event sdHoldBack(uint amount, uint total);
    event sdFeeSent(uint amount,uint total);
    event sdNewPool(uint64 oldPool, uint newPool);
    event sdLiquidityProvided(uint256 farmIn, uint256 wethIn, uint256 lpOut);
    event sdInitialized(uint64 poolId, address lpContract);

    error sdLocked();
    error sdInitializedError();
    error sdInsufficentBalance();
    error sdRequiredParameter(string param);
    
    modifier lockFunction() {
        if (_locked == true) revert sdLocked();
        _locked = true;
        _;
        _locked = false;
    }
     
    modifier allowAdmin() {
        require(hasRole(HARVESTER,msg.sender) || owner() == msg.sender,"Restricted Function");
        _;
    }

    function initialize(uint64 _poolId, address _beacon, string memory _exchangeName, address _owner) public onlyOwner payable {
        if (_initialized == true) revert sdInitializedError();
        _initialized = true;
        beaconContract = _beacon;

        address harvester = iBeacon(beaconContract).getAddress("HARVESTER");
        feeCollector = iBeacon(beaconContract).getAddress("FEECOLLECTOR");

        _setupRole(HARVESTER, harvester);
        _setupRole(DEFAULT_ADMIN_ROLE,owner());

        holdBack = 0; 
        
        setup(_poolId, _exchangeName);
        transferOwnership(_owner);
    }

    function addHarvester(address _address) public onlyOwner {
        _setupRole(HARVESTER,_address);
    }

    function removeHarvester(address _address) public onlyOwner{
        revokeRole(HARVESTER,_address);
    }
    function setup(uint64 _poolId, string memory _exchangeName) private  {
        slotsLib.sSlots memory _slot = slotsLib.updateSlot(uint64(slotsLib.MAX_SLOTS+1),_poolId,_exchangeName, slots, beaconContract);

        if (msg.value > 0) {
            addFunds(_slot, msg.value);
            emit sdDeposit(msg.value);
        }
        emit sdInitialized(_poolId,_slot.lpContract);
    }
    
    receive() external payable {}

    function deposit(uint64 _poolId, string memory _exchangeName) external onlyOwner payable  {
        slotsLib.sSlots memory _slot = slotsLib.getDepositSlot(_poolId, _exchangeName,slots, beaconContract);
        uint deposit_amount = msg.value;
        uint pendingReward_val =  pendingReward(_slot);
        if (pendingReward_val > 0) {
            deposit_amount = deposit_amount + do_harvest(_slot, 0);
        }
        addFunds(_slot, deposit_amount);
        emit sdDeposit(deposit_amount);
    }

    function swapPool(uint64 _fromPoolId, string memory _fromExchangeName, uint64 _toPoolId, string memory _toExchangeName) public allowAdmin {
        slotsLib.sSlots memory _slot = getSlot(_fromPoolId, _fromExchangeName);
        
        if(_toPoolId == _slot.poolId) revert sdRequiredParameter("New pool required");
        
        removeLiquidity(_slot);
        revertBalance(_slot);
        
        uint _bal = address(this).balance;
        if (_bal==0) revert sdInsufficentBalance();
        
        _slot = slotsLib.swapSlot(_fromPoolId, _fromExchangeName,_toPoolId, _toExchangeName,slots, beaconContract);
        addFunds(_slot,_bal);
        emit sdNewPool(_fromPoolId,_toPoolId);
    }
    
    function pendingReward(uint64 _poolId, string memory _exchangeName) public view returns (uint) {        
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        return pendingReward(_slot);
    }

    function pendingReward(slotsLib.sSlots memory _slot) private view returns (uint) {
        (, bytes memory data) = _slot.chefContract.staticcall(abi.encodeWithSignature(_slot.pendingCall, _slot.poolId,address(this)));
        uint pendingReward_val = data.length==0?0:abi.decode(data,(uint256));
        if (pendingReward_val == 0) {
            pendingReward_val += ERC20(_slot.rewardToken).balanceOf(address(this));
        }
        return pendingReward_val;
    }
    
    function liquidate(uint64 _poolId, string memory _exchangeName) public onlyOwner lockFunction {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        do_harvest(_slot, 0);
        removeLiquidity(_slot);
        revertBalance(_slot);        
        uint _total = address(this).balance;
        slotsLib.removeSlot(_slot.poolId, _slot.exchangeName,slots);

        _total = sendFee("LIQUIDATE",_total,0);

        payable(owner()).transfer(_total);
        emit sdUintLog("Liquidate Total",_total);
    }
    
    function setHoldBack(uint64 _holdback) public onlyOwner {
        holdBack = _holdback;
        emit sdUintLog("holdback",_holdback);
    }
    
    function sendHoldBack() public onlyOwner lockFunction{
        uint bal = address(this).balance;
        if (bal == 0) revert sdInsufficentBalance();
        payable(owner()).transfer(bal);
        emit sdHoldBack(bal,bal);
    }
    
    function harvest(uint64  _poolId, string memory _exchangeName) public lockFunction allowAdmin {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        uint64 _offset = iBeacon(beaconContract).getConst('DEFAULT','HARVESTSOLOGAS');
        uint startGas = gasleft() + 21000 + _offset;
        uint split = do_harvest(_slot, 1);
        
        addFunds(_slot, split);
        if (msg.sender != owner()) {
            lastGas = startGas - gasleft();
        }
    }
    
    function tokenBalance(slotsLib.sSlots memory _slot) private view returns (uint _bal0,uint _bal1) {
        _bal0 = ERC20(_slot.token0).balanceOf(address(this));
        _bal1 = ERC20(_slot.token1).balanceOf(address(this));
    }    
    
    function rescueToken(address token) public onlyOwner{
        uint _bal = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(owner(),_bal);
    }

    function addFunds(slotsLib.sSlots memory _slot, uint inValue) private  {
        if (inValue==0) revert sdInsufficentBalance();

        uint amount0;
        uint amount1;
        uint split = (inValue*50)/100;
        
        if (_slot.token0 != WBNB_ADDR) {
            address[] memory path1 = new address[](2);
            path1[0] = WBNB_ADDR;
            path1[1] = _slot.token0;
            amount0 = swap(_slot, split,path1);
        }
        else{
            amount0 = split;
        }
        
        if (_slot.token1 != WBNB_ADDR) {
            address[] memory path2 = new address[](2);
            path2[0] = WBNB_ADDR;
            path2[1] = _slot.token1;
            amount1 = swap(_slot, split,path2);
        }       
        else{
            amount1 = split;
        }
        addLiquidity(_slot,amount0,amount1);
    }

    function addLiquidity(slotsLib.sSlots memory _slot, uint amount0, uint amount1) private {
        uint amountA;
        uint amountB;
        uint liquidity;
                

        if (_slot.token1 == WBNB_ADDR || _slot.token0 == WBNB_ADDR) {
            (amount0,amount1) = _slot.token0 == WBNB_ADDR?(amount0,amount1):(amount1,amount0);
            address token = _slot.token0 == WBNB_ADDR?_slot.token1:_slot.token0;
            (amountA, amountB, liquidity) = iRouter(_slot.routerContract).addLiquidityETH{value: amount0}(token, amount1, 0,0, address(this), block.timestamp);
        }
        else {
            ( amountA,  amountB, liquidity) = iRouter(_slot.routerContract).addLiquidity(_slot.token0, _slot.token1, amount0, amount1, 0, 0, address(this), block.timestamp);
        }

        iMasterChef(_slot.chefContract).deposit(_slot.poolId,liquidity);
        emit sdLiquidityProvided(amountA, amountB, liquidity);
    }
    
    function swap(slotsLib.sSlots memory _slot, uint amountIn, address[] memory path) private returns (uint){
        if (amountIn == 0) revert sdInsufficentBalance();
        uint pathLength = (_slot.intermediateToken != address(0) && path[0] != _slot.intermediateToken && path[1] != _slot.intermediateToken) ? 3 : 2;
        address[] memory swapPath = new address[](pathLength);
        
        if (pathLength == 2) {
            swapPath[0] = path[0];
            swapPath[1] = path[1];
        }
        else {
            swapPath[0] = path[0];
            swapPath[1] = _slot.intermediateToken;
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
                amounts = iRouter(_slot.routerContract).swapExactTokensForETH(amountIn, 0,  swapPath, address(this), deadline);
            } else if (path[0] == WBNB_ADDR) {
                amounts = iRouter(_slot.routerContract).swapExactETHForTokens{value: amountIn}(0,swapPath,address(this),deadline);
            }
            else {
                amounts = iRouter(_slot.routerContract).swapExactTokensForTokens(amountIn, 0,swapPath,address(this),deadline);
            }
            return amounts[swapPath.length-1];
        }
    }
    
    function do_harvest(slotsLib.sSlots memory _slot,uint revert_trans) private returns (uint) {
        uint pendingCake = 0;
        pendingCake = pendingReward(_slot);
        if (pendingCake == 0) {
            if (revert_trans == 1) {
                revert("Nothing to harvest");
            }
            else {
                    return 0;
            }
        }
        
        iMasterChef(_slot.chefContract).deposit(_slot.poolId,0);
        pendingCake = ERC20(_slot.rewardToken).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = _slot.rewardToken;
        path[1] = WBNB_ADDR;

        pendingCake = swap(_slot, pendingCake,path);
        
        uint finalReward = sendFee('HARVEST',pendingCake, ((lastGas * tx.gasprice)*10e8)); // lastGas is here in case 3rd party harvester is used, should normally be 0
        
        if (holdBack > 0) {
            uint holdbackAmount = (finalReward/100) * (holdBack/10**18);
            finalReward = finalReward - holdbackAmount;
            payable(owner()).transfer(holdbackAmount);
            emit sdHoldBack(holdbackAmount,finalReward);

        }
        return finalReward;
    }
    
    function removeLiquidity(slotsLib.sSlots memory _slot) private {
        uint amountTokenA;
        uint amountTokenB;
        uint deadline = block.timestamp + 600;

        (uint _lpBal,) = iMasterChef(_slot.chefContract).userInfo(_slot.poolId,address(this));
        iMasterChef(_slot.chefContract).withdraw(_slot.poolId,_lpBal);
        
        uint _removed = ERC20(_slot.lpContract).balanceOf(address(this));
        emit sdUintLog("_removed",_removed);
        
        if (_slot.token1 == WBNB_ADDR)
            (amountTokenA, amountTokenB) = iRouter(_slot.routerContract).removeLiquidityETH(_slot.token0,_removed,0,0,address(this), deadline);
        else
            (amountTokenA, amountTokenB) = iRouter(_slot.routerContract).removeLiquidity(_slot.token0,_slot.token1,_removed,0,0,address(this), deadline);
    }

    function revertBalance(slotsLib.sSlots memory _slot) private {
        address[] memory path = new address[](2);
        path[1] = WBNB_ADDR;
        uint amount0 = 0;

        uint _rewards = ERC20(_slot.rewardToken).balanceOf(address (this));
        if (_rewards > 0 ){
            path[0] = _slot.rewardToken;
            amount0 = swap(_slot, _rewards, path);
        }

        (uint _bal0, uint _bal1) = tokenBalance(_slot);
        
        if (_bal0 > 0) {
            path[0] = _slot.token0;
            amount0 += swap(_slot, _bal0, path);
        }
        
        if (_bal1 > 0) {
            path[0] = _slot.token1;
            amount0 += swap(_slot, _bal1, path);
        }
    }
    
    function cakePerBlock(uint64  _poolId, string memory _exchangeName) public view returns(uint) {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        return iMasterChef(_slot.chefContract).cakePerBlock();
    }    
    
    function updatePool(uint64  _poolId, string memory _exchangeName) public {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);

        iMasterChef(_slot.chefContract).updatePool(_slot.poolId);
    }
    
    function userInfo(uint64  _poolId, string memory _exchangeName) public view allowAdmin returns (uint,uint,uint,uint,uint,uint) {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);

        if (_slot.lpContract == address(0))  return (0,0,0,0,0,0);
        
        (uint a, uint b) = iMasterChef(_slot.chefContract).userInfo(_slot.poolId,address(this));
        (uint c, uint d) = tokenBalance(_slot);
        uint e = ERC20(_slot.rewardToken).balanceOf(address(this));
        uint f = address(this).balance;
        return (a,b,c,d,e,f);
    }
    function sendFee(string memory _type, uint _total, uint _extra) private returns (uint){
        uint feeAmt = iBeacon(beaconContract).getFee('DEFAULT',_type,owner());
        // uint feeAmt = 19 * 1e18;
        uint feeAmount = ((_total * feeAmt)/100e18) + _extra;
        if (feeAmount > _total) feeAmount = _total;
        
        if(feeAmount > 0) {
            if (feeAmount > _total) {
                feeAmount = _total;
                _total = 0;
            }
            else {
                _total = _total - feeAmount;
            }
            payable(address(feeCollector)).transfer(feeAmount);
            emit sdFeeSent(feeAmount,_total);
        }
        return _total;
    }

    function getSlot(uint64 _poolId, string memory _exchangeName) public view returns (slotsLib.sSlots memory) {
        return slotsLib.getSlot(_poolId, _exchangeName, slots, beaconContract);
    }
}

    