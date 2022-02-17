MTN_CODE = "01"
AIRTEL_CODE = "06"
TIGO_CODE = "03"
VODAFONE_CODE = "02"
BANK_CODE = "07"


#LIVE_SERVER = "10.105.85.76"#"184.173.139.74"
# LIVE_SERVER =  "10.70.63.210"#"184.173.139.74"
LIVE_SERVER =  "10.136.77.134"#"184.173.139.74"

# ORCHARD_URL="http://10.136.77.134:8218"

# TEST_SERVER = "10.105.85.76"
# TEST_SERVER = "10.105.85.78"
TEST_SERVER = "10.136.168.7" #curr
# TEST_SERVER = "10.136.77.134"

LIVE_PORT = "8218"
# TEST_PORT = "6029"
# TEST_PORT = "7016"
TEST_PORT = "8300"



#network parameters
MTN_PARAM = "MTN"
TIGO_PARAM = "TIG"
AIRTEL_PARAM = "AIR"
VODA_PARAM = "VOD"
BANK_PARAM = "BNK"

MTN = "MTN"
TIGO = "TIG"
AIRTEL = "AIR"
VODAFONE = "VOD"
BANK = "BNK"

#other constants
DR_REF = "Disb-Debit"
CR_REF = "Disb-Credit"
ATP_REF = "Disb-TopUp"
#type of transaction
DEPOSIT = "Deposit"
WITHDRAWAL = 'Withdrawal'
TRANSFER = 'TRF'
AIRTIME = 'Top Up'
#boolean fields
STATUS = 'status'
SUBSCRIBED = 'subscribed'
CHANGED_STATUS = 'changed_status'
#a hash of all ussd bodies

DISBURSE_ID_PRE = "DSB"

#transaction types
DEBIT = "DR"
CREDIT = "CR"
TOPUP = "TP"
TRFUND = "TR"

#amfp
END_POINT = '/sendRequest'#'/execRequest'

AMFP_URL= 'http://10.136.77.134:7016' # live test
# AMFP_URL= 'http://10.136.168.7:7016'  # test
# AMFP_URL= 'http://10.105.85.76:7016'
# AMFP_URL= 'http://10.136.77.134:8218'

# AMFP_URL = 'http://10.105.85.76:7016'#"https://appsnmobileagent.com:8215/"
# AMFP_URL= 'http://10.136.168.7:7016'#"https://appsnmobileagent.com:8215/"
# AMFP_URL= 'http://10.136.168.7:8300'#"https://appsnmobileagent.com:8215/"
#AMFP_URL = 'https://10.105.85.76:8215'#"https://appsnmobileagent.com:8215/"

REQHDR = {'Content-Type'=>'Application/json','timeout'=>'180'}
REF = "mobile money"

MSGSENDERID = "appsNmob"
AMOUNT = '0.1'
MERCHANT_NUMBER_ANB = '261064828'
MERCHANT_NUM_TIGO = '0271300376'
MERCHANT_NAME = 'APPSNMOBIL'
# CLIENT_KEY = "7fxdP3SdaYC03+JiNx6sybqo2QjlFWX9VQiyhc1nBa5FxJ49TVSQrXyOxz+dnNKCfXLLtNJ7pCdrn+ubFqc9lA==" #"Q7uj60S0gbQL9+K5FPZJI1esSFQNjHBGd/4+1ZiOFuOld6PZxJMUGOyUHCbAS9n0rdSPLWh9qm9HPvtJ1PxnRw=="
# SECRETKEY = "Mbmqr7vOxGHKT1JpHjbU79s9GuDZExozT5DeH0MZTfy/Jx8wzugh5XpwuQm6rLpx5nUhUO2qDWIMh0wN8CQ8pg=="#"/sLQWNhUuha/POPe+Eeor5N+6QQOGPtyWptDKZpI9Zuc+cR8OMh4ayM+o+CGEd6eKosEiLlW3yv/7Mxc9yTFXA=="
# CLIENT_ID = '10'

#t24
# LIVE_SERVER = "localhost"
#T24_URL = "http://67.205.74.208:6035"
T24_URL = "https://#{LIVE_SERVER}:8218"
# T24_URL = "https://#{LIVE_SERVER}:8218"
T24_ENDPOINT = "/Request"

BAL = "BAL"
BTW = "BTW"
WTB = "WTB"

MTP="MTP" #Mobile Top-up
MST="MST" #Mini Statement
FTR="FTR" #Funds transfer (Internal bank transfer)
RVS="RVS"
REVERSAL_FLAG1 = "1"
REVERSAL_FLAG0 = "0"
#mobile money callbacks
#DEBIT_MM_CALLBACK_URL = "http://#{TEST_SERVER}:#{TEST_PORT}/debit_response"
#CREDIT_MM_CALLBACK_URL = "http://#{TEST_SERVER}:#{TEST_PORT}/ds_credit_response"
CREDIT_MM_CALLBACK_URL = "http://#{TEST_SERVER}:#{TEST_PORT}/disburse_callback"

#TOPUP_MM_CALLBACK_URL = "http://#{TEST_SERVER}:#{TEST_PORT}/topup_response"

# WTB_RETURN_URL = "http://#{LIVE_SERVER}:#{LIVE_PORT}/req_wtb"
# BTW_RETURN_URL = "http://#{LIVE_SERVER}:#{LIVE_PORT}/req_btw"
DISBURSE = "Disburse"

# API_KEY = "NZwUeG4g7Bst6JbnQv/BkuAusc2NIhlxWTTOWL0SEq27ARDj/I1/pbjns04iVeDkPKtOuhdEvLDzw99QyhbBlw=="
SMS_END_POINT = "/sendSms"
# BNK_END_POINT = "/sendSms"
#CHECK_BAL_END_POINT = "/check_wallet_balance"
CHECK_BAL_END_POINT = "/portal_wallet_bal_req"

SMS_URL=AMFP_URL
CHECK_BAL_URL=AMFP_URL
#'https://appsnmobileagent.com:8215'
# SMS_URL='https://'

SMS_CONN = Faraday.new(:url=>SMS_URL,:headers=>REQHDR, :ssl => {:verify => false}) do |f|
  f.response :logger
  f.adapter Faraday.default_adapter
end

CHECK_BAL_CONN = Faraday.new(:url=>CHECK_BAL_URL,:headers=>REQHDR, :ssl => {:verify => false}) do |f|
  f.response :logger
  f.adapter Faraday.default_adapter
end

