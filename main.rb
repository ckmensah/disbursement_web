puts "HELOOOOOOOOOOOOOOOOOOOOOOOOO"
puts "----------------------------------------------------------------------------"
puts "TESTING 1, 2................................................................."

require 'sinatra'
#set :show_exceptions, false
require 'active_record'
require 'json'
require 'net/http'

require 'faraday'
require_relative 'config/variables'

require_relative 'premium_mobile/models/model'
require_relative 'premium_mobile/controllers/variables'
require_relative 'premium_mobile/controllers/helpers'
require_relative 'premium_mobile/controllers/functions'
require_relative 'premium_mobile/controllers/loyalty_functions'
require_relative 'premium_mobile/controllers/manager'
require_relative 'premium_mobile/controllers/process'

#jara require
require_relative 'jara/controllers/variables'
#require './controllers/helpers'
require_relative 'jara/controllers/functions'
#require './controllers/manager'
require_relative 'jara/controllers/process'
require_relative 'jara/controllers/t24fnx'
#require 'tester_script'
require_relative 'jara/model/j_model'
require_relative 'jara/controllers/fml_functions'

require_relative 'jara/controllers/j_clients_api_functions'

#####################################################################################################
ActiveRecord::Base.configurations['jara'] = {
    :adapter  => 'postgresql',
    :database => $env[:jara_dbname],
    :username => $env[:jara_username],
    :password => $env[:jara_password],
    :host     => $env[:jara_host]
}


ActiveRecord::Base.configurations['premium'] = {
    :adapter  => 'postgresql',
    :database => $env[:premium_dbname],
    :username => $env[:premium_username],
    :password => $env[:premium_password],
    :host     => $env[:premium_host]
}

require_relative 'premium_mobile/models/model'
#####################################################################################################

#require './controllers/helpers'

INTRO = "PREMIUM BANK\n"+
"1. Premium Mobile\n"+
"2. Jara\n"

# before do
#   security_check
# end

post '/' do
    puts "---------------------------------------------------------------------------------------------------"
    puts "Request Received"
    puts "---------------------------------------------------------------------------------------------------"
    
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)

    puts "----------------- PREMIUM MAIN --------------------"
    puts "--------------- IN COMING PAYLOAD------------------"
    puts json_vals

    #sequence=json_vals['SEQUENCE']
    session_id=json_vals['session_id']
    mobile_number=json_vals['msisdn']
    msg_type = json_vals['msg_type']
    ussd_body=json_vals['ussd_body'].strip if json_vals.has_key?('ussd_body')
    #end_session=json_vals['END_OF_SESSION']

    nw_code = json_vals['nw_code']

    service_key=json_vals['service_code']

    puts "THE SERVICE CODE: #{service_key}"

    puts "---------OUTGOING DATA-------------"
    #process(service_key, session_id, mobile_number, ussd_body, nw_code, msg_type) #,custom)
    #puts "-----------------END JARA --------------------"

    #
    # PREMIUM_CONN = Faraday.new(:url => PREMIUM_MOBILE_URL, :ssl => {:verify => false}) do |faraday|
    #     faraday.response :logger                  # log requests to STDOUT
    #     faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    # end
    #
    # JARA_CONN = Faraday.new(:url => JARA_TEST_URL, :ssl => {:verify => false}) do |faraday|
    #     faraday.response :logger                  # log requests to STDOUT
    #     faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    # end

    if BLACK_USSD_BODY.include?(ussd_body) && json_vals['service_code'].blank?
        puts "SESSION ENDED DUE TO BLACKLISTED USSD BODY"
        json_vals['msg_type'] = '2'
        json_vals['ussd_body'] = 'session ended'
        return json_vals.to_json
    end

    #############################################################################################
    #                                                                                           #
    #############################################################################################

    ussd_blocked = GlobalVariable.find_by(param_name: "blocked").param_value.strip

    if ussd_blocked == "yes" and not MAIN_WHITELIST.include? mobile_number
        json_vals['ussd_body'] = "Service is undergoing a brief maintenance activity. Please try again later..."
        json_vals['msg_type'] = '2'
        return json_vals.to_json
    end

    #get premium_obj
    # premium_row = PremiumMain.find_by(session_id: session_id)
    # if nw_code == "02" and premium_row.nil?
    #     PremiumMain.create(
    #         sequence: -1,
    #         mobile_number: mobile_number,
    #         session_id: session_id
    #     )
    #     body = "You need a voucher code in order to make mobile money payment. Please dial *110# and select 6 to generate a voucher code and return here to continue\n"+
    #         "1. Continue\n"+
    #         "2. Cancel"
    #     json_vals['msg_type'] = '1'
    #     json_vals['ussd_body'] = body
    #     return json_vals.to_json
    #
    # elsif nw_code == "02" and premium_row.sequence == -1
    #     if ussd_body == "1"
    #         # do nothing... let code continue
    #         #set msg_type to 0
    #         msg_type = '0'
    #     else
    #         json_vals['msg_type'] = '2'
    #         json_vals['ussd_body'] = 'session ended'
    #         return json_vals.to_json
    #     end
    #
    # end

    if msg_type == '0' #first time

        premium_row = PremiumMain.find_by(session_id: session_id)
        if premium_row.nil?
            PremiumMain.create(
                sequence: 0,
                mobile_number: mobile_number,
                session_id: session_id
            )

        else
            premium_row.update(sequence: 0)
        end



        json_vals['ussd_body'] = INTRO
        json_vals['msg_type'] = '1'
        p json_vals.to_json

    elsif msg_type != '0'
        #premium_row = PremiumMain.find_by(session_id: session_id)
        #premium_row = PremiumMain.find_by_session_id(session_id)

        premium_row = PremiumMain.find_by(session_id: session_id)


        #premium_row [id, premium_jara, sequence, mobile_number, session_id]
        if premium_row.sequence == 0#premium_row[2].to_s == "0" #sequence... string here but integer inside
            premium_row.update(sequence: 1)#premium_row[2] = "1" #let's hope it works



            puts "SEQUENCE = 0 ------------------------------------------------------------------------------------------"
            if ussd_body == '1'
            #means it's premium mobile
            require_relative "premium_mobile/main_app"
            #premium_row[1] = "'t'"
            premium_row.update(premium_or_jara: true)
            #PremiumMain.update_by_session_id(session_id, "premium_or_jara", premium_row[1])

            puts "UPDATES DONE--------------------------------------------------------------------------------------------"
            #move to premium

            #reset msg_type
            # json_vals['msg_type'] = '0'
            msg_type = '0'
            ussd_body = PREMIUM_MOBILE_USSD_BODY

                return premium_process(session_id, mobile_number, msg_type, ussd_body, nw_code, service_key)

            elsif ussd_body == '2'

                #means jara
                require_relative 'jara/main_app'
#require './controllers/manager'
                #premium_row [id, premium_jara, sequence, mobile_number, session_id]
                #premium_row[1] = "'f'"
                premium_row.update(premium_or_jara: false)


                #puts PremiumMain.update_by_session_id(session_id, "premium_or_jara", premium_row[1])
                #premium_row.save

                msg_type = '0'
                ussd_body = JARA_USSD_BODY
                return jara_process(service_key, session_id, mobile_number, ussd_body, nw_code, msg_type)

            else
                json_vals['ussd_body'] = 'Wrong option selected.'
                json_vals['msg_type'] = '2'
                puts "WRONG OPTION SELECTED ON FIRST PAGE OF 446"
                return json_vals.to_json
            end
            #premium_row [id, premium_jara, sequence, mobile_number, session_id]

        elsif premium_row.sequence == 1#premium_row[2].to_s == "1" #sequence
            if premium_row.premium_or_jara#premium_row[1] == "t" #if premium
                require_relative "premium_mobile/main_app"
                return premium_process(session_id, mobile_number, msg_type, ussd_body, nw_code, service_key)
            elsif not premium_row.premium_or_jara
                require_relative "jara/main_app"
                #call jara
                return jara_process(service_key, session_id, mobile_number, ussd_body, nw_code, msg_type)
            end
        end
    end
end

get '/' do
    require_relative 'premium_mobile/main_app'

    # puts "---------------------------------------------------------------------------------------------------"
    # puts "Request Received"
    # puts "---------------------------------------------------------------------------------------------------"
    #
    # request.body.rewind
    # json_payload = request.body.read
    # json_vals = JSON.parse(json_payload)

    puts "----------------- REVERSAL TEST PREMIUM --------------------"
    puts "--------------- IN COMING PAYLOAD------------------"
    #j_handle_reversal(payload, auto=true, table=BankTransaction, table2=TransactionReprocess)
    # params = {
    #     account_no: '0120332000018',
    #     exttrxnid: 'PM1702230917685',
    #     return_url: BTW_RETURN_URL,
    #     amount: '0.5',
    #     wallet_nw: 'MTN',
    #     req_type: MTP,
    #     mobile_no: '233247915505',
    #     mobile_nw: '01'
    # }
    #
    # j_handle_reversal(params)
#     mobile_number = '233247915505'
#     amt = '0.5'
#
#
# code = genUniqueID
#     params = {
#         account_no: '0120332000018',
#         exttrxnid: code,
#         return_url: BTW_RETURN_URL,
#         amount: '0.5',
#         wallet_nw: 'MTN',
#         req_type: MTP,
#         mobile_no: '233247915505',
#         mobile_nw: '01'
#     }

