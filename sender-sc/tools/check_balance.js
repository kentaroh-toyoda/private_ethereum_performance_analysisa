const Web3 = require('web3')

// connect to its own via http or ws
// var url = 'http://localhost:8545'
// var web3 = new Web3(new Web3.providers.HttpProvider(url))
var url = 'ws://localhost:8546'
var web3 = new Web3(new Web3.providers.WebsocketProvider(url))

var nProcessedAccounts = 0

function checkBalance(account, index, array) {
	web3.eth.getBalance(account, function(error, balance) {
		if (error) {
			console.log(error)
		} else {
			console.log('Account ' + index + ':' + balance + ' wei')
			// Since the app doesn't finish automatically, exit with a so unclever way...
			nProcessedAccounts++
			if (nProcessedAccounts === array.length) {
				process.exit()
			}
		}
	})
}

web3.eth.getAccounts((error, accounts) => {
	if (error) {
		console.log(error)
	} else {
		console.log('Account = ')
		console.log(accounts)
		accounts.forEach(checkBalance)
	}
})
