# meerbank-eth
The smart contract of the Qitmeer on the Ethereum network

# Meer-Destroy

The destruction contract is used to permanently lock HLC tokens and record the destruction address. When Meer is online, the corresponding tokens can be returned.

### Contract creation

* symbol : Quantity of token destroyed;
* token : token contract address;

```ts
constructor (address _token ) public {
    symbol = 0;
    token = _token;
}
```

### Burn

* _sender : Destroyed users address;
* value : Destroyed token number , need approve destroy contract number;

```ts
function burn( address _sender, uint256 value ) public onlyOwner( _sender ) {
    require(ERC20(token).transferFrom( _sender, address(this), value), 'transferFrom erro');
    burnList[_sender].amount = burnList[_sender].amount.add(value);
    symbol = symbol.add(value);
    emit Burn( _sender, value);
}
```

### Confirm meer Address

Batch operations can be used confirmBatchTxid.

* _meerPKH: meer publickey hash 160;

```ts
function fetchMeer( bytes20 _meerPKH ) public {
    burnList[msg.sender].redeemPublicHash = _meerPKH;
}
```

### Query the Recycle Address of the User

* getSenderNum: Query Recycle Address number;
* getSender: Query destroyed users meer address;

```ts
function getSenderNum( address _sender ) view public returns(uint) {
    return burnList[_sender].redeem.length;
}

function getSender( address _sender, uint i ) view public returns( bytes20 meerPublickeyHash, bytes32 txId, uint256 amount ) {
    BurnList memory burn = burnList[_sender];
    return ( burn.redeem[i].meerPKH, burn.redeem[i].txId, burn.redeem[i].amount );
}
```

### Upload transaction id

After Main Network Stabilization, After returning the Meer to the user, upload the transaction certificate to the contract.

* _sender: Destroyed users address;
*  txId: meer txid;
* meerNum: Number of meers returned to users;

```ts
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
    burnList[_sender].amount = 0;
}
```

### Test

* network: ropsten;
* test token: [0xD72270bC2656C58b7B9d1Cd9935b1e82adc48aaa](https://ropsten.etherscan.io/address/0xD72270bC2656C58b7B9d1Cd9935b1e82adc48aaa)
* test destroy contract address: [0x36f1e09232d3F5bd4428216761cC18D6FE60F67A](https://ropsten.etherscan.io/address/0x36f1e09232d3F5bd4428216761cC18D6FE60F67A)

### Main

* network: main;
* token: [0x58c69ed6cd6887c0225D1FcCEcC055127843c69b](https://etherscan.io/address/0x58c69ed6cd6887c0225d1fccecc055127843c69b)
* destroy contract address: [0x126720EC10F5aFbf2184146621F183CAE317F573](https://etherscan.io/address/0x126720EC10F5aFbf2184146621F183CAE317F573)


# Meer-Bank

### Test

* network: ropsten;
* test token: [0x84F274225D7Db9DD868AB1D905173Bb7990BCD0f](https://ropsten.etherscan.io/address/0x84F274225D7Db9DD868AB1D905173Bb7990BCD0f)
* test bank contract address: [0xf21F9cff0607590635b45c642B94a266A0CE3bfd](https://ropsten.etherscan.io/address/0xf21F9cff0607590635b45c642B94a266A0CE3bfd)