#     puts "---------------------------------------------------------------"
#     puts "---------------------------------------------------------------"
#     p "---------------- STARTED TESTING TOP UP --------------------------"
#     puts "---------------------------------------------------------------"
#     puts "---------------------------------------------------------------"
#
#     response = exec_t24_request(params)
#
#     puts "---------------------------------------------------------------"
#     puts "---------------------------------------------------------------"
#     p "---------------- FINISHED TESTING TOP UP --------------------------"
#     puts "RESPONSE: #{response.inspect}"
#     puts "---------------------------------------------------------------"
#     puts "---------------------------------------------------------------"
#


    # if response['error_code']
    #     newMobilePayment(MERCHANT_NUMBER_ANB, mobile_number, amt, "01", TOPUP_MM_CALLBACK_URL, CLIENT_ID, transaction, TOPUP, trans_ref)
    #
    # else
    #     params2 = {
    #         account_no: '0120332000018',
    #         exttrxnid: code,
    #         return_url: BTW_RETURN_URL,
    #         amount: '0.5',
    #         wallet_nw: 'MTN',
    #         req_type: MTP,
    #         mobile_no: '233247915505',
    #         mobile_nw: '01'
    #     }


# puts "---------------------------------------------------------------"
# puts "---------------------------------------------------------------"
# p "---------------- STARTED TESTING REVERSAL FOR TOP UP-----------------"
# puts "---------------------------------------------------------------"
# puts "---------------------------------------------------------------"

    trans_id = 'PM1702231628709'
    # trans_id2 = 'PM1702230917685'

    # params2 = {
    #             account_no: '0120332000018',
    #             exttrxnid: trans_id,
    #             return_url: BTW_RETURN_URL,
    #             amount: '0.5',
    #             wallet_nw: 'MTN',
    #             req_type: MTP,
    #             mobile_no: '233247915505',
    #             mobile_nw: '01'
    #         }



  account_no = '0112584000018'
    #
    # params = {
    #     account_no: account_no,
    #     exttrxnid: trans_id,
    #     return_url: BTW_RETURN_URL,
    #     amount: '0.5',
    #     wallet_nw: 'MTN',
    #     req_type: MTP,
    #     mobile_no: '233247915505',
    #     mobile_nw: '01',
    #     reversal: REVERSAL_FLAG1
    # }

    params = {
        account_no: account_no,
        exttrxnid: genUniqueID,
        return_url: WTB_RETURN_URL,
        # amount: amt,
        wallet_nw: '06',
        req_type: BAL
    }
    #payload[:reversal] = REVERSAL_FLAG1

        response = exec_t24_request(params)

        puts "#############################################################################################################"
        puts "---------------------------------------------------------------"
        puts "---------------------------------------------------------------"
        p "---------------- FINISHED TESTING TOP UP--------------------------"
        puts "RESPONSE: #{response.inspect}----------------------------------"
        puts "---------------------------------------------------------------"
        puts "---------------------------------------------------------------"
        puts "#############################################################################################################"

        response.to_json
    # end
     # "hello world"
    # puts json_vals



end


get '/test' do

    'hello world'
end




INVALID_TOKEN = '2001'
INVALID_MOBILE_NUMBER = '2002'
RECORD_NOT_FOUND = '2003'
TOKENS_EXPIRED = '2004'
TOKENS_REDEEMED = '2005'
TOKENS_BLOCKED = '2006'
TOKENS_NOT_REDEEMED = '2007'
SUCCESS_CODE = '2000'
INVALID_KEYS = '2009'



