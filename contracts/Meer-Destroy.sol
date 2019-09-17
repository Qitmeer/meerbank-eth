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

contract MeerDestroy is Owned {
    using SafeMath for uint;
    
    uint256 public symbol;
    address public token;
    mapping(address => BurnList) public burnList;
    
    struct BurnList {
        uint256 amount;
        Redeem[] redeem;
    }
    
    struct Redeem {
        bytes20 meerPKH;
        bytes32 txId;
        uint256 amount;
    }
    
    constructor (address _token ) public {
        symbol = 0;
        token = _token;
    }
    
    event Burn(address burner, uint256 value);
    
    function burn( address _sender, uint256 value ) public onlyOwner( _sender ) {
        require(ERC20(token).transferFrom( _sender, address(this), value), 'transferFrom erro');
        burnList[_sender].amount = burnList[_sender].amount.add(value);
        symbol = symbol.add(value);
        emit Burn( _sender, value);
    }
    
    function fetchMeer( bytes20 _meerPKH ) public {
        require(burnList[msg.sender].amount != 0);
        burnList[msg.sender].redeem.push(
            Redeem(
                _meerPKH,
                0,
                0
            )
        );
    }
    function confirmTxid( address _sender, bytes32 txId, uint index, uint256 meerNum ) public only(owner) {
        require( burnList[_sender].amount > 0 );
        burnList[_sender].redeem[index].txId = txId;
        burnList[_sender].redeem[index].amount = meerNum;
        burnList[_sender].amount = 0;
    }
    
    function confirmBatchTxid( address[] memory _senders, bytes32[] memory txId, uint[] memory index,uint[] memory meerNum  ) public only(owner) {
        for ( uint i =0; i < _senders.length; i++ ) {
            confirmTxid( _senders[i], txId[i], index[i], meerNum[i] );
        }
    }
    
    function getSenderNum( address _sender ) view public returns(uint) {
        return burnList[_sender].redeem.length;
    }
    
    function getSender( address _sender, uint i ) view public returns( bytes20 meerPublickeyHash, bytes32 txId, uint256 amount ) {
        BurnList memory burn = burnList[_sender];
        return ( burn.redeem[i].meerPKH, burn.redeem[i].txId, burn.redeem[i].amount );
    }
}