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
        uint poolId;
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

    uint constant MAX_SLOTS = 100;
    uint256 constant MAX_INT = type(uint).max;


    error RequiredParameter(string param);
    error InactivePool(uint _poolID);

    error MaxSlots();
    error SlotOutOfBounds();

    function addSlot(uint _poolId, string memory _exchangeName, slotStorage[] storage slots,address beaconContract) internal returns (uint) {
        for(uint8 i = 0;i<slots.length;i++) {
            if (slots[i].poolId == _poolId && keccak256(bytes(slots[i].exchangeName)) == keccak256(bytes(_exchangeName))) {
                return i;
            }
        }
        if (slots.length+1 >= MAX_SLOTS) revert MaxSlots();
        updateSlot(MAX_SLOTS+1,_poolId,_exchangeName,slots,beaconContract);
        return slots.length - 1;
    }

    function updateSlot(uint _slotId, uint _poolId, string memory _exchangeName, slotStorage[] storage slots, address beaconContract) internal returns (sSlots memory) {
        (address _chefContract, address _routerContract, address _rewardToken, string memory _pendingCall, address _intermediateToken,) = iBeacon(beaconContract).getExchangeInfo(_exchangeName);
        (address _lpContract,uint _alloc,,) = iMasterChef(_chefContract).poolInfo(_poolId);
        
        if (_lpContract == address(0)) revert RequiredParameter("_lpContract");
        if (_alloc == 0) revert InactivePool(_poolId);

        if (_slotId == MAX_SLOTS+1) {
            slots.push(slotStorage(_poolId,_exchangeName,_lpContract, iLPToken(_lpContract).token0(),iLPToken(_lpContract).token1()));
            _slotId = slots.length - 1;
        } else {
            if (_slotId >= slots.length) revert SlotOutOfBounds();
            slots[_slotId] = slotStorage(_poolId,_exchangeName,_lpContract, iLPToken(_lpContract).token0(),iLPToken(_lpContract).token1());
        }     

        if (ERC20(_rewardToken).allowance(address(this), _routerContract) == 0) {
            ERC20(_rewardToken).approve(address(this),MAX_INT);
            ERC20(_rewardToken).approve(_routerContract,MAX_INT);
            iLPToken(_lpContract).approve(address(this),MAX_INT);
            iLPToken(_lpContract).approve(_chefContract,MAX_INT);        
            iLPToken(_lpContract).approve(_routerContract,MAX_INT);                            
        }

        return sSlots(slots[_slotId].poolId,slots[_slotId].exchangeName,slots[_slotId].lpContract, slots[_slotId].token0,slots[_slotId].token1,_chefContract,_routerContract,_rewardToken,_pendingCall,_intermediateToken);
    }

    function getSlot(uint _slotId, slotStorage[] memory slots, address beaconContract) internal view returns (sSlots memory) {
        if (_slotId >= slots.length) revert SlotOutOfBounds();
        (address _chefContract, address _routerContract, address _rewardToken, string memory _pendingCall, address _intermediateToken,) = iBeacon(beaconContract).getExchangeInfo(slots[_slotId].exchangeName);
        return sSlots(slots[_slotId].poolId,slots[_slotId].exchangeName,slots[_slotId].lpContract, slots[_slotId].token0,slots[_slotId].token1,_chefContract,_routerContract,_rewardToken,_pendingCall,_intermediateToken);
    }    
}