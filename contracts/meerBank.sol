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
        uint256[4] interest;
    }
    
    struct Interest {
        uint256 m1;
        uint256 m3;
        uint256 m6;
        uint256 m9;
        bool open;
        uint256 decimals;
    }
    
    mapping(address => OrderList) public orderList;
    mapping(address => Interest) public interest;
    mapping(address => uint256) public rate;
    
    constructor () public {
        name = 'meererc20';
        symbol = 'tmeer';
        decimals = 8;
    }
    // function 
    event Burned(address burner, uint burnedAmount);

    function burn(uint burnAmount) internal {
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(burnAmount);
        totalSupply = totalSupply.sub(burnAmount);
        emit Burned(burner, burnAmount);
    }
    
    event Pledge(address token, address _creditor, uint256 _value);
    function pledge( address _creditor, uint256 _value, address _token) public onlyOwner( _creditor ) {
        require(orderList[_creditor].balance == 0);
        require(interest[_token].open == true);
        require(ERC20(_token).transferFrom( _creditor, address(this), _value), 'transferFrom erro');
        orderList[_creditor] = OrderList(
            _token,
            now,
            _value,
            [
                interest[_token].m1, 
                interest[_token].m3, 
                interest[_token].m6, 
                interest[_token].m9
            ]
        );
        emit Pledge( _token, _creditor, _value);
    }
    
    event Redemption(address _creditor, address _token, uint256 _value);
    
    function redemption( address _creditor ) public onlyOwner( _creditor ) {
        OrderList memory order = orderList[_creditor];
        require(order.balance > 0, 'balance low');
        settlement( _creditor );
        ERC20(order.token).transfer(_creditor, order.balance);
        delete orderList[_creditor];
        emit Redemption( _creditor, order.token, order.balance);
    }
    
    function settlement( address _creditor ) internal {
        uint256 meer = calculatingInterest( _creditor );
        require( meer > 0);
        totalSupply = totalSupply.add(meer);
        balances[_creditor] = balances[_creditor].add(meer);
    }
    
    
    event LogsNum( string s, uint u);
    function setInterest( address _token, uint256[4] memory inters, bool _open ) public only(owner) {
        interest[_token].m1 = inters[0];
        interest[_token].m3 = inters[1];
        interest[_token].m6 = inters[2];
        interest[_token].m9 = inters[3];
        interest[_token].open = _open;
        interest[_token].decimals = ERC20(_token).decimals();
    }
    
    function calculatingInterest( address _creditor ) view public returns( uint256 ) {
        OrderList memory order = orderList[_creditor];
        Interest memory token = interest[order.token];
        uint256 time = now.sub( order.createdAt );
        uint256 inters = 0;
        
        // if ( time >= 270 days )
        //     inters = order.interest[3];
        // else if ( time >= 180 days ) 
        //     inters = order.interest[2];
        // else if ( time > 90 days ) 
        //     inters = order.interest[1];
        // else if ( time > 30 days ) 
        //     inters = order.interest[0];
        
        // test
        if ( time >= 270 )
            inters = order.interest[3];
        else if ( time >= 180 ) 
            inters = order.interest[2];
        else if ( time > 90 ) 
            inters = order.interest[1];
        else if ( time > 30 ) 
            inters = order.interest[0];
        
        uint256 Meer = order.balance.mul(inters).mul(10**decimals).div(10**token.decimals).div(10000);
        return Meer;
    }
    
    function accountOverview( address _creditor ) view public returns( uint256 ,uint256 token, uint256 Meer,uint256[4] memory interests ) {
        OrderList memory order = orderList[_creditor];
        uint256 time = now.sub( order.createdAt );
        return (time, order.balance , calculatingInterest( _creditor ), order.interest );
    }
    
}