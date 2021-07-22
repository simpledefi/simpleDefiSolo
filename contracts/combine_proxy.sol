//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Storage.sol";

interface pBeacon {
    function getExchange(string memory _exchange) external returns(address);
}

contract combine_proxy is Storage, Ownable, AccessControl  {
    modifier allowAdmin() {
        require(hasRole(HARVESTER,msg.sender) || owner() == msg.sender,"Restricted Function");
        _;
    }

    constructor(string memory _exchange, address beacon, address _admin) {
        bytes memory bExchange = bytes(_exchange);
        require(bExchange.length > 0, "Exchange is required");
        require(beacon != address(0), "Beacon Contract required");
        require(_admin != address(0), "Admin address required");
        
        exchange = _exchange;
        beaconContract = beacon;
        _setupRole(HARVESTER, _admin);
        _setupRole(DEFAULT_ADMIN_ROLE,owner());
    }
    
    function setExchange(string memory _exchange) public allowAdmin returns (bool success){
        bytes memory bExchange = bytes(_exchange);
        require(bExchange.length > 0, "Exchange is required");
        exchange = _exchange;
        
        return true;
    }
    function getExchange() public returns (address) {
            return pBeacon(beaconContract).getExchange(exchange);
    }
    
    fallback () payable external {
        address target = pBeacon(beaconContract).getExchange(exchange);
        require(target != address(0),"Logic contract required");
        
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