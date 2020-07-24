const yargs = require('yargs')
const Web3 = require('web3')
const keyTh = require('keythereum')
const EthereumTx = require('ethereumjs-tx')
const pMap = require('p-map')
const pThrottle = require('p-throttle')

// connect to the running geth via http or ws
// var url = 'http://localhost:8545'
// var web3 = new Web3(new Web3.providers.HttpProvider(url))
// we use ws
var url = 'ws://localhost:8546'
var web3 = new Web3(new Web3.providers.WebsocketProvider(url))

// take arguments
yargs.command('$0', 'Send ether', {
	'from': {
		alias: 's',
		default: 0,
		describe: 'Sender\'s account number'
	},
	'to': {
		alias: 'r',
		default: 1,
		describe: 'Recipient\'s account number'
	},
	'password': {
		alias: 'p',
		default: '1',
		describe: 'Password to unlock the account'
	},
	'numTxs': {
		alias: 'n',
		default: 1000,
		describe: 'parseInt of transactions totally sent out'
	},
	'maxTPS': {
		alias: 't',
		default: 1000,
		describe: 'Maximum number of transactions per second'
	}
}, async (argv) => {
	// enumerate nonces for transactions
	var nonces = [...Array(parseInt(argv['numTxs'])).keys()]

	// get accounts
	var accounts = await web3.eth.getAccounts()

	// get a private key from a local file
	var keyObj = keyTh.importFromFile(accounts[parseInt(argv['from'])], '/root/.ethereum')
	var priKey = keyTh.recover(argv['password'].toString(), keyObj)

	let sendEther = (nonce) => {
		return new Promise((resolve, reject) => {
			const txParams = {
				nonce: nonce,
				gasLimit: 21000, 
				to: accounts[parseInt(argv['to'])],
				value: '0x1'
			}

			const tx = new EthereumTx(txParams)
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

	// specify TPS
	// sendEther = pThrottle(sendEther, parseInt(argv['maxTPS']), 1000)
	// make the function concurrent
	await pMap(nonces, sendEther, { concurrency: Infinity })

	process.exit()
}).help().argv

function formatDate(date) {
	var year = date.getFullYear()
	var month = date.getMonth() + 1
	month = month < 10 ? '0' + month : month
	var day = date.getDate()
	day = day < 10 ? '0' + day : day

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