post '/verifySender' do
    request.body.rewind
    req = JSON.parse request.body.read

    CardlessLog.create(
        url: request.url,
        data: req.to_s,
        end_point: 'verifySender'
    )

    unless req.has_key?('recipient_token') || req.has_key?('recipient_number') || req.has_key?('sender_token')
        return {status: false, resp_code: INVALID_KEYS,response_desc: "Invalid keys. Expected keys are 'recipient_number', 'recipient_token' and 'sender_token'"}.to_json
    end

    # {recipient_number: "", recipient_token: "", sender_token: ""}

    p "-----------------PREMIUM MOBILE CARDLESS SENDER VERIFIER----------------------"

    recipient_number_init = req['recipient_number'].strip

    recipient_number_formatted = phone_formatter(recipient_number_init) #change format to 233xxxxxxxx
    recipient_number = recipient_number_formatted[3..recipient_number_formatted.size]
    recipient_token = req['recipient_token'].strip

    sender_token = req['sender_token'].strip

    #test incoming data
    db_sender_token = CardlessAtm.where(sender_token: sender_token, changed_status: false)[0]
    db_recipient_token = CardlessAtm.where(recipient_token: recipient_token, changed_status: false)[0]
    db_recipient_number = CardlessRequest.where("recipient_number LIKE ? AND changed_status = false", "%#{recipient_number}%")[0]

    unless db_recipient_token and db_sender_token
        return {status: false, resp_code: INVALID_TOKEN, response_desc: "Invalid Token"}.to_json
    end

    unless db_recipient_number
        return {status: false, resp_code: INVALID_MOBILE_NUMBER, response_desc: "Invalid mobile number"}.to_json
    end


    record = CardlessAtm.joiner.where("cardless_requests.recipient_number LIKE ?
AND cardless_atms.recipient_token = ?
AND cardless_atms.sender_token = ?
AND cardless_requests.changed_status = false","%#{recipient_number}%", recipient_token, sender_token).order('cardless_atms.id desc')[0]


    response = Hash.new

    if record #if it exists
      if record.expired
          response['recipient_number'] = recipient_number_formatted
          # response['recipient_token'] = record.recipient_token
          response['cardless_trans_id'] = record.request_code
          response['sender_token'] = record.sender_token
          response['amount'] = record.amount
          response['status'] = false
          response['resp_code'] = TOKENS_EXPIRED
          response['response_desc'] = "Transaction has expired"
      elsif record.redeemed
          response['recipient_number'] = recipient_number_formatted
          # response['recipient_token'] = record.recipient_token
          response['cardless_trans_id'] = record.request_code
          response['sender_token'] = record.sender_token
          response['amount'] = record.amount
          response['status'] = false
          response['resp_code'] = TOKENS_REDEEMED
          response['response_desc'] = "Transaction has already been redeemed"

      elsif record.blocked
          response['recipient_number'] = recipient_number_formatted
          # response['recipient_token'] = record.recipient_token
          response['cardless_trans_id'] = record.request_code
          response['sender_token'] = record.sender_token
          response['amount'] = record.amount
          response['status'] = false
          response['resp_code'] = TOKENS_BLOCKED
          response['response_desc'] = "Transaction has been blocked"
      else
          response = Hash.new
          response['recipient_number'] = recipient_number_formatted
          # response['recipient_token'] = record.recipient_token
          response['cardless_trans_id'] = record.request_code
          response['sender_token'] = record.sender_token
          response['amount'] = record.amount
          response['status'] = true
          response['resp_code'] = SUCCESS_CODE
          response['response_desc'] = "Success"
      end
        return response.to_json
    else
        {status: false, resp_code: RECORD_NOT_FOUND,response_desc: 'Record Not Found'}.to_json
    end
end

post '/verifyRecipient' do
    request.body.rewind

    req = JSON.parse request.body.read

    CardlessLog.create(
        url: request.url,
        data: req.to_s,
        end_point: 'verifyRecipient'
    )

    unless req.has_key?('recipient_token') || req.has_key?('recipient_number')
      return {status: false, resp_code: INVALID_KEYS, response_desc: "Invalid keys. Expected keys are 'recipient_number' and 'recipient_token'"}.to_json
    end

    recipient_number_init = req['recipient_number'].strip

    recipient_number_formatted = phone_formatter(recipient_number_init) #change format to 233xxxxxxxx
    recipient_number = recipient_number_formatted[3..recipient_number_formatted.size]

    recipient_token = req['recipient_token'].strip

    check_recipient_token = CardlessAtm.where(recipient_token: recipient_token, changed_status: false)


    check_number = CardlessRequest.where("recipient_number LIKE ? and changed_status = false", "%#{recipient_number}%")

    unless check_number.size > 0
        return {status: false, resp_code: INVALID_MOBILE_NUMBER, response_desc: "Invalid mobile number"}.to_json
    end

    #continue if number exists

    unless check_recipient_token.size > 0
        return {status: false, resp_code: INVALID_TOKEN, response_desc: "Invalid Token"}.to_json
    end




    record = CardlessAtm.joiner.where("cardless_requests.recipient_number LIKE ?
AND cardless_atms.recipient_token = ?
AND cardless_requests.changed_status = false","%#{recipient_number}%", recipient_token).order('cardless_atms.id desc')[0]



    p "-----------------PREMIUM MOBILE CARDLESS RECIPIENT VERIFIER----------------------"
    if record
        response = Hash.new
        response['recipient_number'] = recipient_number_formatted
        response['recipient_token'] = record.recipient_token
        response['status'] = true
        response['resp_code'] = SUCCESS_CODE
        response['cardless_trans_id'] = record.request_code

        return response.to_json
    else
      {status: false, resp_code: RECORD_NOT_FOUND, response_desc: 'Record Not Found'}.to_json
    end

end


post '/resetTokens' do
    request.body.rewind
    req = JSON.parse request.body.read

    request_code = req['cardless_trans_id'].strip

    main_record = CardlessRequest.find_by(request_code: request_code, changed_status: false)

    record = CardlessAtm.where(cardless_req_code: request_code, changed_status: false).order('created_at desc')[0]

    response = Hash.new
    if record
      main_record.redeemed = false
      main_record.save

      record.atm_redeemed = false
      record.save

      response['status'] = true
      response['resp_code'] = SUCCESS_CODE
      response['response_desc'] = "Success"
    else
        response['status'] = false
        response['resp_code'] = RECORD_NOT_FOUND
        response['response_desc'] = "Record not found"
    end

    return response.to_json
end

post '/setDispenseStatus' do

    request.body.rewind
    req = JSON.parse request.body.read

    CardlessLog.create(
        url: request.url,
        data: req.to_s,
        end_point: 'setDispenseStatus'
    )

    request_code = req['cardless_trans_id'].strip

    main_record = CardlessRequest.find_by(request_code: request_code, changed_status: false)

    record = CardlessAtm.where(cardless_req_code: request_code, changed_status: false).order('created_at desc')[0]
    response = Hash.new
    if record
      if record.atm_redeemed
        response['status'] = false
        response['resp_code'] = TOKENS_REDEEMED
        response['response_desc'] = "Transaction has been redeemed already"
      elsif record.atm_expired
          response['status'] = false
          response['resp_code'] = TOKENS_EXPIRED
          response['response_desc'] = "Transaction has expired"
      elsif record.atm_blocked
          response['status'] = false
          response['resp_code'] = TOKENS_BLOCKED
          response['response_desc'] = "Transaction has been blocked"
      else

        main_record.redeemed = true
        main_record.save
        #cardless_atm = CardlessAtm.where(cardless_req_code: request_code, changed_status: false).order('created_at desc')[0]
        #cardless_atm.delete_status = true
        record.atm_redeemed = true
        record.save

        CardlessReversal.create(
            cardless_trans_id: request_code,
            cardless_atms_id: record.id,
            cardless_trans_type: "W",
            reversal_status: true

        )

        response['status'] = true
        response['resp_code'] = SUCCESS_CODE
        response['response_desc'] = "Success"

      end

      response.to_json
    else
      {status: false, resp_code: RECORD_NOT_FOUND,response_desc: "Record not found"}.to_json
    end
end

post '/dispenseReversal' do
    request.body.rewind
    req = JSON.parse request.body.read

    CardlessLog.create(
        url: request.url,
        data: req.to_s,
        end_point: 'dispenseReversal'
    )

    request_code = req['cardless_trans_id'].strip

    main_record = CardlessRequest.find_by(request_code: request_code, changed_status: false)
    record = CardlessAtm.where(cardless_req_code: request_code, changed_status: false).order('created_at desc')[0]


    response = Hash.new
    if record
      if not record.atm_redeemed
        response['status'] = false
        response['resp_code'] = TOKENS_NOT_REDEEMED
        response['response_desc'] = "Token not redeemed"
      elsif record.atm_expired
          response['status'] = false
          response['resp_code'] = TOKENS_EXPIRED
          response['response_desc'] = "Transaction has expired"
      elsif record.atm_blocked
          response['status'] = false
          response['resp_code'] = TOKENS_BLOCKED
          response['response_desc'] = "Transaction has been blocked"
      else

        main_record.redeemed = false
        main_record.save

        # cardless_atm.delete_status = false
        record.atm_redeemed = false
        record.save

        CardlessReversal.create(
            cardless_trans_id: request_code,
            cardless_atms_id: record.id,
            cardless_trans_type: "R",
                reversal_status: true
        )

        response['status'] = true
        response['resp_code'] = SUCCESS_CODE
        response['response_desc'] = "Success"
      end

      response.to_json
    else
        {status: false, resp_code: RECORD_NOT_FOUND,response_desc: "Record not found"}.to_json
    end
end



#CALL BACKS FROM PREMIUM
###################################################################################################
###################################################################################################
post '/pm_debit_response' do

    request.body.rewind
    req = JSON.parse request.body.read
    #
    # File.open('callback.log','a+') do |file|
    #     file.write(req.inspect)
    #     file.write("\n\n\n\n-------------------------------------------END-------------------------------------------")
    #     file.close
    # end

    p "-----------------PREMIUM MOBILE MONEY DEBIT CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"

    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"].to_s
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    amfp_resp = _trans_status[0]
    nw_resp = _trans_status[1]
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    puts "CURRENT DATABASE: #{SentCallback.connection.current_database}"
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    puts "--------------------------------------------------------------------------------"
    sent_object = SentCallback.where("trnx_id=?", trans_ref.to_s).first

    #customer = Subscription.find_by(mobile_number: sent_object.mobile_number, subscribed: true, changed_status: false)
    mobile_number = sent_object.mobile_number
    amt = sent_object.amount
    nw = sent_object.network


    #transaction = BankTransaction.find_by(transaction_ref_id: trans_ref)



    #log mobile money
    params = Hash.new
    params['merchant_number'] = MERCHANT_NUMBER_ANB #has to change
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = nw_resp
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref

    pm_log_mobile_money(params)

    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = nw
    pm_log_callback_resp(parameters)

    #send txt message

    transaction = BankTransaction.where(transaction_ref_id: trans_ref.to_s).first

    unless transaction.err_code.nil? #prevent multiple callbacks
        return #break everything
    end
    #transaction.trans_step = AM_WALLET_DR_COMPLETED # error
    #first part is complete
    transaction.nw_resp = message
    transaction.save
    transaction.status = 1
    transaction.err_code = amfp_resp
    transaction.save

    if amfp_resp == '000'

        #update transaction transaction


        #if customer
        acctno = transaction.account_number
        #send money to account
        nw_code = get_nw_code(nw)

        params = {
            account_no: acctno,
            exttrxnid: trans_ref,
            return_url: WTB_RETURN_URL,
            amount: amt,
            wallet_nw: nw_code,
            req_type: WTB
        }

        #set status2 = 0 before sending request
        transaction.status2 = 0
        transaction.save

        puts "VVVV T24 HASH RESPONSE BELOW VVVV"
        puts
        puts arrResp = exec_t24_request(params)
        puts
        puts

        #successful transfer

        #{"trans_type":"0210","proc_code":"201040","trans_ref":"1612090839978","account_no":"0120332000018","trxn_amt":"0.1","remote_ref":"FT1624678264","balance":"12.94","error_code":"00"}

        if arrResp # && mobile_number  != "233247915505"#just for testing...
            puts "RESPONSE DESCRIPTION: #{arrResp['error_desc']}"
            #desc = arrResp['resp_desc']
            transaction.status2 = 1
            transaction.err_code2 = arrResp['error_code']
            transaction.balance = arrResp['balance']
            transaction.bank_resp = arrResp['error_desc']
            transaction.remote_ref_id = arrResp['remote_ref']
            transaction.save

            if arrResp['error_code'] == '00'
                transaction.final_status = true
                transaction.save


                # {
                #     DEFAULT_SRC => ["MSG_SENDER_ID","MSG"],
                #     LOY_SRC => ["MSG_SENDER_ID","MSG"]
                # }

                #default sms
                txtmsg_default="You have deposited GHS #{amt} to acct. no. #{account_no_formatter(acctno)} successfully. Available balance is #{arrResp['currency']} #{arrResp['balance']}. Transaction ID: #{arrResp['trans_ref']}"
                #client's of pb sms
                client = PremiumClient.where(src: transaction.src).active.last
                txtmsg_loyalty= client.nil? ? "" : "You have deposited GHS #{amt} to #{client.company_name}'s account successfully. Transaction ID: #{arrResp['trans_ref']}"

                #bundle them up
                txt_hash = {
                    DEFAULT_SRC => [MSGSENDERID, txtmsg_default],
                    LOY_SRC => [LOY_SENDER_ID, txtmsg_loyalty]
                }

                sendmsg_conditional(mobile_number,txt_hash,transaction.src)

                # if transaction.src == DEFAULT_SRC
                #     txtmsg="You have deposited GHS #{amt} to acct. no. #{account_no_formatter(acctno)} successfully. Available balance is #{arrResp['currency']} #{arrResp['balance']}. Transaction ID: #{arrResp['trans_ref']}"
                #     sendmsg(MSGSENDERID, mobile_number, txtmsg)
                #
                # else
                #   client = PremiumClient.where(src: transaction.src).active.last
                #   if client
                #       txtmsg="You have deposited GHS #{amt} to #{client.company_name}'s account successfully. Transaction ID: #{arrResp['trans_ref']}"
                #       sendmsg(MSGSENDERID, mobile_number, txtmsg)
                #   end
                # end



            else
                txtmsg="Your deposit failed due to: #{arrResp['error_desc']}. Transaction ID: #{trans_ref}" #change on live
                sendmsg(MSGSENDERID, mobile_number, txtmsg) #if transaction.src == DEFAULT_SRC
                handle_amfp_reversal2(mobile_number, amt, nw_code, transaction, trans_ref)
            end

            # Response: {"resp_code":"041","resp_desc":"Invalid bank account number provided"} OF TYPE: String
        else



            if transaction.src == DEFAULT_SRC
                txtmsg="Your deposit was unsuccessful. Your bank account will be credited manually within 24 hours. Transaction ID: #{arrResp['trans_ref']}"
                sendmsg(MSGSENDERID, mobile_number, txtmsg) #

            else
                txtmsg="Your deposit was unsuccessful. Your account will be credited manually within 24 hours. Transaction ID: #{arrResp['trans_ref']}"
                sendmsg(MSGSENDERID, mobile_number, txtmsg) #
            end

            transaction.status2 = nil
            transaction.save

            handle_amfp_reversal2(mobile_number, amt, nw_code, transaction, trans_ref)
        end


        # else
        #     #person hasn't fully registered... use pending
        #     PendingDeposit.create(
        #         phone_number: mobile_number,
        #         trnx_id: trans_ref,
        #         amount: amt,
        #         status: 1,
        #         network: nw
        #
        #     )
        #
        #     txtmsg="Your have deposited GHS #{amt} is pending. It will be available once your account creation is complete"
        #     sendmsg(J_MSGSENDERID, mobile_number, txtmsg)
        # end



    else
        txtmsg="Your deposit of GHS #{amt} was unsuccessful"
        sendmsg(MSGSENDERID, mobile_number, txtmsg) if transaction.src == DEFAULT_SRC
    end
    #LOYALTY DEPOSIT
    if transaction.src == LOY_SRC
      loy_hash = Hash.new
      amfp_resp == '000' ? loy_hash['debit_status'] = 'Success' : 'Failure'
      transaction.err_code2 == T24_SUCCESS ? loy_hash['credit_status'] = 'Success' : 'Failure'
      transaction.final_status ? loy_hash['status'] = 'Success' : 'Failure'
      push_loyalty_callback(loy_hash) #push callback
    end
end



post '/pm_credit_response' do

    request.body.rewind
    req = JSON.parse request.body.read
    #
    # File.open('callback.log','a+') do |file|
    #     file.write(req.inspect)
    #     file.write("\n\n\n\n-------------------------------------------END-------------------------------------------")
    #     file.close
    # end

    p "-----------------PREMIUM MOBILE MONEY CREDIT CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"

    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"].to_s
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    amfp_resp = _trans_status[0]
    nw_resp = _trans_status[1]

    sent_object = SentCallback.where(trnx_id: trans_ref).first

    #customer = Subscription.find_by(mobile_number: sent_object.mobile_number, subscribed: true, changed_status: false)
    mobile_number = sent_object.mobile_number
    amt = sent_object.amount
    nw = sent_object.network

    #if it's not a reversal... do this
    # if sent_object.is_reversal
    #     puts "in if object.is_reversal"
    #     puts "sent object is_reversal = #{sent_object.is_reversal}"
    #     reprocess = TransactionReprocess.where(new_trnx_id: sent_object.trnx_id).first
    #     reprocess.status2 = true
    #     reprocess.err_code2 = amfp_resp
    #     reprocess.nw_resp_desc = nw_resp
    #     transaction = BankTransaction.where(transaction_ref_id: reprocess.old_trnx_id).first
    # else
    puts "in else object.is_reversal"
    puts "sent object is_reversal = #{sent_object.is_reversal}"
    if sent_object.is_reversal
        reprocessed_transaction = TransactionReprocess.where(new_trnx_id: trans_ref).order('id desc').first

        #check against multiple callbacks
        unless reprocessed_transaction.nw_resp.nil?
            return #cut the whole thing
        end

        old_trnx_id = reprocessed_transaction.old_trnx_id
        transaction = BankTransaction.where(transaction_ref_id: old_trnx_id).order('id desc').first
        puts "TRANSACTION REPROCESS: #{reprocessed_transaction.inspect}"
        puts "TRANSACTION: #{transaction.inspect}"
    else
        transaction = BankTransaction.where(transaction_ref_id: trans_ref).first

        #check against multiple callbacks
        unless transaction.nw_resp.nil?
            return #cut the whole thing
        end

        transaction.nw_resp = message
        transaction.status2 = true
        puts "STATUS2: #{transaction.status2}"
        transaction.err_code2 = amfp_resp
        transaction.save
    end
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts
    # puts "TRANSACTION OBJECT AFTER SAVING STATUS2: #{transaction.inspect} on line 282"
    # puts
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # end

    #transaction = BankTransaction.find_by(transaction_ref_id: trans_ref)


    #log mobile money
    params = Hash.new
    params['merchant_number'] = MERCHANT_NUMBER_ANB #has to change
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = nw_resp
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref

    pm_log_mobile_money(params)

    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = nw
    pm_log_callback_resp(parameters)

    #send txt message


    acctno = transaction.account_number
    if amfp_resp == '000'
        #set to one only when successful
        transaction.status2 = true

        if sent_object.is_reversal #if it's reversal...
          reprocessed_transaction.final_status = true
          reprocessed_transaction.save
            transaction.is_reversal = true
            transaction.save
            txtmsg = "Your funds has been sent to your wallet successfully. Amount: GHS #{amt}\n
Acct. No.: #{account_no_formatter(acctno)}\nTransaction ID: #{trans_ref}\nOld Trans ID: #{old_trnx_id}"
            sendmsg(MSGSENDERID, mobile_number, txtmsg)

        elsif transaction.trans_type == BILL_PAY
          #bill payment
            transaction.final_status = true
            transaction.save
            txtmsg = "Your #{transaction.bill_type} bill payment of GHS #{amt} from #{account_no_formatter(acctno)} was successful. Balance is #{transaction.balance}, Transaction ID: #{transaction.transaction_ref_id}"
            sendmsg(MSGSENDERID, mobile_number, txtmsg) if transaction.src == DEFAULT_SRC

        else
            transaction.final_status = true
            transaction.save


            #check for second number (that's if it's third party)
            if transaction.mobile_number2
                #the above message was sent to this number, so send message to the sender (mobile_number)
                if nw == MTN_PARAM
                    network = "MTN"
                elsif nw == AIRTEL_PARAM
                    network = "Airtel"
                elsif nw == VODA_PARAM
                    network = "Vodafone"
                elsif nw == TIGO_PARAM
                    network = "Tigo"
                else
                    network = ""
                end

                txtmsg = "Your transfer of GHS #{amt} from #{account_no_formatter(acctno)} to the #{network} number #{mobile_number} was successful. Balance is #{transaction.balance}, Transaction ID: #{transaction.transaction_ref_id}"
                sendmsg(MSGSENDERID, transaction.mobile_number, txtmsg) if transaction.src == DEFAULT_SRC

                customer = get_subscriber(transaction.mobile_number) #here

                txtmsg2 = "You have successfully received GHS #{amt} from #{customer.firstname} #{customer.lastname}. Phone Number:  #{transaction.mobile_number}. Transaction ID: #{trans_ref}"
                sendmsg(MSGSENDERID, transaction.mobile_number2,txtmsg2) if transaction.src == DEFAULT_SRC
            else
                txtmsg_client = ""
                txtmsg_default = ""
                #loyalty
                if transaction.subscription.is_client
                    client_code = transaction.subscription.client_code
                    client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('created_at desc')[0]
                    txtmsg_client = "You have successfully received GHS #{amt} from #{client.company_name}. Transaction ID: #{trans_ref}"
                    # sendmsg(MSGSENDERID, mobile_number, txtmsg)
                else
                    txtmsg_default = "Your withdrawal of GHS #{amt} from #{account_no_formatter(acctno)} was successful. Balance is #{transaction.balance}, Transaction ID: #{transaction.transaction_ref_id}"
                end

                txt_hash = {
                    DEFAULT_SRC => [MSGSENDERID, txtmsg_default],
                    LOY_SRC => [LOY_SENDER_ID, txtmsg_client]
                }

                sendmsg_conditional(mobile_number,txt_hash,transaction.src)
            end
        end

    else
        #just resave it...
        transaction.status2 = true
        transaction.save

        if sent_object.is_reversal
            txtmsg = "Your deposit of GHS #{amt} to #{account_no_formatter(acctno)} could not be reversed at this time. Transaction ID of reversal: #{trans_ref}"
            sendmsg(MSGSENDERID, mobile_number, txtmsg) if transaction.src == DEFAULT_SRC

        else
            #it's an actual withdrawal but it has failed so reverse
            #  params = {
            #      account_no: acctno,
            #      exttrxnid: trans_ref,
            #      return_url: BTW_RETURN_URL,
            #      amount: amt,
            #      wallet_nw: get_nw_code(nw),
            #      req_type: BTW,
            #      mobile_no: mobile_number,
            #      mobile_nw: get_nw_code(nw)
            #  }
            #
            # handle_reversal(params) #so simple
            #
            #  sendmsg(MSGSENDERID, '233247915505',"Reversal would have taken place in main_app.rb line 353. transaction ID: #{trans_ref}")
            txtmsg_client = ""
            txtmsg_default = ""
          if transaction.src == DEFAULT_SRC
              txtmsg_default="Your withdrawal of GHS #{amt} was unsuccessful. Your bank account will be credited. Transaction ID: #{trans_ref}"
              # sendmsg(MSGSENDERID, transaction.mobile_number, txtmsg)
            else
                txtmsg_client_admin="Your disbursement of GHS #{amt} to #{mobile_number} was unsuccessful. Log on to the web portal and reverse. Transaction ID: #{trans_ref}"
                txtmsg_client="Your withdrawal of GHS #{amt} was unsuccessful. Your account will be credited. Transaction ID: #{trans_ref}"

                client = PremiumClient.where(src: transaction.src).active.last
                phone_number = phone_formatter(client.contact_number)

                sendmsg(MSGSENDERID, phone_number, txtmsg_client_admin) if phone_number
            end

            txt_hash = {
                DEFAULT_SRC => [MSGSENDERID, txtmsg_default],
                LOY_SRC => [LOY_SENDER_ID, txtmsg_client]
            }

            sendmsg_conditional(transaction.mobile_number,txt_hash,transaction.src)
        end
    end
    # transaction.update(status2: true)
    # transaction.save
    # puts "----------------------------------------------------------------------------------"
    # puts "----------------------------------------------------------------------------------"
    # puts "FINAL TRANSACTION OBJECT: #{transaction.inspect} ---------------------------------"
    # puts "----------------------------------------------------------------------------------"
    # puts "----------------------------------------------------------------------------------"
    #LOYALTY DEPOSIT
    if transaction.src == LOY_SRC
        loy_hash = Hash.new
        amfp_resp == '000' ? loy_hash['credit_status'] = 'Success' : 'Failure'
        transaction.err_code == T24_SUCCESS ? loy_hash['debit_status'] = 'Success' : 'Failure'
        transaction.final_status ? loy_hash['status'] = 'Success' : 'Failure'
        push_loyalty_callback(loy_hash) #push callback
    end
end


post "/pm_req_wtb" do
    request.body.rewind
    req = JSON.parse request.body.read
    #
    # File.open('callback.log','a+') do |file|
    #     file.write(req.inspect)
    #     file.write("\n\n\n\n-------------------------------------------END-------------------------------------------")
    #     file.close
    # end

    p "-----------------PREMIUM T24 CREDIT CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"
end



post "/pm_topup_response" do



    request.body.rewind
    req = JSON.parse request.body.read
    #
    # File.open('callback.log','a+') do |file|
    #     file.write(req.inspect)
    #     file.write("\n\n\n\n-------------------------------------------END-------------------------------------------")
    #     file.close
    # end

    p "-----------------PREMIUM MOBILE MONEY TOPUP CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"

    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"]
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    amfp_resp = _trans_status[0]
    nw_resp = _trans_status[1]

    sent_object = SentCallback.where(trnx_id: trans_ref).first

    #customer = Subscription.find_by(mobile_number: sent_object.mobile_number, subscribed: true, changed_status: false)
    mobile_number = sent_object.mobile_number
    amt = sent_object.amount
    nw = sent_object.network


    #transaction = BankTransaction.find_by(transaction_ref_id: trans_ref)



    #log mobile money
    params = Hash.new
    params['merchant_number'] = MERCHANT_NUMBER_ANB #has to change
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = nw_resp
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref

    pm_log_mobile_money(params)

    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = nw
    pm_log_callback_resp(parameters)

    #send txt message

    transaction = BankTransaction.where(transaction_ref_id: trans_ref).first
    #transaction.trans_step = AM_WALLET_DR_COMPLETED # error
    #first part is complete

    unless transaction.nw_resp.nil?
      puts "TRANSACTION REJECTED: DUPLICATE"
        return #cut the whole thing
    end

    mobile_number1 = transaction.mobile_number #sender's number
    mobile_number2 = transaction.mobile_number2
    transaction.nw_resp = message
    transaction.save
    transaction.status2 = 1
    transaction.err_code2 = amfp_resp
    transaction.save

    acctno = transaction.account_number

    if amfp_resp == '000'
        #set to one only when successful
        transaction.final_status = true
        transaction.save
        #update transaction transaction

        #if customer


        if mobile_number2
            txtmsg = "Your airtime top-up of #{amt} from  #{acctno} to #{mobile_number2} was successful. Balance is #{transaction.balance}. Transaction ID: #{transaction.transaction_ref_id}"
            sendmsg(MSGSENDERID, mobile_number1, txtmsg) if transaction.src == DEFAULT_SRC
            txtmsg = "You have received airtime worth GHS #{amt} from #{mobile_number}. Transaction ID: #{transaction.transaction_ref_id}"
            sendmsg(MSGSENDERID, mobile_number2, txtmsg) if transaction.src == DEFAULT_SRC

        else
            txtmsg_client = ""
            txtmsg_default = ""
            if transaction.subscription.is_client
                client_code = transaction.subscription.client_code
                client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('created_at desc')[0]
                txtmsg_client = "You have received GHS #{amt} worth of airtime from #{client.company_name}. Transaction ID: #{trans_ref}"
                # sendmsg(MSGSENDERID, mobile_number1, txtmsg)
            else
                txtmsg_default = "Your top-up of GHS #{amt} from #{acctno} was successful. Balance is #{transaction.balance}, Transaction ID: #{transaction.transaction_ref_id}"
            end
            # sendmsg(MSGSENDERID, mobile_number1, txtmsg) if transaction.src == DEFAULT_SRC

            txt_hash = {
                DEFAULT_SRC => [MSGSENDERID, txtmsg_default],
                LOY_SRC => [LOY_SENDER_ID, txtmsg_client]
            }

            sendmsg_conditional(mobile_number,txt_hash,transaction.src)
        end
    else
        txtmsg="Your top-up of GHS #{amt} was unsuccessful. Your bank account will be credited with the amount."
        sendmsg(MSGSENDERID, mobile_number, txtmsg) if transaction.src == DEFAULT_SRC

        params = {
            account_no: acctno,
            exttrxnid: trans_ref,
            return_url: BTW_RETURN_URL,
            amount: amt,
            wallet_nw: get_nw_code(nw),
            req_type: MTP,
            mobile_no: mobile_number1,
            mobile_nw: get_nw_code(nw)
        }

        handle_reversal(params) #so simple

        sendmsg(MSGSENDERID, '233247915505', "Reversal would have taken place on line 495 of main_app.rb. Transaction ID: #{trans_ref}") if transaction.src == DEFAULT_SRC
    end

    #LOYALTY DEPOSIT
    if transaction.src == LOY_SRC
        loy_hash = Hash.new
        amfp_resp == '000' ? loy_hash['credit_status'] = 'Success' : 'Failure'
        transaction.err_code == T24_SUCCESS ? loy_hash['debit_status'] = 'Success' : 'Failure'
        transaction.final_status ? loy_hash['status'] = 'Success' : 'Failure'
        push_loyalty_callback(loy_hash) #push callback
    end

end



#JARA CALLBACKS
#################################################################################################
#################################################################################################
post '/reqCallback' do

    p "REGISTRATION CALL BACK..........................."

    request.body.rewind
    req = JSON.parse request.body.read
    #
    # File.open('callback.log','a+') do |file|
    #     file.write(req.inspect)
    #     file.write("\n\n\n\n-------------------------------------------END-------------------------------------------")
    #     file.close
    # end

    p "REQUEST: #{req.inspect}"
    puts
    puts
    puts "---------------------------AMFP/NETWORK RESPONSE---------------------"

    #{\"trans_id\"=>\"MP161013.1120.C01460\", \"trans_status\"=>\"000/200\", \"trans_ref\"=>\"1610130961122\", \"message\"=>\"Success\"}"
    # "REQUEST: {\"trans_id\"=>\"MP161031.1436.C09061\", \"trans_status\"=>\"000/200\", \"trans_ref\"=>\"1610314521438\", \"message\"=>\"Success\"}"
    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"]
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    _amfp_resp = _trans_status[0]

    puts "AMFP RESP #{_amfp_resp}"
    _nw_resp = _trans_status[1]

    puts _trans_status
    puts
    puts
    puts "**********************************************************************"

    pending_deposit = PendingDeposit.find_by(trnx_id: trans_ref)
    #check against multiple callbacks
    if pending_deposit
      puts "TRANSACTION REJECTED: DUPLICATE"
        return #cut the whole thing
    end

    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = ""
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = ""
    pm_log_callback_resp(parameters)



    sent_callback_obj = JSentCallback.find_by(trnx_id: trans_ref)
    #use the transref to get mobile number

    puts "###########################################################################################################################"
    puts
    puts "------------------------------------------------SENT CALL BACK JARA PROSPECT CUSTOMER--------------------------------------"
    puts
    puts "###########################################################################################################################"

    puts "SENT CALL BACK OBJ: #{sent_callback_obj.inspect}"

    puts "###########################################################################################################################"
    puts
    puts "------------------------------------------------SENT CALL BACK JARA PROSPECT CUSTOMER--------------------------------------"
    puts
    puts "###########################################################################################################################"

    mobile_number = sent_callback_obj.mobile_number






    #####################################################################################
    #customer = RegisteredCustomer.find_by(phone_number: sent_callback_obj.mobile_number)

    #acctno = customer.assigned_acct_no
    amt = sent_callback_obj.amount
    #send money to account
    nw = sent_callback_obj.network


    #log mobile money
    params = Hash.new
    params['merchant_number'] = J_MERCHANT_NUMBER_ANB
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = _nw_resp
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref
    log_mobile_money(params)

    #LOG IT AGAIN
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status
    parameters['resp_desc'] = message
    parameters['network'] = nw
    log_callback_resp(parameters)

    #use mobile_number to get prospect_cust_reg object
    puts "WHAT IS HAPPENING HERE............................................"
    puts
    puts
    puts "###########################################################"
    prospect_obj = ProspectCustReg.find_by(phone_number: mobile_number, active_status: true)

    prospect = prospect_obj.nil? ? ProspectCustReg.find_by(phone_number: mobile_number) : prospect_obj
    prospect.active_status = true

    #cater for missing records in the future

    if _amfp_resp == "000"
        puts "AMFP RESP = 000"

        # prospect = ProspectCustReg.where(agent_number: mobile_number).order('id desc').limit(1)[0] #agent registration
        # if prospect
        #     p "AGENT REGISTRATION: #{prospect.inspect}"
        #     prospect.status = true
        #     prospect.save
        # else

        # p "SELF REGISTRATION: #{prospect.inspect}"
        prospect.status = true
        prospect.save
        # end

        #if successful???
        #save to pending deposit
        PendingDeposit.create(
            phone_number: prospect.phone_number,
            trnx_id: trans_ref,
            amount: amt,
            network: nw,
            nw_resp: message,
            status: true
        )

        puts "PENDING DEPOSIT CREATED..."

        #new_execDeposit(acctno, amt, mobile_number)
        #####################################################################################

        #create pre registration
        parameters = Hash.new
        parameters['phone_number'] = prospect.phone_number
        parameters['customer_name'] = prospect.customer_name
        #parameters['status'] = 0
        parameters['alt_number'] = prospect.alt_number
        parameters['agent_number'] = prospect.agent_number
        parameters['id_type'] = prospect.id_type
        parameters['id_number'] = prospect.id_number
        parameters['id_issue_date'] = prospect.id_issue_date
        parameters['id_expiry_date'] = prospect.id_expiry_date
        parameters['date_of_birth'] = prospect.date_of_birth

        customer = pre_register(parameters)

        p "CUSTOMER REGISTERED: ...."
        p customer.inspect



        resp={:resp_code=>"00", :resp_desc=>"Success"}

        txtmsg = "Your registration has begun successfully. You will be notified when it is completed. Thank you."
        puts j_sendmsg(J_MSGSENDERID, prospect.phone_number, txtmsg)

        reg_msg = "Registration request.\n Name: #{prospect.customer_name}\nPhone Number: #{prospect.phone_number}\nAlternative Phone Number: #{prospect.alt_number}"

        Thread.new{
            j_notify(NOTIFY_REG, reg_msg)
        }

        if prospect.agent_number
            txtmsg_agent = "You have successfully initiated the registration of #{prospect.customer_name}"
            puts j_sendmsg(J_MSGSENDERID, prospect.agent_number, txtmsg_agent)
        end

    else
        resp={:resp_code=>"01", :resp_desc=>"Failure"}

        p "REGISTRATION FAILED................."
        #reverse process
        puts "DID REGISTRATION FAIL???"
        txtmsg = "Your registration failed, please try again later."
        puts j_sendmsg(J_MSGSENDERID, prospect.phone_number, txtmsg)
    end





    p resp.to_json

    #log call back
    #update prospect_cust_reg status to 1
    #create customer in pre registration
    #if successful


end

#call back small functions


post '/jr_debit_response' do

    request.body.rewind
    req = JSON.parse request.body.read
    #
    # File.open('callback.log','a+') do |file|
    #     file.write(req.inspect)
    #     file.write("\n\n\n\n-------------------------------------------END-------------------------------------------")
    #     file.close
    # end

    p "-----------------JARA MOBILE MONEY DEBIT CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"

    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"].to_s
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    amfp_resp = _trans_status[0]
    nw_resp = _trans_status[1]

    sent_object = JSentCallback.find_by(trnx_id: trans_ref)

    customer = RegisteredCustomer.find_by(phone_number: sent_object.mobile_number)
    mobile_number = sent_object.mobile_number
    amt = sent_object.amount
    nw = sent_object.network


    #log mobile money
    params = Hash.new
    params['merchant_number'] = J_MERCHANT_NUMBER_ANB
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = nw_resp
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref

    log_mobile_money(params)

    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = nw
    log_callback_resp(parameters)

    #send txt message

    summary = TransactionSummary.find_by(transaction_ref_id: trans_ref)

    #summary.trans_step = AM_WALLET_DR_COMPLETED # error
    #first part is complete
    if summary

        unless summary.nw_resp.nil?
            return
        end

        summary.nw_resp = message
        summary.save
        summary.status = 1
        summary.err_code = amfp_resp
        #summary.pending = true unless customer #make it pending if pending customer
        summary.save
    end

    ############# TRY AND GET CLIENT #####################
    client = PremiumClient.where(src: summary.src).active.order('id desc').first

    if amfp_resp == '000'
        #set to one only when successful

        #update transaction summary

        if customer
            acctno = customer.assigned_acct_no
            #send money to account
            new_execDeposit(acctno, amt, mobile_number, trans_ref)


        #EXCEPTION FOR COMPLETE FARMER
        ###########################################################
        elsif summary.src == COMPLETE_FARMER_SRC
          acct_no = client.collection_account
            new_execDeposit(acct_no, amt, mobile_number, trans_ref)

          #create prospect
          prospect = ProspectCustReg.where(mobile_number: mobile_number).order('id desc').first

          parameters = Hash.new
          parameters['phone_number'] = prospect.phone_number
          parameters['customer_name'] = prospect.customer_name
          #parameters['status'] = 0
          parameters['alt_number'] = prospect.alt_number

          parameters['id_type'] = prospect.id_type
          parameters['id_number'] = prospect.id_number
          parameters['id_issue_date'] = prospect.id_issue_date
          parameters['id_expiry_date'] = prospect.id_expiry_date
          parameters['date_of_birth'] = prospect.date_of_birth
          parameters['src'] = prospect.src

          customer = fml_pre_register(parameters)

        ###########################################################
        else
            #person hasn't fully registered... use pending
            PendingDeposit.create(
                phone_number: mobile_number,
                trnx_id: trans_ref,
                amount: amt,
                status: true,
                network: nw,
                nw_resp: message

            )

            txtmsg="Your deposit of GHS #{amt} is pending. It will be available once your account creation is complete. Transaction ID: #{trans_ref}"
            j_sendmsg(J_MSGSENDERID, mobile_number, txtmsg)
        end

    else
        txtmsg="Your deposit of GHS #{amt} was unsuccessful. Transaction ID: #{trans_ref}"
        j_sendmsg(J_MSGSENDERID, mobile_number, txtmsg)

    end
end

post '/jr_credit_response' do

    request.body.rewind
    req = JSON.parse request.body.read

    p "-----------------JARA MOBILE MONEY CREDIT CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"

    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"]
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    amfp_resp = _trans_status[0]
    nw_resp = _trans_status[1]

    sent_object = JSentCallback.find_by(trnx_id: trans_ref)
    puts "SENT CALLBACK OBJECT: #{sent_object.inspect}"
    customer = RegisteredCustomer.find_by(phone_number: sent_object.mobile_number)

    acctno = customer.assigned_acct_no
    amt = sent_object.amount
    mobile_number = sent_object.mobile_number
    nw = sent_object.network


    summary = TransactionSummary.find_by(transaction_ref_id: trans_ref)

    #check against multiple callbacks
    unless summary.err_code2.nil?
        return #cut the whole thing
    end

    summary.nw_resp = message
    summary.status2 = true
    summary.err_code2 = amfp_resp
    summary.save
    #summary.save
    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = nw
    log_callback_resp(parameters)

    #log mobile money
    # merchant_no: ,
    #     customer_no: parameters['customer_number'],
    #     amount: parameters['amount'],
    #     network: parameters['network'],
    #     trnx_id: parameters['trnx_id'],
    #     resp_code: parameters['resp_code'],
    #     resp_desc: parameters['resp_desc']

    params = Hash.new
    params['merchant_number'] = J_MERCHANT_NUMBER_ANB
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = trans_status
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref

    log_mobile_money(params)



    if amfp_resp == '000' #&& mobile_number != '233247915505'

        #SAVE SUCCESS CODE
        summary.final_status = true
        summary.save
        #summary.trans_step = AM_WALLET_DR_COMPLETED # error
        #final part complete
        puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        puts "                                                                                        +"
        puts "                                                                                        +"
        p "SUMMARY CONTAINING MESSAGE: #{summary.inspect}                                             +"
        puts "                                                                                        +"
        puts "                                                                                        +"
        puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"





        #send messages to back office admins
        # if !sent_object.is_reversal
        #     txt = "There was a reversal for customer with name #{customer.customer_name} and number #{mobile_number} for withdrawal of #{amt} on JARA"
        # elsif sent_object.is_reversal.nil?
        #
        # end
        txt = "You have withdrawn GHS #{amt} from acct. no #{acctno} on JARA successfully. Your available balance is #{summary.available_bal}. Transaction ID: #{trans_ref}"

        j_sendmsg(J_MSGSENDERID, mobile_number, txt)

        # Thread.new {
        #     txt = "Customer with name #{customer.customer_name} and number #{mobile_number} has withdrawn #{amt} on JARA. Transaction ID: #{trans_ref}"
        #     #send customer txt msg
        # admins = CustAdmin.where(withdraw_notify: true)
        # admins.each do |admin|
        #     sendmsg(J_MSGSENDERID, admin.phone_number, txt)
        # end
        # }

    else
        #rev_resp =  j_handle_reversal(trans_ref, acctno, amt)
        # if rev_resp
        #     txt = "Your withdrawal request was unsuccesful. Transaction has been reversed.Transaction ID: #{trans_ref}. Thank you."
        #     sendmsg(J_MSGSENDERID, mobile_number, txt)
        #     #customer = ProspectCustReg.find_by(phone_number: mobile_number)
        #     back_office_text = "Withdrawal request for customer with account number,  #{account_no_formatter(acctno)}, was unsuccessful. Transaction has been reversed.Transaction ID: #{trans_ref}. Thank you."
        #     Thread.new{
        #         notify(NOTIFY_REVERSALS, back_office_text)
        #             }
        #
        # else
        txt = "Your withdrawal request was unsuccessful, your account will be credited.Transaction ID: #{trans_ref}. Thank you."
        #txt = "Your withdrawal of GHS #{amt} from #{acctno} has failed and has been reversed successfully. Transaction ID: #{trans_ref}"
        j_sendmsg(J_MSGSENDERID, mobile_number, txt)
        #customer = ProspectCustReg.find_by(phone_number: mobile_number)
        back_office_text = "Withdrawal request for customer with account number,  #{account_no_formatter(acctno)}, was unsuccessful and requires reversal.  Transaction ID: #{trans_ref}."
        Thread.new{
            j_notify(NOTIFY_REVERSALS, back_office_text)
        }
        # end


    end
end


####################
post '/pm_wallet_push' do

  ###################################################################################

  ###################################################################################
    request.body.rewind
    req = JSON.parse request.body.read
    #
    # File.open('callback.log','a+') do |file|
    #     file.write(req.inspect)
    #     file.write("\n\n\n\n-------------------------------------------END-------------------------------------------")
    #     file.close
    # end

    p "-----------------PREMIUM MOBILE MONEY CREDIT CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"

    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"].to_s
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    amfp_resp = _trans_status[0]
    nw_resp = _trans_status[1]

    sent_object = SentCallback.where(trnx_id: trans_ref).first

    #customer = Subscription.find_by(mobile_number: sent_object.mobile_number, subscribed: true, changed_status: false)
    mobile_number = sent_object.mobile_number
    amt = sent_object.amount
    nw = sent_object.network

    #if it's not a reversal... do this
    # if sent_object.is_reversal
    #     puts "in if object.is_reversal"
    #     puts "sent object is_reversal = #{sent_object.is_reversal}"
    #     reprocess = TransactionReprocess.where(new_trnx_id: sent_object.trnx_id).first
    #     reprocess.status2 = true
    #     reprocess.err_code2 = amfp_resp
    #     reprocess.nw_resp_desc = nw_resp
    #     transaction = BankTransaction.where(transaction_ref_id: reprocess.old_trnx_id).first
    # else
    puts "in else object.is_reversal"
    puts "sent object is_reversal = #{sent_object.is_reversal}"

    if sent_object.is_reversal

        reprocessed_transaction = TransactionReprocess.where(new_trnx_id: trans_ref).order('id desc').first
        transaction = BankTransaction.where(transaction_ref_id: reprocessed_transaction.old_trnx_id).order('id desc').first
        puts "TRANSACTION REPROCESS: #{reprocessed_transaction.inspect}"
        puts "TRANSACTION: #{transaction.inspect}"

    else

        transaction = BankTransaction.where(transaction_ref_id: trans_ref).first
        transaction.nw_resp = message
        transaction.status2 = true
        puts "STATUS2: #{transaction.status2}"
        transaction.err_code2 = amfp_resp
        transaction.save

    end

    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts
    # puts "TRANSACTION OBJECT AFTER SAVING STATUS2: #{transaction.inspect} on line 282"
    # puts
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # puts "******************************************************************************************************"
    # end

    #transaction = BankTransaction.find_by(transaction_ref_id: trans_ref)


    #log mobile money
    params = Hash.new
    params['merchant_number'] = MERCHANT_NUMBER_ANB #has to change
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = nw_resp
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref

    pm_log_mobile_money(params)

    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = nw
    pm_log_callback_resp(parameters)

    #send txt message


    acctno = transaction.account_number
    if amfp_resp == '000'
        #set to one only when successful
        transaction.status2 = true

        if sent_object.is_reversal #if it's reversal...
          reprocessed_transaction.final_status = true
          reprocessed_transaction.save
            transaction.is_reversal = true
            transaction.save
            txtmsg = "Your deposit of GHS #{amt} to #{account_no_formatter(acctno)} has been reversed successfully. Transaction ID of reversal: #{trans_ref}"
            sendmsg(MSGSENDERID, mobile_number, txtmsg)

        elsif transaction.trans_type == BILL_PAY
            #bill payment
            transaction.final_status = true
            transaction.save
            txtmsg = "Your #{transaction.bill_type} bill payment of GHS #{amt} from #{account_no_formatter(acctno)} was successful. Balance is #{transaction.balance}, Transaction ID: #{transaction.transaction_ref_id}"
            sendmsg(MSGSENDERID, mobile_number, txtmsg) if transaction.src == DEFAULT_SRC

        else
            transaction.final_status = true
            transaction.save


            #check for second number (that's if it's third party)
            if transaction.mobile_number2
                #the above message was sent to this number, so send message to the sender (mobile_number)
                if nw == MTN_PARAM
                    network = "MTN"
                elsif nw == AIRTEL_PARAM
                    network = "Airtel"
                elsif nw == VODA_PARAM
                    network = "Vodafone"
                elsif nw == TIGO_PARAM
                    network = "Tigo"
                else
                    network = ""
                end

                txtmsg = "Your transfer of GHS #{amt} from #{account_no_formatter(acctno)} to the #{network} number #{mobile_number} was successful. Balance is #{transaction.balance}, Transaction ID: #{transaction.transaction_ref_id}"
                sendmsg(MSGSENDERID, transaction.mobile_number, txtmsg) if transaction.src == DEFAULT_SRC

                customer = get_subscriber(transaction.mobile_number) #here

                txtmsg2 = "You have successfully received GHS #{amt} from #{customer.firstname} #{customer.lastname}. Phone Number:  #{transaction.mobile_number}. Transaction ID: #{trans_ref}"
                sendmsg(MSGSENDERID, transaction.mobile_number2,txtmsg2) if transaction.src == DEFAULT_SRC
            else
                txtmsg_client = ""
                txtmsg_default = ""
                #loyalty
                if transaction.subscription.is_client
                    client_code = transaction.subscription.client_code
                    client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('created_at desc')[0]
                    txtmsg_client = "You have successfully received GHS #{amt} from #{client.company_name}. Transaction ID: #{trans_ref}"
                    # sendmsg(MSGSENDERID, mobile_number, txtmsg)
                else
                    txtmsg_default = "Your withdrawal of GHS #{amt} from #{account_no_formatter(acctno)} was successful. Balance is #{transaction.balance}, Transaction ID: #{transaction.transaction_ref_id}"
                end

                txt_hash = {
                    DEFAULT_SRC => [MSGSENDERID, txtmsg_default],
                    LOY_SRC => [LOY_SENDER_ID, txtmsg_client]
                }

                sendmsg_conditional(mobile_number,txt_hash,transaction.src)
            end
        end

    else
        #just resave it...
        transaction.status2 = true
        transaction.save

        if sent_object.is_reversal
            txtmsg = "Your deposit of GHS #{amt} to #{account_no_formatter(acctno)} could not be reversed at this time. Transaction ID of reversal: #{trans_ref}"
            sendmsg(MSGSENDERID, mobile_number, txtmsg) if transaction.src == DEFAULT_SRC

        else
            #it's an actual withdrawal but it has failed so reverse
            #  params = {
            #      account_no: acctno,
            #      exttrxnid: trans_ref,
            #      return_url: BTW_RETURN_URL,
            #      amount: amt,
            #      wallet_nw: get_nw_code(nw),
            #      req_type: BTW,
            #      mobile_no: mobile_number,
            #      mobile_nw: get_nw_code(nw)
            #  }
            #
            # handle_reversal(params) #so simple
            #
            #  sendmsg(MSGSENDERID, '233247915505',"Reversal would have taken place in main_app.rb line 353. transaction ID: #{trans_ref}")
            txtmsg_client = ""
            txtmsg_default = ""
            if transaction.src == DEFAULT_SRC
                txtmsg_default="Your withdrawal of GHS #{amt} was unsuccessful. Your bank account will be credited. Transaction ID: #{trans_ref}"
                # sendmsg(MSGSENDERID, transaction.mobile_number, txtmsg)
            else
                txtmsg_client_admin="Your disbursement of GHS #{amt} to #{mobile_number} was unsuccessful. Log on to the web portal and reverse. Transaction ID: #{trans_ref}"
                txtmsg_client="Your withdrawal of GHS #{amt} was unsuccessful. Your account will be credited. Transaction ID: #{trans_ref}"

                client = PremiumClient.where(src: transaction.src).active.last
                phone_number = phone_formatter(client.contact_number)

                sendmsg(MSGSENDERID, phone_number, txtmsg_client_admin) if phone_number
            end

            txt_hash = {
                DEFAULT_SRC => [MSGSENDERID, txtmsg_default],
                LOY_SRC => [LOY_SENDER_ID, txtmsg_client]
            }

            sendmsg_conditional(transaction.mobile_number,txt_hash,transaction.src)
        end
    end
    # transaction.update(status2: true)
    # transaction.save
    # puts "----------------------------------------------------------------------------------"
    # puts "----------------------------------------------------------------------------------"
    # puts "FINAL TRANSACTION OBJECT: #{transaction.inspect} ---------------------------------"
    # puts "----------------------------------------------------------------------------------"
    # puts "----------------------------------------------------------------------------------"
    #LOYALTY DEPOSIT
    if transaction.src == LOY_SRC
        loy_hash = Hash.new
        amfp_resp == '000' ? loy_hash['credit_status'] = 'Success' : 'Failure'
        transaction.err_code == T24_SUCCESS ? loy_hash['debit_status'] = 'Success' : 'Failure'
        transaction.final_status ? loy_hash['status'] = 'Success' : 'Failure'
        push_loyalty_callback(loy_hash) #push callback
    end
end


################ fml topup

post '/fml_topup' do

    #expected hash: {trnx_id: xxxx, amount: xxx, mobile_no: xxxx, nw: AIR}

    request.body.rewind

    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts "----------------- FARMLINE API TOPUP --------------------"
    puts "------------------- IN COMING PAYLOAD ----------------------"
    puts json_vals

    response = fml_topup(json_vals)
    puts response.to_json
    return response.to_json
end

#FARM LINE API ##################################################################################
post '/fml_tp_callback' do

    request.body.rewind
    req = JSON.parse request.body.read

    p "-----------------JARA FML TOPUP CALLBACK RESPONSE----------------------"

    p "REQUEST: #{req.inspect}"

    puts trans_id=req["trans_id"]
    puts trans_status=req["trans_status"]
    puts trans_ref=req["trans_ref"]
    puts message=req["message"]

    _trans_status = trans_status.split('/')
    amfp_resp = _trans_status[0]
    nw_resp = _trans_status[1]

    sent_object = JSentCallback.find_by(trnx_id: trans_ref)
    puts "SENT CALLBACK OBJECT: #{sent_object.inspect}"
    customer = RegisteredCustomer.find_by(phone_number: sent_object.mobile_number)

    acctno = customer.assigned_acct_no
    amt = sent_object.amount
    mobile_number = sent_object.mobile_number
    nw = sent_object.network


    summary = TransactionSummary.find_by(transaction_ref_id: trans_ref)
    summary.nw_resp = message
    summary.status2 = true
    summary.err_code2 = amfp_resp
    summary.save
    #summary.save
    #log callback
    parameters = Hash.new
    parameters['trans_id'] = trans_id
    parameters['trans_ref'] = trans_ref
    parameters['mobile_number'] = mobile_number
    parameters['resp_code'] = trans_status

    parameters['resp_desc'] = message
    parameters['network'] = nw
    log_callback_resp(parameters)

    #log mobile money
    # merchant_no: ,
    #     customer_no: parameters['customer_number'],
    #     amount: parameters['amount'],
    #     network: parameters['network'],
    #     trnx_id: parameters['trnx_id'],
    #     resp_code: parameters['resp_code'],
    #     resp_desc: parameters['resp_desc']

    params = Hash.new
    params['merchant_number'] = J_MERCHANT_NUMBER_ANB
    params['customer_number'] = mobile_number
    params['amount'] = amt
    params['network'] = nw
    params['resp_code'] = trans_status
    params['resp_desc'] = message
    params['trnx_id'] = trans_ref

    log_mobile_money(params)

    if amfp_resp == '000' #&& mobile_number != '233247915505'

        #SAVE SUCCESS CODE
        summary.final_status = true
        summary.save
        #summary.trans_step = AM_WALLET_DR_COMPLETED # error
        #final part complete
        puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        puts "                                                                                        +"
        puts "                                                                                        +"
        p "SUMMARY CONTAINING MESSAGE: #{summary.inspect}                                             +"
        puts "                                                                                        +"
        puts "                                                                                        +"
        puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

        #send messages to back office admins
        # if !sent_object.is_reversal
        #     txt = "There was a reversal for customer with name #{customer.customer_name} and number #{mobile_number} for withdrawal of #{amt} on JARA"
        # elsif sent_object.is_reversal.nil?
        #
        # end

        #txt = "You have made a top of GHS #{amt} from acct. no #{acctno} on JARA successfully. Your available balance is #{summary.available_bal}. Transaction ID: #{trans_ref}"

        #j_sendmsg(J_MSGSENDERID, mobile_number, txt)

        # Thread.new {
        #     txt = "Customer with name #{customer.customer_name} and number #{mobile_number} has withdrawn #{amt} on JARA. Transaction ID: #{trans_ref}"
        #     #send customer txt msg
        # admins = CustAdmin.where(withdraw_notify: true)
        # admins.each do |admin|
        #     sendmsg(J_MSGSENDERID, admin.phone_number, txt)
        # end
        # }

    else
        #rev_resp =  j_handle_reversal(trans_ref, acctno, amt)
        # if rev_resp
        #     txt = "Your withdrawal request was unsuccesful. Transaction has been reversed.Transaction ID: #{trans_ref}. Thank you."
        #     sendmsg(J_MSGSENDERID, mobile_number, txt)
        #     #customer = ProspectCustReg.find_by(phone_number: mobile_number)
        #     back_office_text = "Withdrawal request for customer with account number,  #{account_no_formatter(acctno)}, was unsuccessful. Transaction has been reversed.Transaction ID: #{trans_ref}. Thank you."
        #     Thread.new{
        #         notify(NOTIFY_REVERSALS, back_office_text)
        #             }
        #
        # else
        txt = "Your top up request was unsuccessful, your account will be credited.Transaction ID: #{trans_ref}. Thank you."
        #txt = "Your withdrawal of GHS #{amt} from #{acctno} has failed and has been reversed successfully. Transaction ID: #{trans_ref}"
        #j_sendmsg(J_MSGSENDERID, mobile_number, txt)
        #customer = ProspectCustReg.find_by(phone_number: mobile_number)
        back_office_text = "Farmerline top up request for customer with account number,  #{account_no_formatter(acctno)}, was unsuccessful and requires reversal.  Transaction ID: #{trans_ref}."
        # Thread.new{
        #     j_notify(NOTIFY_REVERSALS, back_office_text)
        # }
        # end


    end

    fml_log_obj = FmlLog.where(trans_id: trans_ref).order('id desc').first
    if fml_log_obj

        request = eval(fml_log_obj.req_body)    #get the request body that was sent
        call_back_url = request['topup_callback']

        # url = 'https://banking.paytime.com.gh'
        # endpoint = '/api/jara'
        fml_conn = Faraday.new(:url => call_back_url,:headers => {'Content-Type'=>'Application/json','timeout'=>'180'}, :ssl => {:verify => false}) do |faraday|
            faraday.response :logger                  # log requests to STDOUT
            faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end

        params = {trnx_id: trans_ref,
                  mobile_no: mobile_number,
                  status: "#{amfp_resp == '000' ? "Success":"Failure"}",
        }
        json_params = JSON.generate(params)

        response = fml_conn.post do |req|
            req.body = json_params
        end

        puts response.inspect


    end
end
##################################################################################################

post '/fml_deposit' do

  #expected json: {trnx_id: '122367654', 'amount': '50', mobile_no: '2332345674', nw:'AIR'}

  request.body.rewind

    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # fml_logger(json_vals, request.path)

  # unless security_check(request, json_vals)
  #     return {status: '401', message: 'Unauthorized'}.to_json
  # end

    puts "----------------- FARMLINE API DEPOSIT --------------------"
    puts "--------------- IN COMING PAYLOAD------------------"
    puts json_vals

    response = deposit(json_vals)
    puts response.to_json
    return response.to_json
end

post '/fml_register' do

# expected hash {trnx_id: xxx, amount: x.xx, mobile_no: xxxxxxxxx, nw: MTN|AIR|TIG|, date_of_birth: 20150505,
# id_type: 'Drivers Lic', id_number: xxxxxxx, id_issue_date: 20160606, id_expiry_date: 20170707,
# fullname: 'John Doe', alt_number: '233xxxxx'}

    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)

    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts "----------------- FARMLINE API REGISTER --------------------"
    puts "--------------- IN COMING PAYLOAD------------------"
    puts json_vals

    response = register(json_vals)
    puts response.to_json
    return response.to_json
end

post '/fml_check_balance' do
#expected hash : {trnx_id: xxxx, mobile_no: xxxx}
    request.body.rewind

    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)

    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts "----------------- FARMLINE API CHECK BALANCE --------------------"
    puts "--------------- IN COMING PAYLOAD------------------"
    puts json_vals

    response = fml_check_balance(json_vals)
    puts response.to_json
    return response.to_json
