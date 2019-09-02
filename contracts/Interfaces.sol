pragma solidity ^0.5.0;

contract ERC20 {
    uint public totalSupply;
    uint public decimals;
    function balanceOf(address _owner) public returns (uint);
    function allowance(address _owner, address _spender) public returns (uint);
    function transfer(address _to, uint _value) public returns (bool ok);
    function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
    function approve(address _spender, uint _value) public returns (bool ok);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
