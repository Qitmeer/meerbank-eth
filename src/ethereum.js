const Web3 = require('web3')
const EthereumTx = require('ethereumjs-tx')

const BigNumber = require('bignumber.js')

const MAINNET_PROVIDER = `wss://mainnet.infura.io/ws/v3/22a4704c6cc24b3f93a29c753922b3bc`
const TESTNET_PROVIDER = `wss://ropsten.infura.io/ws/v3/22a4704c6cc24b3f93a29c753922b3bc`
const LOCAL_PROVIDER = `http://localhost:8545`

function setDefineProperty(obj, key, get) {
    Object.defineProperty(obj, key, {
        enumerable: false,
        configurable: false,
        get: () => get
    })
}

class Contract {

    constructor ( web3, ABI, contractAddress ) {
        this.web3 = web3
        this.contractAddress = contractAddress
        this.contract = new web3.eth.Contract( ABI, contractAddress )
        this.accounts = {}
        this.events = this.contract.events
        this.methods = {}
        Object.keys(this.contract.methods).map( key => {
            setDefineProperty(this.methods, key, ( ...arg ) => this._methods(key, ...arg ))
        })
    }

    _methods ( methods, ...arg ) {
        const web3 = this.web3
        const methodsString = this.contract.methods[methods](...arg)
        const _data = methodsString.encodeABI()
        let _value = '0x00'
        const m = {
            call: from => methodsString.call({from}),
            send: async ( address, privateKey, gasLimit ) => {
                if( privateKey === undefined ) throw 'need privateKey'
                const serialize = await this.sign ( { _to: this.contractAddress, _from: address, _value, _data, gasLimit } ,privateKey )
                return new Promise((resolve, reject) => {
                    web3.eth.sendSignedTransaction(serialize, (err, address) => {
                        if ( err !== null ) return reject(err)
                        resolve(address)
                    });
                });
            },
            value: ( num ) => {
                _value = this.web3.utils.toHex(num);
                return {
                    send: m.send
                }
            }
        }
        return m
    }

    async estimateGasPriceWeb3({ speed = 'fast' } = {}) {
        const _multiplier = (() => {
        switch (speed) {
            case 'fast':    return 2
            case 'normal':  return 1
            case 'slow':    return 0.5
            default:      return 1
        }
        })()

        const gasPrice = await new Promise((resolve, reject) =>
            this.web3.eth.getGasPrice((err, gasPrice) => {
                if (err) {
                    reject(err)
                } else {
                    resolve(gasPrice)
                }
            })
        )

        return BigNumber(gasPrice).multipliedBy(_multiplier).toNumber()
    }

    async sign ( { _to, _from, _value, _data, speed, gasLimit } ,privateKey ) {
        const web3 = this.web3
        const t = {to:_to, from:_from, value:_value, data:_data}
        const [
            nonce,
            gaspricr
        ] = await Promise.all([
            web3.eth.getTransactionCount(_from),
            this.estimateGasPriceWeb3({speed})
        ])
        t.gasPrice = web3.utils.toHex(gaspricr);
        t.nonce = web3.utils.toHex( nonce );
        t.gasLimit = web3.utils.toHex('3000000' || gasLimit);
        const tx = new EthereumTx(t);
        tx.sign( Buffer.from(privateKey.substr(2), 'hex') );
        return '0x' + tx.serialize().toString('hex');
    }
}

function creatWeb3( PROVIDER ) {
    PROVIDER = new Web3.providers[`http://localhost:8545` === PROVIDER? 'HttpProvider':'WebsocketProvider']( PROVIDER )
    const web3 = new Web3( PROVIDER )
    return {
        web3,
        Contract( ABI, contractAddress ) {
            return new Contract( web3, ABI, contractAddress )
        }
    }
}

module.exports = {
    mainnet: () => creatWeb3( MAINNET_PROVIDER ),
    testnet: () => creatWeb3( TESTNET_PROVIDER ),
    localnet: () => creatWeb3( LOCAL_PROVIDER )
}
