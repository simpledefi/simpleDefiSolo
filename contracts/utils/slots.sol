//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "../Interfaces.sol";

library slotsLib {
    struct slotStorage {
        uint poolId;
        string exchangeName;
        address lpContract;
        address token0;
        address token1;
    }

    struct sSlots {
        uint64 poolId;
        string exchangeName;
        address lpContract;
        address token0;
        address token1;
        address chefContract;
        address routerContract;
        address rewardToken;
        string pendingCall;
        address intermediateToken;
        
    }

    uint64 constant MAX_SLOTS = 100;
    uint256 constant MAX_INT = type(uint).max;


    error RequiredParameter(string param);
    error InactivePool(uint _poolID);
    error MaxSlots();
    error SlotOutOfBounds();
    event SlotsUpdated();

    function addSlot(uint64 _poolId, string memory _exchangeName, slotStorage[] storage slots,address beaconContract) internal returns (uint) {
        uint _slotId = find_slot(_poolId, _exchangeName, slots);
        if (_slotId != MAX_SLOTS) return _slotId;

        if (slots.length+1 >= MAX_SLOTS) revert MaxSlots();
        updateSlot(MAX_SLOTS+1,_poolId,_exchangeName,slots,beaconContract);
        return slots.length - 1;
    }

    function swapSlot(uint _fromPoolId, string memory _fromExchangeName, uint _toPoolId, string memory _toExchangeName, slotStorage[] storage slots, address beaconContract) internal returns (sSlots memory) {
        uint64 _fromSlotId = find_slot(_fromPoolId, _fromExchangeName, slots);
        if (_fromSlotId == MAX_SLOTS) revert InactivePool(_fromPoolId);
        return updateSlot(_fromSlotId, _toPoolId, _toExchangeName, slots, beaconContract);
    }

    function updateSlot(uint64 _slotId, uint _poolId, string memory _exchangeName, slotStorage[] storage slots, address beaconContract) internal returns (sSlots memory) {
        (address _chefContract, address _routerContract, address _rewardToken, string memory _pendingCall, address _intermediateToken,) = iBeacon(beaconContract).getExchangeInfo(_exchangeName);
        (address _lpContract,uint _alloc,,) = iMasterChef(_chefContract).poolInfo(_poolId);

        if (_lpContract == address(0)) revert RequiredParameter("_lpContract");
        if (_alloc == 0) revert InactivePool(_poolId);

        if (_slotId == MAX_SLOTS+1) {
            slots.push(slotStorage(_poolId,_exchangeName,_lpContract, iLPToken(_lpContract).token0(),iLPToken(_lpContract).token1()));
            _slotId = uint64(slots.length - 1);
        } else {
            if (_slotId >= slots.length) revert SlotOutOfBounds();
            slots[_slotId] = slotStorage(_poolId,_exchangeName,_lpContract, iLPToken(_lpContract).token0(),iLPToken(_lpContract).token1());
        }     

        
        if (ERC20(_rewardToken).allowance(address(this), _routerContract) == 0) {
            ERC20(slots[_slotId].token0).approve(_routerContract,MAX_INT);
            ERC20(slots[_slotId].token1).approve(_routerContract,MAX_INT);
            ERC20(_rewardToken).approve(address(this),MAX_INT);
            ERC20(_rewardToken).approve(_routerContract,MAX_INT);
            iLPToken(_lpContract).approve(address(this),MAX_INT);
            iLPToken(_lpContract).approve(_chefContract,MAX_INT);        
            iLPToken(_lpContract).approve(_routerContract,MAX_INT);                            
        }
        emit SlotsUpdated();
        return sSlots(uint64(slots[_slotId].poolId),slots[_slotId].exchangeName,slots[_slotId].lpContract, slots[_slotId].token0,slots[_slotId].token1,_chefContract,_routerContract,_rewardToken,_pendingCall,_intermediateToken);
    }

    function removeSlot(uint _poolId, string memory _exchangeName, slotStorage[] storage slots) internal returns (uint) {
        uint _slotId = find_slot(_poolId,_exchangeName,slots);
        if (_slotId >= slots.length) revert SlotOutOfBounds();
        slots[_slotId] = slots[slots.length-1];
        slots.pop();

        emit SlotsUpdated();
        return slots.length;
    }


    function find_slot(uint _poolId, string memory _exchangeName, slotStorage[] storage slots) private view returns (uint64){
        for(uint64 i = 0;i<slots.length;i++) {
            if (slots[i].poolId == _poolId && keccak256(bytes(slots[i].exchangeName)) == keccak256(bytes(_exchangeName))) { //this is to get around storage type differences...
                return i;
            }
        }
        return MAX_SLOTS+1;
    }
    function getSlot(uint _poolId, string memory _exchangeName, slotStorage[] storage slots, address beaconContract) internal view returns (sSlots memory) {
        uint64 _slotId = find_slot(_poolId,_exchangeName,slots);
        if (_slotId >= slots.length) revert SlotOutOfBounds();
        (address _chefContract, address _routerContract, address _rewardToken, string memory _pendingCall, address _intermediateToken,) = iBeacon(beaconContract).getExchangeInfo(slots[_slotId].exchangeName);
        return sSlots(uint64(slots[_slotId].poolId),slots[_slotId].exchangeName,slots[_slotId].lpContract, slots[_slotId].token0,slots[_slotId].token1,_chefContract,_routerContract,_rewardToken,_pendingCall,_intermediateToken);
    }    
}