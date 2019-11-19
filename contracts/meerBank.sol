pragma solidity ^0.5.0;

import './SafeMath.sol';
import './Interfaces.sol';


contract Owned {

    address public owner;
    address newOwner;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }
    
    modifier onlyOwner(address _creditor) {
        require(msg.sender == owner || msg.sender == _creditor);
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


contract MeerBank is Owned {
    
    using SafeMath for uint;
    
    address public token;
    bool public open = false; 
    
    struct Interest {
        address creditor;
        uint256 amount;
        uint256 unlockTime;
        uint256 startTime;
        uint256 profit;
        bytes20 hash160;
    }
    
    struct Amount {
        uint256 amount;
        uint256 unprofit;
        uint256 profit;
    }
    
    mapping( address => Amount ) public amounts;
    
    struct MeerBalance {
        address creditor;
        bytes32 txId;
        uint256 unprofit;
        uint256 profit;
    }
    
    mapping( bytes20 => MeerBalance[] ) public meerBalance;
    
    bytes20[] public meerList;
    
    // 债权人列表
    Interest[] public interest;
    
    // 利息列表
    uint256[2][] public interestList;
    
    // event Redemption(address _creditor, address _token, uint256 _value);
    event Pledge( address creditor, uint256 value, uint256 startTime, uint256 lockTime, uint256 profit, bytes20 hash160 );
    event Settlement( address creditor, uint256 value, uint256 profit);
    event WithdrawMeer( bytes20 meerHash , bytes32 txId , uint256 profit);
    
    constructor ( address _token ) public {
        token = _token;
    }
    
    // 控制开关
    function switchs( bool _open ) public only(owner) {
        open  = _open;
    }
    
    // 设置 利息和天数，利息单位 1%%
    function setInterest( uint256 _days, uint256 _interest  ) public only(owner) returns(uint256) {
        uint256 time =  _days * 1 days;
        for( uint i = 0; i < interestList.length; i++ ) {
            if ( interestList[i][0] == time ) {
                return interestList[i][1] = _interest;
            }
        }
        interestList.push([ time, _interest ]);
        return _interest;
    }
    
    function getInterest( ) view public returns(uint256[2][] memory) {
        return interestList; 
    }
    
    function getInterestByDays( uint256 _days ) view public returns(uint256) {
        uint256 _interest = 0;
        uint256 time =  _days * 1 days;
        for( uint i = 0; i < interestList.length; i++ ) {
            if ( interestList[i][0] == time ) {
                return interestList[i][1];
            }
        }
        return _interest;
    }
    
    // 自助模式
    function pledgeBatchByUser(  uint256 _value, uint256 _days, bytes20 _hash160 ) public {
        require( open == true );
        require( _days != 0 );
        uint256 _yield = getInterestByDays( _days );
        require( _yield != 0 );
        require(ERC20(token).transferFrom( msg.sender, address(this), _value), 'transferFrom erro');
        _yield = _yield.mul(_value).div(10000);
        uint256 _startTime = now;
        uint256 _unlockTime =  _startTime.add(_days * 1 days);
        interest.push(
            Interest(
                msg.sender,
                _value,
                _unlockTime,
                _startTime,
                _yield,
                _hash160
            )
        );
        amounts[msg.sender].amount = amounts[msg.sender].amount.add( _value );
        amounts[msg.sender].unprofit = amounts[msg.sender].unprofit.add( _yield );
        emit Pledge( msg.sender, _value, _startTime, _unlockTime, _yield, _hash160 );
    }
    
    // 代理模式
    function pledgeBatchByOwner( address _creditor,  uint256 _value, uint256 _days, uint256 _interest, bytes20 _hash160  ) public only(owner) {
        require( open == true );
        require(ERC20(token).transferFrom( _creditor, address(this), _value), 'transferFrom erro');
        uint256 _yield = _interest.mul(_value).div(10000);
        uint256 _startTime = now;
        uint256 _unlockTime =  _startTime.add(_days * 1 days);
        interest.push(
            Interest(
                _creditor,
                _value,
                _unlockTime,
                _startTime,
                _yield,
                _hash160
            )
        );
        amounts[_creditor].amount = amounts[_creditor].amount.add( _value );
        amounts[_creditor].unprofit = amounts[_creditor].unprofit.add( _yield );
        emit Pledge( _creditor, _value, _startTime, _unlockTime, _yield, _hash160 );
    }
    
    // 结算 并退还 hlc
    function settlement( uint256 _stopTime ) public only(owner){
        for ( uint i = 0 ; i < interest.length; i++ ) {
            if ( interest[i].profit > 0 && interest[i].unlockTime >= _stopTime && interest[i].unlockTime < _stopTime.add(1 days) ){
                require(ERC20(token).transfer( interest[i].creditor, interest[i].amount), 'transferFrom erro');
                amounts[interest[i].creditor].amount = amounts[interest[i].creditor].amount.sub( interest[i].amount );
                amounts[interest[i].creditor].profit = amounts[interest[i].creditor].profit.add( interest[i].profit );
                amounts[interest[i].creditor].unprofit = amounts[interest[i].creditor].unprofit.sub( interest[i].profit );
                meerList.push( interest[i].hash160 );
                meerBalance[interest[i].hash160].push(
                    MeerBalance(
                        interest[i].creditor,
                        0x0,
                        interest[i].profit,
                        0
                    )
                );
                delete interest[i];
                emit Settlement(interest[i].creditor, interest[i].amount, interest[i].profit);
            }
        }
    }
    
    // 发送meer
    function withdrawMeer( bytes20 _meerHash, bytes32 _txId, uint8 _index ) public only(owner){
        require(meerBalance[_meerHash][_index].unprofit > 0);
        meerBalance[_meerHash][_index].profit = meerBalance[_meerHash][_index].unprofit;
        meerBalance[_meerHash][_index].unprofit = 0;
        meerBalance[_meerHash][_index].txId = _txId;
        amounts[  meerBalance[_meerHash][_index].creditor ].profit = amounts[  meerBalance[_meerHash][_index].creditor ].profit.sub(meerBalance[_meerHash][_index].profit);
        emit WithdrawMeer( _meerHash , _txId , meerBalance[_meerHash][_index].profit);
    }
    
    function withdrawMeers( bytes20[] memory _meerHashs, bytes32[] memory _txIds, uint8[] memory _i) public only(owner){
        for ( uint i = 0 ;i < _meerHashs.length; i++ ) {
            withdrawMeer( _meerHashs[i], _txIds[i], _i[i] );
        }
    }
    
    function getMeerListLength() view public returns(uint256) {
        return meerList.length;
    }
    
    function getMeerBalanceCount( bytes20 _meerHashs  ) view public returns(uint256) {
        return meerBalance[_meerHashs].length;
    }
    
    function interestCount() view public returns(uint256) {
        return interest.length;
    }
    
}