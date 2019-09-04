# meerbank-eth
The smart contract of the Qitmeer on the Ethereum network

## Description



You can deposit your erc20 tokens in the `meerbank` contract and return the contract to IHLC as interest, provided that your erc20 tokens are configured in the `meerbank` contract.

test addres：[baankContract](https://ropsten.etherscan.io/address/0x9989bb34ad56e631164a1956209257a6509dfb97)

## Contract Interface

### Allocation of tokens

- setInterest

```js
enum TokenType { open, close }
function setInterest( address _token, uint256[3] memory inters, TokenType _open, uint256 minAmount ) public only(owner) {
        interest[_token].inter = inters;
        interest[_token].open = _open;
        interest[_token].decimals = ERC20(_token).decimals();
        interest[_token].minAmount = minAmount;
    }
```

### Pledge coins

- pledge

```js
struct OrderList {
    address token;
    uint256 createdAt;
    uint256 balance;
    uint256 interest;
    uint256 cycle;
}
event Pledge(address token, address _creditor, uint256 _value);
function pledge( address _creditor, uint256 _value, address _token, InterestcCycle _cycle  ) public onlyOwner( _creditor ) {
    require(interest[_token].open == TokenType.open);
    require(interest[_token].minAmount <= _value);
    require(ERC20(_token).transferFrom( _creditor, address(this), _value), 'transferFrom erro');
    orderList[_creditor].push(
        OrderList(
            _token,
            now,
            _value,
            interest[_token].inter[uint256(_cycle)],
            InterestcTime[uint256(_cycle)]
        )
    );
    emit Pledge( _token, _creditor, _value);
}
```

### Redemption of coins

- redemption

```js
 function redemption( address _creditor, uint256 _id ) public onlyOwner( _creditor ) {
    OrderList memory order = orderList[_creditor][_id];
    require(order.balance > 0, 'balance low');
    require(now > order.createdAt.add(order.cycle));
    settlement( _creditor, _id );
    ERC20(order.token).transfer(_creditor, order.balance);
    delete orderList[_creditor][_id];
    emit Redemption( _creditor, order.token, order.balance);
}
```