# bitcoin-trader
A Ruby program that allows for BTC price updates as well as buying/selling of BTC at current market rates or according to user-defined criteria (at certain prices or at percentages of prices). All interaction is via email. Uses coinbase API for BTC transactions

##Dependencies

Coinbase - gem install coinbase

Ruby-Gmail - gem install ruby-gmail

A gmail account set up for the program to use exclusively is needed. The commands will be sent to his account via email from whatever email account you would likero use.

##Commands

The following commands are currently available. They must be used as specified in the email subject line

1. price - gets the current BTC price and emails it back to you
4. alert BTC_PRICE PERCENT- will add an alert to the system so that it will notify you when the price changes by the PERCENT specified (in either direction) from the BTC_PRICE specified
5. order BUY_OR_SELL ABSOLUTE_OR_PERCENT_OR_MARKET TOTAL_BTC_AMOUNT PRICE_THRESHOLD PERCENT_TRESHOLD NUM_DAYS_ORDER_TO_STAY_ACTIVE NUM_OF_ORDERS_TO_FULFILL BTC_AMOUNT_PER_ORDER - this creates an order for BTC. For the most simple command use only the first 4 params. (ex: order buy market .01)

## Download
Download all of the files in the repo to wherever you would like to run them

## Run
Create a driver file (can name it whatever) in the same directory as the downloaded files

Create an instance of BitcoinTrader similar to below

//

require_relative 'bitcoin_trader'

btc_trader = BitcoinTrader.new(MIN_CHECK, ABS_MAX, LIVE_ENV, S_KEY,S_SECRET,SBOX_URL,EMAIL,PW, TO_EMAIL)

btc_trader.run

//

Run the file using ruby 'filename'

Here are the explanations for the criteria above

->MIN_CHECK = int, the number of minutes to sleep in between each run of the main loop of the program
->ABS_MAX = float, the absolute max that should be allowed for any BTC transaction the program will run
->LIVE_ENV = boolean, whether to use the live environment or not
->S_KEY = string, the API key to use for Coinbase
->S_SECRET = string, the API secret to use for Coinbase
->SBOX_URL = string, the Sandbox URL to use for Coinbase
->EMAIL = string, the gmail account username (without @gmail.com) that is checked by the program to receive commands
->PW = string, the password for the above account
->TO_EMAIL = the email address that you will be sending commands and receiving updates to


