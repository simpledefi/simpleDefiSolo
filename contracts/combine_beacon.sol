//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract combine_beacon is Ownable {
    struct sFee {
        uint64 current_amount;
        uint64 replacement_amount;
        uint256 start;
    }

    struct sExchange {
        address current_logic_contract;
        address replacement_logic_contract;
        uint256 start;
    }

    mapping (string => mapping(string => sFee)) public mFee;
    mapping (string => sExchange) public mExchanges;

    string[] public Exchanges; 

    constructor() {}

    function getFee(string memory _exchange, string memory _type) public view returns(uint) {
        sFee memory rv = mFee[_exchange][_type];

        if (rv.start != 0 && rv.start < block.timestamp) {
            return rv.replacement_amount;
        }
        return rv.current_amount;
    }

    function setFee(string memory _exchange, string memory _type, uint64 _replacement_amount, uint256 _start) public onlyOwner {
        sFee memory rv = mFee[_exchange][_type];
        
        if (_start < 1209600) {
            _start = block.timestamp + _start;
        }
        
        if (rv.start != 0 && rv.start < block.timestamp) {
            mFee[_exchange][_type].current_amount = mFee[_exchange][_type].replacement_amount;
        }
        
        mFee[_exchange][_type].start = _start;
        mFee[_exchange][_type].replacement_amount = _replacement_amount;
        if (mFee[_exchange][_type].current_amount == 0) {
            mFee[_exchange][_type].current_amount = _replacement_amount;
        }
    }
    
    function getExchange(string memory _exchange) public view returns(address) {
        sExchange memory rv = mExchanges[_exchange];

        if (rv.start != 0 && rv.start < block.timestamp) {
            return rv.replacement_logic_contract;
        }
        return rv.current_logic_contract;
    }

    function setExchange(string memory _exchange, address _replacement_logic_contract, uint256 _start) public onlyOwner {
        sExchange memory rv = mExchanges[_exchange];
        
        if (_start < 1209600) {
            _start = block.timestamp + _start;
        }
        
        if (rv.start != 0 && rv.start < block.timestamp) {
            mExchanges[_exchange].current_logic_contract = mExchanges[_exchange].replacement_logic_contract;
        }
        
        mExchanges[_exchange].start = _start;
        mExchanges[_exchange].replacement_logic_contract = _replacement_logic_contract;
        if (mExchanges[_exchange].current_logic_contract == address(0)) {
            mExchanges[_exchange].current_logic_contract = _replacement_logic_contract;
        }
    }
    
    
    
}

