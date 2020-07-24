'use strict'

const fs = require('fs')
const yargs = require('yargs')
const Web3 = require('web3')
const keyTh = require('keythereum')
const Tx = require('ethereumjs-tx')
const solc = require('solc')

const url = 'ws://localhost:8546'

yargs.command('$0', 'Deploy FungibleToken', {
  'from': {
    alias: 's',
    default: 0,
    describe: 'Account number that deploys a smart contract'
  },
  'password': {
    alias: 'p',
    default: '1',
    describe: 'Password to unlock the account'
  }
}, async (argv) => {
  // 0. get accounts
  const provider = new Web3.providers.WebsocketProvider(url)
  const web3 = new Web3(provider)

  var accounts = await web3.eth.getAccounts()
  var address = accounts[parseInt(argv['from'])]

  // get a private key from a local file
  var keyObj = keyTh.importFromFile(address, '/root/.ethereum')
  var priKey = keyTh.recover(argv['password'].toString(), keyObj)

  // 1. compile
  const inputs = {
    'SafeMath.sol': fs.readFileSync('./contracts/lib/SafeMath.sol', 'utf8'),
    'FungibleToken.sol': fs.readFileSync('./contracts/FungibleToken.sol', 'utf8')
  }
  const compiledContract = solc.compile({sources: inputs}, 1)
  console.log(compiledContract)
  console.log('> Compiled')

  // 2. deploy
  const abi = compiledContract.contracts['FungibleToken.sol:FungibleToken'].interface
  const bytecode = '0x' + compiledContract.contracts['FungibleToken.sol:FungibleToken'].bytecode

  const contract = new web3.eth.Contract(JSON.parse(abi))
  const params = {
    data: bytecode,
    arguments: [
      'Token', // name
      'SeT', // symbol
      1000 // decimals
    ]
  }
  const txData = contract.deploy(params).encodeABI()
  const nonce = await web3.eth.getTransactionCount(address)
  const rawTx = {
    from: address,
    to: contract.options.address,
    gas: 4700000,
    gasPrice: 0,
    data: txData,
    nonce: nonce,
  }

  const tx = new Tx(rawTx)
	tx.sign(priKey)

  const serializedTx = tx.serialize()
  const res = await web3.eth.sendSignedTransaction('0x' + serializedTx.toString('hex'))
  const outputJson = {
    abi: JSON.parse(abi),
    address: res.contractAddress
  }
  const error = fs.writeFileSync('./build/contract.json', JSON.stringify(outputJson, null, '  '))
  if (error) throw error

  console.log('> Deployed a contract')
  process.exit()
}).help().argv

