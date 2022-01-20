//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./utils/slots.sol";

contract Storage {
    uint64 public holdBack;
    uint256 public lastGas;
    uint256 constant MAX_INT = type(uint).max;
    
    address constant WBNB_ADDR = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public logic_contract;
    address internal chefContract;
    address internal routerContract;
    address internal rewardToken;
    address internal feeCollector;
    address public beaconContract;
    address internal intermediateToken;
    
    bool _locked = false;
    bool _initialized = false;

    bytes32 public constant HARVESTER = keccak256("HARVESTER");

    string public exchange;    
    string public pendingCall;
    //New Variables after this only

    slotsLib.slotStorage[] public slots;
}
