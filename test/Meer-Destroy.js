const meerDestroy = require('../src/meerDestroy')
const meerDestroyAbi = require('../src/contractsABI/Meer-Destroy')

const contractAddress = '0x1864f84e43980a77d1d9021dc983d4dc31acbadc'
const network = 'testnet'
const Abi = meerDestroyAbi

const MeerDestroy = new meerDestroy({ Abi, contractAddress, network })

const token = '0x01e899e6bc56aac01760e3aa092129cc0beec25f'
const tokenAbi = require('../src/contractsABI/Token')

const tokenTest = new meerDestroy({ Abi:tokenAbi, contractAddress:token, network })

console.log(
    // MeerDestroy.getPastEvents,
    MeerDestroy.contract.methods.token().call( '0x085467c5dc198252c2112fcb5c178fa91b36cc8d' ).then(function(c){
        console.log(c,'tken')
        MeerDestroy.contract.events.Burn({
            filter: {},
            fromBlock: 0,
            toBlock: 'latest'
         },function(error, event){ console.log(error, event,'ddddddd'); }).on('data', function(event){
            console.log ('daata')
            console.log(event); // same results as the optional callback above
        })
        .on('changed', function(event){
            // remove event from local database
            console.log ('changed')
            console.log(event);
        })
        .on('error', function(err){
            console.log(err,'eer')
        });
    })
    
 )
 



// MeerDestroy.contract.getPastEvents('Burn', {
//     // filter: {myIndexedParam: [20,23], myOtherIndexedParam: '0x123456789...'}, // Using an array means OR: e.g. 20 or 23
//     fromBlock: 0,
//     toBlock: 'latest'
// }, function(error, events){ console.log(events); })
// .then(function(events){
//     console.log(events) // same results as the optional callback above
// })
