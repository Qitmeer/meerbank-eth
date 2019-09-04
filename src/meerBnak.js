const Ethereum = require('./ethereum')

const InputDataDecoder = require('ethereum-input-data-decoder')

const BigNumber = require('bignumber.js')

let ETHPRIVATEKEY = Symbol('EthprivateKey')

class ERC20 {

  constructor({ tokenAbi, contractAddress, network, decimals }) {
    if ( tokenAbi === undefined ) {
      throw new Error('EthSwap: tokenAbi required')
    }
    if ( contractAddress === undefined ) {
      throw new Error('EthSwap: contractAddress required')
    }
    const { web3, Contract } = Ethereum[network]()
    this.web3 = web3
    this.contractAddress = contractAddress
    this.contract = Contract( tokenAbi, contractAddress )
    this._decimals = decimals
  }

  setSender( privateKeyString ) {
    privateKeyString = ('0x' == privateKeyString.substr(0, 2)?'':'0x') + privateKeyString
    const { address, privateKey } = this.web3.eth.accounts.privateKeyToAccount(privateKeyString)
    this[ETHPRIVATEKEY] = privateKey
    this.sender = address
    return this
  }

  symbol() {
    return this.contract.methods.name().call( this.sender )
  }

  decimals() {
    if ( this._decimals !== undefined ) return this._decimals
    return this.contract.methods.decimals().call( this.sender )
      .then( decimals => {
        this._decimals =  decimals
        return decimals
      })
  }

  numToBigNum( amount ) {
    const decimals = this._decimals
    const exp = BigNumber(10).pow(decimals)
    return BigNumber(amount).times(exp)
  }

  transfer( toAddress, amount ) {
    amount = this.numToBigNum( amount ).toString()
    return this.contract.methods.transfer( toAddress, amount ).send( this.sender, this[ETHPRIVATEKEY] )
  }

  approve( _spender, amount ) {
    amount = this.numToBigNum( amount ).toString()
    return this.contract.methods.approve( _spender, amount ).send( this.sender, this[ETHPRIVATEKEY] )
  }

  allowance( _owner, _spender ) {
    return this.contract.methods.allowance(  _owner, _spender ).call( this.sender )
  }

  balanceOf( address = this.sender ) {
    return this.contract.methods.balanceOf( address ).call( this.sender )
  }
}

class MeerBank extends ERC20 {

    constructor({ network = 'testnet', abi, contractAddress, tokenAbi, decimals } = {}) {
        if ( abi === undefined ) {
            throw new Error('EthSwap: abi required')
        }
        if ( contractAddress === undefined ) {
            throw new Error('EthSwap: "contractAddress" required')
        }
        if ( tokenAbi === undefined ) {
            throw new Error('EthSwap: tokenAbi required')
        }
    }

    super({ tokenAbi, contractAddress, network, decimals })
        this.decoder  = new InputDataDecoder(abi)
    }

    setSender( privateKeyString ) {
        privateKeyString = ('0x' == privateKeyString.substr(0, 2)?'':'0x') + privateKeyString
        const { address, privateKey } = this.web3.eth.accounts.privateKeyToAccount(privateKeyString.toLocaleLowerCase())
        this[ETHPRIVATEKEY] = privateKey
        this.sender = address
        return this
    }

    /**
    * @param {addresss} creditor
    * @param {nubmer} value
    * @param {addresss} token
    * @param {nubmer} cycle [0,1,2]
    * @returns {Promise<any>}
    */
    pledge({creditor, value, token, cycle}) {
        return this.contract.methods.pledge( creditor, value, token, cycle ).send( this.sender, this[ETHPRIVATEKEY] )
    }

    pledge({creditor, value, token, cycle}) {
        return this.contract.methods.pledge( creditor, value, token, cycle ).send( this.sender, this[ETHPRIVATEKEY] )
    }

    /**
    * @param {string} transactionHash
    * @returns {Promise<any>}
    */
    getSecretFromTxhash(transactionHash) {
        return this.web3.eth.getTransaction(transactionHash)
            .then(txResult => {
                try {
                    const bytes32 = this.decoder.decodeData(txResult.input)
                    return this.web3.utils.bytesToHex(bytes32.inputs[0]).split('0x')[1]
                } catch (err) {
                    console.log('Trying to fetch secret from tx: ' + err.message)
                    return
                }
            })
    }
}

module.exports = ERC20Swap
