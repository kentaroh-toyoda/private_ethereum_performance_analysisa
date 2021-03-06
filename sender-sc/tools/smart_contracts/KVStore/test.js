'use strict'

const fs = require('fs')
const yargs = require('yargs')
const Web3 = require('web3')
const Tx = require('ethereumjs-tx')
const solc = require('solc')
const keyTh = require('keythereum')
const contractJson = require('../contract.json')
const pMap = require('p-map')

const url = 'ws://localhost:8546'

yargs.command('$0', 'Test KVStore', {
	'from': {
		alias: 's',
		default: 0,
		describe: 'Sender\'s account number'
	},
	'password': {
		alias: 'p',
		default: '1',
		describe: 'Password to unlock the account'
	},
	'numTxs': {
		alias: 'n',
		default: 1000,
		describe: 'Number of contract execution'
	}
}, async (argv) => {
	console.log('> Testing...')
	console.log('#txs:', parseInt(argv['numTxs']))
	const provider = new Web3.providers.WebsocketProvider(url)
	const web3 = new Web3(provider)
	const contract = new web3.eth.Contract(contractJson.abi, contractJson.address)

	// enumerate nonces for transactions
	var maxNonce = parseInt(argv['numTxs'])
	var nonces = Array(maxNonce).fill().map((v, i) => i + 1)
	// NOTE: +1 because nonce should incremented by contract deployment

	// get accounts
	var accounts = await web3.eth.getAccounts()

	// get a private key from a local file
	var fromAddr = accounts[parseInt(argv['from'])]
	var keyObj = keyTh.importFromFile(fromAddr, '/root/.ethereum')
	var priKey = keyTh.recover(argv['password'].toString(), keyObj)

	let set = (nonce) => {
		return new Promise(async resolve => {
			if (nonce <= (maxNonce / 2)) {
				// set
				var txData = contract.methods.set('foo', 'bar').encodeABI()
			} else {
				// get
				var txData = contract.methods.get('foo').encodeABI()
			}
			const txParams = {
				from: fromAddr,
				to: contract.options.address,
				gas: 4700000,
				gasPrice: 0,
				data: txData,
				nonce: nonce,
			}
			const tx = new Tx(txParams)
			tx.sign(priKey)

			const serializedTx = tx.serialize()
			const rawTx = '0x' + serializedTx.toString('hex')

			const method = web3.eth.sendSignedTransaction.method

			method.requestManager.send(method.toPayload([rawTx]), (err, txHash) => {
				if (err) {
					console.log(err)
				} else {
					var d = new Date()
					console.log(formatDate(d) + ' _' + nonce +'_success_' + txHash)
				}
				resolve()
			})
		})
	}

	await pMap(nonces, set, { concurrency: Infinity })

	console.log('> [test.js] Finished')
	process.exit()
}).help().argv

function formatDate(date) {
	var year = date.getFullYear()
	var month = date.getMonth() + 1
	month = month < 10 ? '0' + month : month
	var day = date.getDate()
  var hours = date.getHours()
	hours = hours < 10 ? '0' + hours : hours

  var minutes = date.getMinutes()
	minutes = minutes < 10 ? '0' + minutes : minutes

	var seconds = date.getSeconds()
	seconds = seconds < 10 ? '0' + seconds : seconds
	var ms = date.getMilliseconds()
	ms = ms < 100 ? (ms < 10 ? ms + '00' : ms + '0') : ms

	var datetime = year + '-' + month + '-' + day + ' ' + hours + ':' + minutes + ':' + seconds + '.' + ms

  return datetime
}
