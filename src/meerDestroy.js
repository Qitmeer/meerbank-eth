const Ethereum = require('./ethereum')

const InputDataDecoder = require('ethereum-input-data-decoder')

const BigNumber = require('bignumber.js')

let ETHPRIVATEKEY = Symbol('EthprivateKey')

class meerDestroy {

    constructor({ Abi, contractAddress, network }) {
        if ( Abi === undefined ) {
            throw new Error('EthSwap: tokenAbi required')
        }
        if ( contractAddress === undefined ) {
            throw new Error('EthSwap: contractAddress required')
        }
        const { web3, Contract } = Ethereum[network]()
        this.web3 = web3
        this.contractAddress = contractAddress
        this.contract = Contract( Abi, contractAddress )
    }

    setSender( privateKeyString ) {
        privateKeyString = ('0x' == privateKeyString.substr(0, 2)?'':'0x') + privateKeyString
        const { address, privateKey } = this.web3.eth.accounts.privateKeyToAccount(privateKeyString)
        this[ETHPRIVATEKEY] = privateKey
        this.sender = address
        return this
    }
}

module.exports = meerDestroy
