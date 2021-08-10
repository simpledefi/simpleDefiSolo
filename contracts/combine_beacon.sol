//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract combine_beacon is Ownable {
    struct sFee {
        uint current_amount;
        uint replacement_amount;
        uint256 start;
    }

    struct sExchange {
        address current_logic_contract;
        address replacement_logic_contract;
        uint256 start;
    }

    struct sDiscount {
        uint discount_amount;
        uint expires;
    }

    mapping (string => mapping(string => sFee)) public mFee;
    mapping (string => sExchange) public mExchanges;
    mapping (address => sDiscount) public mDiscounts;

    bool bitFlip;

    event feeSet(string _exchange, string _function, uint _amount, uint256 _time, uint256 _current);
    event discountSet(address _user, uint _discount, uint _expires);
    event exchangeSet(string  _exchange, address _replacement_logic_contract, uint256 _start);
    
    constructor() {}
    // function getFee(string memory _exchange, string memory _type) public view returns (uint) {
    //     return getFee(_exchange,_type, address(0));
    // }

    function getFee(string memory _exchange, string memory _type, address _user) public view returns (uint) {
        sFee memory rv = mFee[_exchange][_type];
        sDiscount memory disc = mDiscounts[_user];

        uint amount =  (rv.start != 0 && rv.start <= block.timestamp) ? rv.replacement_amount : rv.current_amount;

        if (disc.discount_amount > 0 && (disc.expires <= block.timestamp || disc.expires == 0)) {
            amount = amount - (amount *(disc.discount_amount/100) / (10**18)); 
        }

        return amount;
    }

    function setDiscount(address _user, uint _amount, uint _expires) public onlyOwner {
        require(_amount <= 100 ether,"Cannot exceed 100%");
        mDiscounts[_user].discount_amount = _amount;
        if (_expires > 0 && _expires < 31536000) {
            _expires = block.timestamp + _expires;
        }
        mDiscounts[_user].expires = _expires;

        emit discountSet(_user,_amount,_expires);
    }
    function updateBlock() public { //function used for testing to advance block time
        bitFlip = bitFlip == true ? false : true;
    }
    function setFee(string memory _exchange, string memory _type, uint _replacement_amount, uint256 _start) public onlyOwner {
        sFee memory rv = mFee[_exchange][_type];
        
        if (_start < 1209600) {
            _start = block.timestamp + _start;
        }
        
        if (rv.start != 0 && rv.start < block.timestamp) {
            mFee[_exchange][_type].current_amount = mFee[_exchange][_type].replacement_amount;
        }
        
        mFee[_exchange][_type].start = _start;
        mFee[_exchange][_type].replacement_amount = _replacement_amount;

        if (rv.current_amount == 0) {
            mFee[_exchange][_type].current_amount = _replacement_amount;
        }
        emit feeSet(_exchange,_type,_replacement_amount,_start, block.timestamp);
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
        
        if (rv.start != 0 && rv.start <= block.timestamp) {
            mExchanges[_exchange].current_logic_contract = mExchanges[_exchange].replacement_logic_contract;
        }
        
        mExchanges[_exchange].start = _start;
        mExchanges[_exchange].replacement_logic_contract = _replacement_logic_contract;
        if (mExchanges[_exchange].current_logic_contract == address(0)) {
            mExchanges[_exchange].current_logic_contract = _replacement_logic_contract;
        }
        emit exchangeSet(_exchange, _replacement_logic_contract, _start);
    }
    
    
    
}

