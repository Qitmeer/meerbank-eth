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


contract Token is Owned {
    
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function mint(address _to, uint _amount) public only(owner) returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

}


contract MeerBank is Token {
    
    struct OrderList {
        address token;
        uint256 createdAt;
        uint256 balance;
        uint256 interest;
        uint256 cycle;
    }
    
    struct Interest {
        uint256 inter;
        TokenType open;
        uint256 decimals;
        uint256 minAmount;
        uint256 cycle;
    }
    
    enum TokenType { close, open }
    
    mapping(address => OrderList[]) public orderList;
    mapping(address => Interest) public interest;
    
    constructor () public {
        name = 'hlc-interest';
        symbol = 'ihlc';
        decimals = 18;
    }
    
    event Redemption(address _creditor, address _token, uint256 _value);
    event Pledge(address token, address _creditor, uint256 _value);
    
    function pledge( address _creditor, uint256 _value, address _token  ) public onlyOwner( _creditor ) {
        require(interest[_token].open == TokenType.open);
        require(interest[_token].minAmount <= _value);
        require(ERC20(_token).transferFrom( _creditor, address(this), _value), 'transferFrom erro');
        orderList[_creditor].push(
            OrderList(
                _token,
                now,
                _value,
                interest[_token].inter,
                interest[_token].cycle
            )
        );
        emit Pledge( _token, _creditor, _value);
    }
    
    function pledgeBatch( address[] memory _creditor, uint256[] memory _value, address[] memory _token ) public only(owner){
        for ( uint i =0 ;i < _creditor.length; i++ ) {
            pledge( _creditor[i], _value[i], _token[i]  );
        }
    }
    
    function redemption( address _creditor, uint256 _id ) public onlyOwner( _creditor ) {
        OrderList memory order = orderList[_creditor][_id];
        require(order.balance > 0, 'balance low');
        require(now > order.createdAt.add(order.cycle));
        settlement( _creditor, _id );
        ERC20(order.token).transfer(_creditor, order.balance);
        delete orderList[_creditor][_id];
        emit Redemption( _creditor, order.token, order.balance);
    }
    
    function redemptionBatch( address[] memory _creditor, uint256[] memory _id ) public only(owner){
        for ( uint i =0 ;i < _creditor.length; i++ ) {
            redemption( _creditor[i], _id[i]  );
        }
    }
    
    function settlement( address _creditor, uint256 _id ) internal {
        uint256 meer = calculatingInterest( _creditor, _id );
        require( meer > 0);
        totalSupply = totalSupply.add(meer);
        balances[_creditor] = balances[_creditor].add(meer);
    }
    
    
    event LogsNum( string s, uint u);
    function setInterest( address _token, uint256 inters, TokenType _open, uint256 minAmount, uint256 cycle, uint256 _decimals ) public only(owner) {
        interest[_token].inter = inters;
        interest[_token].open = _open;
        interest[_token].decimals = _decimals;
        interest[_token].minAmount = minAmount;
        interest[_token].cycle = cycle;
    }
    
    function calculatingInterest( address _creditor, uint256 _id ) view public returns( uint256 ) {
        OrderList memory order = orderList[_creditor][_id];
        Interest memory token = interest[order.token];
        uint256 inters = 0;
        if ( now > order.createdAt.add(order.cycle))
            inters = order.interest;
        uint256 Meer = order.balance.mul(inters).mul(10**decimals).div(10**token.decimals).div(10000);
        return Meer;
    }
    
    function countOrder( address _creditor ) view public returns(uint256) {
        return orderList[_creditor].length;
    }
}