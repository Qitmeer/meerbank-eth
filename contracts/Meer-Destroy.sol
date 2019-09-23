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
        bytes20 redeemPublicHash;
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
    
    event Burn(address indexed burner, uint256 value);
    event FetchMeer(address indexed burner, bytes20 _meerPKH);
    
    function burn( address _sender, uint256 value ) public onlyOwner( _sender ) {
        require(ERC20(token).transferFrom( _sender, address(0), value), 'transferFrom erro');
        burnList[_sender].amount = burnList[_sender].amount.add(value);
        symbol = symbol.add(value);
        emit Burn( _sender, value);
    }
    
    function fetchMeer( bytes20 _meerPKH ) public {
        // require(burnList[msg.sender].redeemPublicHash != 0x0);
        burnList[msg.sender].redeemPublicHash = _meerPKH;
        emit FetchMeer( msg.sender, _meerPKH );
    }
    function confirmTxid( address _sender, bytes32 txId, uint256 meerNum ) public only(owner) {
        BurnList memory burner = burnList[_sender];
        require( burner.amount > 0 );
        require( burner.redeemPublicHash != 0x0 );
        burnList[_sender].redeem.push(
            Redeem(
                burner.redeemPublicHash,
                txId,
                meerNum
            )
        );
        symbol.sub(burner.amount);
        burnList[_sender].amount = 0;
    }
    
    function confirmBatchTxid( address[] memory _senders, bytes32[] memory txId, uint[] memory meerNum  ) public only(owner) {
        for ( uint i =0; i < _senders.length; i++ ) {
            confirmTxid( _senders[i], txId[i], meerNum[i] );
        }
    }
    
    function getSenderNum( address _sender ) view public returns(uint) {
        return burnList[_sender].redeem.length;
    }
    
    function getSender( address _sender, uint i ) view public returns( bytes20 meerPublickeyHash, bytes32 txId, uint256 amount ) {
        BurnList memory burner = burnList[_sender];
        return ( burner.redeem[i].meerPKH, burner.redeem[i].txId, burner.redeem[i].amount );
    }
}