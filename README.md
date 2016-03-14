# bitcoin-trader
A ruby program that allows for automated and manual buying/selling of BTC based on certain criteria. Uses coinbase API

## Download
Download all of the files in the repo

## Run
Create a driver file (can name it whatever) in the same directory as the downloaded files

Create an instance of BitcoinTrader similar to below

require_relative 'bitcoin_trader'

btc_trader = BitcoinTrader.new(false, S_KEY,S_SECRET,SBOX_URL,EMAIL,PW, TO_EMAIL)

btc_trader.run

Run the file using ruby 'filename'

