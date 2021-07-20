//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Storage.sol";

contract combine_proxy is Storage, Ownable, AccessControl  {
    modifier allowAdmin() {
        require(hasRole(HARVESTER,msg.sender) || owner() == msg.sender,"Restricted Function");
        _;
    }

    constructor(address _c, address _admin) {
        logic_contract = _c;
        _setupRole(HARVESTER, _admin);
        _setupRole(DEFAULT_ADMIN_ROLE,owner());
    }
    
    function setLogicContract(address _c) public allowAdmin returns (bool success){
        logic_contract = _c;
        return true;
    }
    
    fallback () payable external {
        address target = logic_contract;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}
//"0x92aF24CDc779715bcf55f3BC4dc4C2d8F7729507","0xD0153B7c79473eA931DaA5FDb25751d7534c4c3B"