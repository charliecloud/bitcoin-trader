# bitcoin-trader
A ruby program that allows for automated and manual buying/selling of BTC based on certain criteria. Allows interaction and commands via email. Uses coinbase API

## Download
Download all of the files in the repo

## Run
Create a driver file (can name it whatever) in the same directory as the downloaded files

Create an instance of BitcoinTrader similar to below

require_relative 'bitcoin_trader'

btc_trader = BitcoinTrader.new(false, S_KEY,S_SECRET,SBOX_URL,EMAIL,PW, TO_EMAIL)

btc_trader.run


###false = whether to use the live environment or not
###S_KEY = the API key to use for Coinbase
###S_SECRET = the API secret to use for Coinbase
###SBOX_URL = the Sandbox URL to use for Coinbase
###EMAIL = the gmail account username (ex:test@gmail.com) that is checked by the program for commands
###PW = the password for the above account
###TO_EMAIL = the email address that you will be sending commands from

Run the file using ruby 'filename'