end

post '/fml_withdraw' do

    #expected hash: {trnx_id: xxxx, amount: xxx, mobile_no: xxxx, nw: AIR}

    request.body.rewind

    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)

    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end



    puts "----------------- FARMLINE API WITHDRAW --------------------"
    puts "------------------- IN COMING PAYLOAD ----------------------"
    puts json_vals

    response = fml_withdraw(json_vals)
    puts response.to_json
    return response.to_json
end

post '/fml_check_trans_status' do

    #expected hash {trnx_id: xxxxxx}
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts "----------------- FARMLINE API CHECK TRANS STATUS --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals

    response = check_trans_status(json_vals)
    puts response.to_json
    return response.to_json
end

post '/fml_withdraw_response' do
    #expected hash: {trnx_id: xxxx, status: xx}
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts "----------------- FARMLINE API CHECK TRANS STATUS --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals

    response = withdraw_response(json_vals)
    puts response.to_json
    return response.to_json
end


post '/fml_withdrawal_reversal' do
    #expected hash: {trnx_id: xxxx}
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # fml_logger(json_vals, request.path)
    puts "----------------- FARMLINE API REVERSE WITHDRAWAL --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals


    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    response = fml_withdrawal_reversal(json_vals)
    puts response.to_json
    return response.to_json
