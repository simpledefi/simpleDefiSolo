//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./Interfaces.sol";
import "./Storage.sol";

contract combineApp is Storage, Ownable, AccessControl {
    event uintLog( string message, uint value);
    event uintLog( string message, uint[] value);
    event Deposit(uint amount);
    event HoldBack(uint amount, uint total);
    event FeeSent(uint amount,uint total);
    event Received(address sender, uint amount);
    event NewPool(uint64 oldPool, uint newPool);
    event LiquidityProvided(uint256 farmIn, uint256 wethIn, uint256 lpOut);
    event Initialized(uint64 poolId, address lpContract);

    error Locked();
    error InitializedError();
    error InsufficentBalance();
    error RequiredParameter(string param);
    error InvestedPool(uint _poolID);
    
    modifier lockFunction() {
        if (_locked == true) revert Locked();
        _locked = true;
        _;
        _locked = false;
    }
     
    modifier allowAdmin() {
        require(hasRole(HARVESTER,msg.sender) || owner() == msg.sender,"Restricted Function");
        _;
    }

    modifier clearPool(uint64 _slotId) {
        slotsLib.sSlots memory _slot = getSlot(_slotId);

        if (_slot.poolId > 0) {
            (uint a, ) = iMasterChef(_slot.chefContract).userInfo(_slot.poolId,address(this));
            if (a != 0) revert InvestedPool(_slot.poolId);
        }
        _;
    }

    function initialize(uint64 _poolId, address _beacon, string memory _exchangeName, address _owner) public onlyOwner payable {
        if (_initialized == true) revert InitializedError();
        _initialized = true;
        beaconContract = _beacon;

        address harvester = iBeacon(beaconContract).getAddress("HARVESTER");
        feeCollector = iBeacon(beaconContract).getAddress("FEECOLLECTOR");

        _setupRole(HARVESTER, harvester);
        _setupRole(DEFAULT_ADMIN_ROLE,owner());

        holdBack = 0; 

        setup(_poolId,_exchangeName);
        transferOwnership(_owner);
    }

    function addHarvester(address _address) public onlyOwner {
        _setupRole(HARVESTER,_address);
    }

    function removeHarvester(address _address) public onlyOwner{
        revokeRole(HARVESTER,_address);
    }
    function newExchange(uint64 _slotId, uint64 _poolId, string memory _exchangeName) public onlyOwner clearPool(_slotId) {

        if (beaconContract == address(0)) revert RequiredParameter("beaconContract");
        if (bytes(_exchangeName).length == 0) revert RequiredParameter("_exchangeName");

        setup(_poolId, _exchangeName);
        slotsLib.updateSlot(_slotId, _poolId, _exchangeName, slots, beaconContract);
    }

    function setup(uint64 _poolId, string memory _exchangeName) private  {
        slotsLib.sSlots memory _slot = slotsLib.updateSlot(uint64(slotsLib.MAX_SLOTS+1),_poolId,_exchangeName, slots, beaconContract);

        if (msg.value > 0) {
            addFunds(_slot, msg.value);
            emit Deposit(msg.value);
        }
        emit Initialized(_poolId,_slot.lpContract);
    }
    
    receive() external payable {}

    function deposit(uint64 _slotId) external onlyOwner payable  {
        slotsLib.sSlots memory _slot = getSlot(_slotId);
        uint deposit_amount = msg.value;
        uint pendingReward_val =  pendingReward(_slotId);
        if (pendingReward_val > 0) {
            deposit_amount = deposit_amount + do_harvest(_slot, 0);
        }
        addFunds(_slot, deposit_amount);
        emit Deposit(deposit_amount);
    }

    function setPool(uint64 _slotId, uint64 _poolId) public allowAdmin clearPool(_slotId) payable {
        slotsLib.sSlots memory _slot = getSlot(_slotId);
        _slot = slotsLib.updateSlot(_slotId, _poolId, _slot.exchangeName,slots, beaconContract);
        if (msg.value > 0) {
            addFunds(_slot, msg.value);
            emit Deposit(msg.value);
        }
    }

    function swapPool(uint64 _slotId, uint64 _newPool) public allowAdmin {
        slotsLib.sSlots memory _slot = getSlot(_slotId);

        if(_newPool == _slot.poolId) revert RequiredParameter("New pool required");
        uint64 oldPool = _slot.poolId;
        
        removeLiquidity(_slot);
        revertBalance(_slot);
        
        uint _bal = address(this).balance;
        if (_bal==0) revert InsufficentBalance();
        
        // setLP(_newPool);
        slotsLib.updateSlot(_slotId,_newPool,_slot.exchangeName,slots, beaconContract);
        addFunds(_slot,_bal);
        
        emit NewPool(oldPool,_newPool);
    }
    
    function pendingReward(uint64 _slotId) public view returns (uint) {        
        slotsLib.sSlots memory _slot = getSlot(_slotId);
        return pendingReward(_slot);
    }

    function pendingReward(slotsLib.sSlots memory _slot) private view returns (uint) {
        // uint pendingReward_val =  iMasterChef(chefContract).pendingCake(poolId,address(this));
        (, bytes memory data) = _slot.chefContract.staticcall(abi.encodeWithSignature(_slot.pendingCall, _slot.poolId,address(this)));
        uint pendingReward_val = abi.decode(data,(uint256));
        if (pendingReward_val == 0) {
            pendingReward_val += ERC20(_slot.rewardToken).balanceOf(address(this));
        }
        return pendingReward_val;
    }
    
    function liquidate(uint64 _slotId) public onlyOwner lockFunction {
        slotsLib.sSlots memory _slot = getSlot(_slotId);
        do_harvest(_slot, 0);
        removeLiquidity(_slot);
        revertBalance(_slot);        
        uint _total = address(this).balance;
        slotsLib.removeSlot(_slotId,slots);
        payable(owner()).transfer(_total);
        emit uintLog("Liquidate Total",_total);
    }
    
    function setHoldBack(uint64 _holdback) public onlyOwner {
        holdBack = _holdback;
        emit uintLog("holdback",_holdback);
    }
    
    function sendHoldBack() public onlyOwner lockFunction{
        uint bal = address(this).balance;
        if (bal == 0) revert InsufficentBalance();
        payable(owner()).transfer(bal);
        emit HoldBack(bal,bal);
    }
    
    function harvest(uint64 _slotId) public lockFunction allowAdmin {
        slotsLib.sSlots memory _slot = getSlot(_slotId);
        uint64 _offset = iBeacon(beaconContract).getConst('DEFAULT','HARVESTSOLOGAS');
        emit uintLog("Offset",_offset);
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

    function addFunds(slotsLib.sSlots memory _slot, uint inValue) private {
        if (inValue==0) revert InsufficentBalance();

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
        emit LiquidityProvided(amountA, amountB, liquidity);
    }
    
    function swap(slotsLib.sSlots memory _slot, uint amountIn, address[] memory path) private returns (uint){
        if (amountIn == 0) revert InsufficentBalance();
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
        
        uint64 fee = iBeacon(beaconContract).getFee('PANCAKESWAP','HARVEST',owner());
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
    
    function removeLiquidity(slotsLib.sSlots memory _slot) private {
        uint amountTokenA;
        uint amountTokenB;
        uint deadline = block.timestamp + 600;

        (uint _lpBal,) = iMasterChef(_slot.chefContract).userInfo(_slot.poolId,address(this));
        iMasterChef(_slot.chefContract).withdraw(_slot.poolId,_lpBal);
        
        uint _removed = ERC20(_slot.lpContract).balanceOf(address(this));
        emit uintLog("_removed",_removed);
        
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
    
    function cakePerBlock(uint64 _slotId) public view returns(uint) {
        slotsLib.sSlots memory _slot = getSlot(_slotId);
        return iMasterChef(_slot.chefContract).cakePerBlock();
    }    
    
    function updatePool(uint64 _slotId) public {
        slotsLib.sSlots memory _slot = getSlot(_slotId);

        iMasterChef(_slot.chefContract).updatePool(_slot.poolId);
    }
    
    function userInfo(uint64 _slotId) public view allowAdmin returns (uint,uint,uint,uint,uint,uint) {
        slotsLib.sSlots memory _slot = getSlot(_slotId);

        (uint a, uint b) = iMasterChef(_slot.chefContract).userInfo(_slot.poolId,address(this));
        (uint c, uint d) = tokenBalance(_slot);
        uint e = ERC20(_slot.rewardToken).balanceOf(address(this));
        uint f = address(this).balance;
        return (a,b,c,d,e,f);
    }

    function getSlot(uint64 _slotId) public view returns (slotsLib.sSlots memory) {
        return slotsLib.getSlot(_slotId, slots, beaconContract);
    }

    function poolId(uint64 _slotId) public view returns (uint) {
        slotsLib.sSlots memory _slot = getSlot(_slotId);
        return _slot.poolId;
    }
}

