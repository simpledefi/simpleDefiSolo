//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Storage {
   
    uint64 public poolId;
    uint64 public holdBack;
    uint256 constant MAX_INT = type(uint).max;
    
    address constant WBNB_ADDR = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public logic_contract;
    address internal chefContract;
    address internal routeContract;
    address internal rewardToken;
    address internal feeCollector;
    address public beaconContract;
    
    address public lpContract;
    address public token0;
    address public token1;
    
    bool _locked = false;
    bool _initialized = false;

    string public exchange;

    bytes32 public constant HARVESTER = keccak256("HARVESTER");
}