end

post '/fml_customer' do
    #expected hash {phone_number: xxxxxx}
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # fml_logger(json_vals, request.path)
    puts "----------------- FARMLINE API CUSTOMER DETAILS --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    response = fml_customer(json_vals)
    puts response.to_json
    return response.to_json
end


########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
# >>>>>>>>>>>>>>>>>>>>>                                                             <<<<<<<<<<<<<<<<<<<<
# >>>>>>>>>>>>>>>>>>>>>                 LOYALTY INSURANCE                           <<<<<<<<<<<<<<<<<<<<
# >>>>>>>>>>>>>>>>>>>>>                                                             <<<<<<<<<<<<<<<<<<<<
########################################################################################################

post '/loy_deposit' do
    #expected hash {phone_number: xxxxxx}
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    #loy_logger(json_vals, request.path, request.ip)
    puts "----------------- LOYALTY API DEPOSIT --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts json_vals

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    response = loy_deposit(json_vals)
    puts response.to_json
    return response.to_json
end

post '/client_withdrawal' do
    #expected hash {phone_number: xxxxxx}
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    #loy_logger(json_vals, request.path, request.ip)
    puts "----------------- LOYALTY API DEPOSIT --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    response = loy_withdrawal(json_vals)
    puts response.to_json
    return response.to_json
