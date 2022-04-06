//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Storage.sol";
interface iApp {
    function  initialize(uint64 _poolId, address _beacon, string memory _exchangeName, address _owner) external payable;
}

interface prBeacon {
    function mExchanges(string memory _exchange) external returns(address);
    function getAddress(string memory _exchange) external returns(address);
    function getContractType(string memory _name, uint _type) external returns (string memory _contract);
}

contract combine_proxy is Storage, Ownable, AccessControl  {
    modifier allowAdmin() {
        require(hasRole(HARVESTER,msg.sender) || owner() == msg.sender,"Restricted Function");
        _;
    }

    error sdInitializedError();
    error sdFunctionLocked();

    receive() external payable {}

    constructor () {}


    ///@notice Initialize the proxy contract
    ///@param _exchange the name of the exchange
    ///@param _beacon the address of the beacon contract
    ///@param _owner the address of the owner
    function initialize (string memory _exchange, address _beacon, address _owner, uint _poolType) public payable onlyOwner {
        if (_initialized == true) revert sdInitializedError();

        bytes memory bExchange = bytes(_exchange);
        require(bExchange.length > 0, "Exchange is required");
        require(_beacon != address(0), "Beacon Contract required");
        require(_owner != address(0), "Owner is required");
        _setupRole(DEFAULT_ADMIN_ROLE,owner());
        _shared = _poolType == 1 ? true  : false;
        
        beaconContract = _beacon;
        setExchange(_exchange);

        address _admin = prBeacon(beaconContract).getAddress("ADMINUSER");        
        require(_admin != address(0), "Admin address required");
        _setupRole(HARVESTER, _admin);
        // transferOwnership(_owner);
    }
    
    ///@notice Sets the logic contract for the exchange
    ///@dev Call function if logic contract gets updated
    ///@param _exchange the name of the exchange
    ///@return success - success or failure
    function setExchange(string memory _exchange) public allowAdmin returns (bool success){
        bytes memory bExchange = bytes(_exchange);
        require(bExchange.length > 0, "Exchange is required");
        logic_contract = prBeacon(beaconContract).mExchanges(_exchange);
        require(logic_contract != address(0), "Logic Contract required - setExchange");
        return true;
    }

    ///@notice Gets the logic contract for the exchange
    function getLogicContract() public view returns (address) {
       return logic_contract;
    }
    
    ///@notice logic for the proxy part of the contract, uses delegatecall to send function call to the logic contract
    fallback () payable external {
        if(!_shared || msg.sender != owner() || !_initialized){ 
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
        else{
            revert sdFunctionLocked();
        }
    }
}

contract proxyFactory is Ownable {
    address public beaconContract;

    mapping (address => address[]) public proxyContracts;
    address[] public proxyContractsUsers;

    event NewProxy(address proxy, address user);


    ///@notice Initialize the proxy factory contract
    ///@param _beacon the address of the beacon contract
    constructor (address _beacon) {
        require(_beacon != address(0), "Beacon Contract required");
        beaconContract = _beacon;
    }

    ///@notice Sets the address of the beacon contract
    ///@dev call when beacon contract gets updated
    ///@param _beaconContract the address of the beacon contract
    function setBeacon(address _beaconContract) public onlyOwner {
        beaconContract = _beaconContract;
    }

    ///@notice Allows admin to add an existing proxy contract to the list of proxy contracts for a user
    ///@param _proxyContract the address of the proxy contract
    ///@param _user the address of the user
    function addProxy(address _proxyContract, address _user) public onlyOwner {
        require(_proxyContract != address(0), "Proxy Contract required");
        require(_user != address(0), "User required");
        proxyContracts[_user].push(_proxyContract);
        proxyContractsUsers.push(_user);
    }

    ///@notice Returns the last proxy contract created (or added) for a specific user
    ///@param _user the address of the user
    ///@return the address of the proxy contract
    function getLastProxy(address _user) public view returns (address) {
        require(_user != address(0), "User required");
        return proxyContracts[_user][proxyContracts[_user].length - 1];
    }
    
    ///@notice Creates a new proxy contract for a specific exchange and pool. 
    ///@dev Proxy contract is owned by calling user
    ///@dev for Solo contracts, only one proxy contract is needed unless custom logic contract is needed
    ///@param _pid the pool id
    ///@param _exchange the name of the exchange
    ///@param _poolType the type of the pool (0=solo, 1=pool)
    ///@return the address of the proxy contract
    function initialize(uint64  _pid, string memory _exchange, uint _poolType) public payable returns (address) {        
        require(beaconContract != address(0), "Beacon Contract required");
        require(bytes(_exchange).length > 0,"Exchange Name cannot be empty");
        string memory _contract = prBeacon(beaconContract).getContractType(_exchange,_poolType);

        address proxy = deploy(_pid);
        proxyContracts[msg.sender].push(address(proxy));
        proxyContractsUsers.push(msg.sender);
        combine_proxy(payable(proxy)).initialize(_contract, beaconContract, msg.sender,_poolType);

        emit NewProxy(address(proxy), msg.sender);

        iApp(address(proxy)).initialize{value:msg.value}(_pid, beaconContract, _exchange,msg.sender);    

        return address(proxy);
    }

    ///@notice Gets bytecode of proxyContract
    ///@return the bytecode of the proxy contract
    function getBytecode() private pure returns (bytes memory) {
        bytes memory result = abi.encodePacked(type(combine_proxy).creationCode);
        return result;
    }

    ///@notice generates an address of a new proxy contract
    ///@dev used in front end
    ///@param _pid the pool id
    ///@return the address of the proxy contract
    function getAddress(uint _pid) public view returns (address)
    {
        bytes32 newsalt = keccak256(abi.encodePacked(_pid,msg.sender));

        bytes memory bytecode = getBytecode();
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), newsalt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }    

    ///@notice deploys bytecode of proxy contract
    ///@param _pid the pool id
    ///@return addr the address of the proxy contract
    function deploy(uint _pid) public payable returns (address addr){
        bytes32 newsalt = keccak256(abi.encodePacked(_pid,msg.sender));
        bytes memory bytecode = getBytecode();

        assembly {
            addr := create2(
                0, 
                add(bytecode, 0x20),
                mload(bytecode),
                newsalt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }    
}
