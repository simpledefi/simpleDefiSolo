//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Storage.sol";
interface iApp {
    function  initialize(uint64 _poolId, address _beacon, string memory _exchangeName, address _owner) external payable;
}

interface prBeacon {
    function mExchanges(string memory _exchange) external returns(address);
    function getAddress(string memory _exchange) external returns(address);
    function getContractType(string memory _name) external returns (string memory _contract);
}

contract combine_proxy is Storage, Ownable, AccessControl  {
    modifier allowAdmin() {
        require(hasRole(HARVESTER,msg.sender) || owner() == msg.sender,"Restricted Function");
        _;
    }

    receive() external payable {}
    constructor(uint64 _pid, string memory _exchange, address beacon, address _owner) {
        bytes memory bExchange = bytes(_exchange);
        require(bExchange.length > 0, "Exchange is required");
        require(beacon != address(0), "Beacon Contract required");
        require(_owner != address(0), "Owner is required");
        _setupRole(DEFAULT_ADMIN_ROLE,owner());
        
        beaconContract = beacon;
        setExchange(_exchange);

        address _admin = prBeacon(beaconContract).getAddress("ADMINUSER");        
        require(_admin != address(0), "Admin address required");
        _setupRole(HARVESTER, _admin);
    }
    
    function setExchange(string memory _exchange) public allowAdmin returns (bool success){
        bytes memory bExchange = bytes(_exchange);
        require(bExchange.length > 0, "Exchange is required");
        exchange = _exchange;
        logic_contract = prBeacon(beaconContract).mExchanges(exchange);
        require(logic_contract != address(0), "Logic Contract required - setExchange");
        return true;
    }

    function getLogicContract() public view returns (address) {
       return logic_contract;
    }
    
    fallback () payable external {
        require(logic_contract != address(0),"Logic contract required");
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

contract proxyFactory is Ownable {
    address public beaconContract;

    mapping (address => address[]) public proxyContracts;
    address[] public proxyContractsUsers;

    constructor (address _beacon) {
        require(_beacon != address(0), "Beacon Contract required");
        beaconContract = _beacon;
    }

    function setBeacon(address _beaconContract) public onlyOwner {
        beaconContract = _beaconContract;
    }

    function addProxy(address _proxyContract, address _user) public onlyOwner {
        require(_proxyContract != address(0), "Proxy Contract required");
        require(_user != address(0), "User required");
        proxyContracts[_user].push(_proxyContract);
        proxyContractsUsers.push(_user);
    }

    function getLastProxy(address _user) public view returns (address) {
        require(_user != address(0), "User required");
        return proxyContracts[_user][proxyContracts[_user].length - 1];
    }
    
    function initialize(uint64  _pid, string memory _exchange) public payable returns (address) {
        require(_pid != 0, "Pool ID required");
        require(beaconContract != address(0), "Beacon Contract required");
        require(bytes(_exchange).length > 0,"Exchange Name cannot be empty");
        string memory _contract = prBeacon(beaconContract).getContractType(_exchange);

        combine_proxy proxy = new combine_proxy(_pid, _contract, beaconContract, msg.sender);
        proxyContracts[msg.sender].push(address(proxy));
        proxyContractsUsers.push(msg.sender);
        iApp(address(proxy)).initialize{value:msg.value}(_pid, beaconContract, _exchange,msg.sender);    

        return address(proxy);
    }
}
//"0x92aF24CDc779715bcf55f3BC4dc4C2d8F7729507","0xD0153B7c79473eA931DaA5FDb25751d7534c4c3B"