end


post '/client_topup' do
    #expected hash {phone_number: xxxxxx}
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # #loy_logger(json_vals, request.path, request.ip)
    puts "----------------- LOYALTY API TOPUP --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals
    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end
    response = loy_topup(json_vals)
    puts response.to_json
    return response.to_json
end

post '/client_collection_bal' do
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # #loy_logger(json_vals, request.path, request.ip)
    puts "----------------- LOYALTY API SETTLEMENT BALANCE CHECK --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    response = client_check_balance(json_vals,'collection')
    puts response.to_json
    return response.to_json
end

post '/client_disbursement_bal' do
    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)
    # #loy_logger(json_vals, request.path, request.ip)
    puts "----------------- LOYALTY API SETTLEMENT BALANCE CHECK --------------------"
    puts "-------------------------- IN COMING PAYLOAD --------------------------"
    puts json_vals

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    response = client_check_balance(json_vals)
    puts response.to_json
    return response.to_json
end


#--------------------------- JARA CLIENT INTEGRATION API -----------------------------------
############################################################################################

post '/jr_register_customer' do
    # expected hash {trnx_id: xxx, amount: x.xx, mobile_no: xxxxxxxxx, nw: MTN|AIR|TIG|, date_of_birth: 20150505,
    # id_type: 'Drivers Lic', id_number: xxxxxxx, id_issue_date: 20160606, id_expiry_date: 20170707,
    # fullname: 'John Doe', alt_number: '233xxxxx'}

    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)

    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts "----------------- JARA PREMIUM CLIENT API REGISTER --------------------"
    puts "------------------------- IN COMING PAYLOAD ---------------------------"
    puts json_vals

    response = register_customer(json_vals)# register(json_vals)
    puts response.to_json
    return response.to_json
end




post '/jr_customer_register' do
    # expected hash {trnx_id: xxx, amount: x.xx, mobile_no: xxxxxxxxx, nw: MTN|AIR|TIG|, date_of_birth: 20150505,
    # id_type: 'Drivers Lic', id_number: xxxxxxx, id_issue_date: 20160606, id_expiry_date: 20170707,
    # fullname: 'John Doe', alt_number: '233xxxxx'}

    request.body.rewind
    json_payload = request.body.read
    json_vals = JSON.parse(json_payload)

    # fml_logger(json_vals, request.path)

    # unless security_check(request, json_vals)
    #     return {status: '401', message: 'Unauthorized'}.to_json
    # end

    puts "----------------- JARA PREMIUM CLIENT API REGISTER --------------------"
    puts "------------------------- IN COMING PAYLOAD ---------------------------"
    puts json_vals

    response = register_customer_invoke(json_vals)# register(json_vals)
    puts response.to_json
    return response.to_json
end

