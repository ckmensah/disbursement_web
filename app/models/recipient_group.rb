#require_relative '../../app/controllers/application_controller'
class RecipientGroup < ActiveRecord::Base
  require 'json'
  require 'faraday'
  require 'bcrypt'
  require 'sendgrid-ruby'
  require 'csv'
  require 'bigdecimal'

  include SendGrid

  belongs_to :client, class_name: "PremiumClient", foreign_key: :client_code
  belongs_to :app_cat, class_name: "ApproversCategory", foreign_key: :approver_cat_id

#      params.require(:recipient_group).permit(:group_desc, :client_code, :approver_cat_id, :approver_code, :status)


  validates :group_desc, presence: true
  validates :client_code, presence: true


  def self.payout(list, client_code, payout_id, trans_type = CREDIT)
    output = Hash.new
    #keys status: true/false, message: 'hey there'
    payout_obj = Payout.find(payout_id)
    client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('id desc')[0]
    logger.info "PAYOUT OBJECT: #{payout_obj.inspect}"
    list.each do |recipient|
      trnx_id = Transaction.genUniqueIDNew(client.acronym)
      mobile_number = recipient.mobile_number
      #recipient.transaction_id = trnx_id
      recipient.transaction_id = trnx_id
      # acct = ClientAcctNumber.find_by(client_code: client_code, status: true, changed_status: false)
      # if acct.nil?
      #   output['status'] = false
      #   output['message'] = "Settlement and disbursement account numbers needed for client."
      #   return output
      # end
      # acct_no = acct.disbursement_acct
      amount = recipient.amount
      nw = recipient.network
      reference = recipient.reference
      bank_code = recipient.bank_code
      recipient_name = recipient.recipient_name
      phone_number = recipient.phone_number

      nw_code = Transaction.get_nw_code(nw)

      if trans_type == CREDIT
        if nw == BANK
          transaction = Transaction.create(
            mobile_number: mobile_number,
            trans_type: "MTC",
            amount: amount,
            network: BANK,
            payout_id: payout_id,
            recipient_id: recipient.id,
            transaction_ref_id: trnx_id,
            trnx_type: BANK,
            status: 0, #about to start first cycle
            reference: reference,
            acronym: client.acronym,
            bank_code: bank_code,
            phone_number: phone_number
          )
        else
          transaction = Transaction.new(
              mobile_number: mobile_number,
              trans_type: DISBURSE,
              payout_id: payout_id,
              recipient_id: recipient.id,
              amount: amount,
              network: nw,
              transaction_ref_id: trnx_id,
              trnx_type: CREDIT,
              status: 0, #about to start first cycle

              acronym: client.acronym
          )
        end

        transaction.save(validate: false)

        logger.info "TRANSACTION OBJECT: #{transaction.inspect}"
        # params = {
        #     account_no: acct_no,
        #     exttrxnid: trnx_id,
        #     return_url: BTW_RETURN_URL,
        #     amount: amount,
        #     wallet_nw: nw_code,
        #     req_type: BTW
        # }

      elsif trans_type == TOPUP
        transaction = Transaction.create(
            mobile_number: mobile_number,
            trans_type: AIRTIME,
            amount: amount,
            network: nw,
            payout_id: payout_id,
            recipient_id: recipient.id,
            transaction_ref_id: trnx_id,
            trnx_type: TOPUP,
            status: 0, #about to start first cycle

            acronym: client.acronym
        )

        logger.info "TRANSACTION OBJECT: #{transaction.inspect}"

      end


      ##########################################################################################33
      ##########################################################################################33

      # Thread.new {
      #
      #
      #
      #
      # response = Transaction.exec_t24_request(params)


      # #nw_type = get_network(nw_code)
      # if response
      #   #{"trans_type":"0210","proc_code":"201040","trands_ref":"1612090839978","account_no":"0120332000018","trxn_amt":"0.1","remote_ref":"FT1624678264","balance":"12.94","error_code":"00"}
      #
      #   transaction.status = 1
      #   transaction.balance = response['balance']
      #   transaction.remote_ref_id = response['remote_ref']
      #   transaction.err_code = response['error_code']
      #   transaction.bank_resp = response['error_desc']
      #   transaction.save
      #
      #   #call amfp function...

      # if response['error_code'] == '00'#and mobile_number != '233247915505'

      # Thread.new {
      logger.info "-----------------------------"
      logger.info "-----------------------------"
      # logger.info "+++++#{trxn_id}++++++++++++++++++++++++++++"
      logger.info "+++++#{trnx_id}++++++++++++++++++++++++++++"
      logger.info "-----------------------------"
      logger.info "-----------------------------"
      Transaction.newMobilePayment(mobile_number, amount, nw_code, CREDIT_MM_CALLBACK_URL, client.client_id, transaction, trans_type, trnx_id, "", reference, bank_code, recipient_name)

      # }
      # else
      #   disb_type = trans_type == TOPUP ? "Top Up" : "Disbursement"
      #   txtmsg = "#{disb_type} of GHS #{amount} to phone number #{mobile_number} failed. Transaction ID: #{transaction.transaction_ref_id}"
      #   phone_number = Recipient.phone_formatter(client.contact_number)
      #   sendmsg(MSGSENDERID, client.contact_number, txtmsg) if phone_number
      # end
      #   else
      #     transaction.status = nil
      #     transaction.save
      #
      #     disb_type = trans_type == TOPUP ? "Top Up" : "Disbursement"
      #     txtmsg = "#{disb_type} of GHS #{amount} to phone number #{mobile_number} failed. Transaction ID: #{transaction.transaction_ref_id}"
      #     phone_number = Recipient.phone_formatter(client.contact_number)
      #     sendmsg(MSGSENDERID, client.contact_number, txtmsg) if phone_number
      #     #sendmsg(MSGSENDERID, mobile_number, txtmsg)
      #
      #   #don't forget to save it
      #
      #   # }
      #   ######################################################################################################
      #   #######################################################################################################
      recipient.disburse_status = true
      recipient.save
    end
    payout_obj.processed = true
    payout_obj.save

    #return good response
    output['status'] = true
    output['message'] = "Payout process successfully initiated."
  end

  def self.newMobilePayment(customer_number, amt, nw_code, callback_url, client_id, transaction, trans_type = DEBIT, trans_id = false, reversing = false, voucher_code = nil)
#trnx_type = PN, CR, DR, NW
    url = AMFP_URL
    endpoint = END_POINT2
    nw_param = Transaction.get_network_param(nw_code)
    #endpoint = "/debitCustomerWallet"

    #might cause problems... TEST IT
    if trans_id && !reversing
      puts "INSIDE IF trans_id && ! reversing"
      trnx_id = trans_id
    elsif reversing
      puts "INSIDE ELSIF reversing"
      trnx_id = Transaction.genUniqueID
    elsif trans_id
      trnx_id = trans_id
    else
      puts "INSIDE ELSE trans_id"
      trnx_id = Transaction.genUniqueID
    end

    #log mobile money
    ts = Time.now.strftime("%Y-%m-%d %H:%M:%S")

    conn = Faraday.new(:url => url, :headers => REQHDR, :ssl => {:verify => false}) do |faraday|
      faraday.response :logger # log requests to STDOUT
      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end


    puts "SENT CALL BACK CREATION BEGUN----------------------"
    n = SentCallback.create!(
        mobile_number: customer_number,
        trnx_type: trans_type,
        trnx_id: trnx_id,
        amount: amt,
        network: nw_param,
        status: 1,
    )

    puts
    puts
    puts
    puts "SENT CALL BACK OBJECT: #{n.inspect}"

    if reversing
      old_trnx_id = trans_id

      n.is_reversal = true
      n.save

      reprocess = TransactionReprocess.where(old_trnx_id: old_trnx_id)[-1] #take the last object
      reprocess.new_trnx_id = trnx_id
      reprocess.status2 = false
      reprocess
      reprocess.save
    end

    p "SENT REQUEST OBJECT: #{n.inspect}"

    if trans_type == DEBIT
      # if trans_type is debit, then it means customer was making a deposit
      p "A DEBIT TO MOBILE MONEY BEGUN..."

      # transaction = Transaction.create(
      #     mobile_number: customer_number,
      #     transaction_ref_id: trnx_id,
      #     trans_type: transaction_type,
      #     trnx_type: CREDIT, #credit with respect to his bank account
      #     amount: amt,
      #     network_code: get_network(nw_code),
      #     status: 0
      #
      # #trans_step: AM_WALLET_DR_STARTED
      # )

      transaction.transaction_ref_id = trnx_id
      transaction.trnx_type = CREDIT
      transaction.status = false
      transaction.save

      p "SUMMARY OBJECT: #{transaction.inspect}"
    end

    if trans_type == DEBIT
      ref = DR_REF
    elsif trans_type == CREDIT
      ref = CR_REF
    elsif trans_type == TOPUP
      ref = ATP_REF
    else
      ref = REF
    end


    puts
    puts
    puts "THIS IS THE NETWORK PARAM: #{nw_param}"
    puts
    puts


    if nw_code == VODAFONE_CODE
      payload = {
          :voucher_code => voucher_code,
          :customer_number => customer_number,
          :reference => ref,
          :amount => amt,
          :exttrid => trnx_id,
          :nw => nw_param,
          :trans_type => trans_type,
          :callback_url => callback_url,
          :ts => ts,
          :client_id => client_id,

      }
    else
      payload = {
          :customer_number => customer_number,
          :reference => ref,
          :amount => amt,
          :exttrid => trnx_id,
          :nw => nw_param,
          :trans_type => trans_type,
          :callback_url => callback_url,
          :ts => ts,
          :client_id => client_id,
      }
    end


    json_payload = JSON.generate(payload)
    msg_endpoint = "#{json_payload}"

    puts
    puts msg_endpoint
    puts

    signature = Transaction.computeSignature(SECRETKEY, msg_endpoint)

    begin
      res = conn.post do |req|
        req.url endpoint
        req.options.timeout = 30 # open/read timeout in seconds
        req.options.open_timeout = 30 # connection open timeout in seconds
        req["Authorization"] = "#{CLIENT_KEY}:#{signature}"
        req.body = json_payload
      end

      puts
      puts "Response: #{res.body} OF TYPE: #{res.body.class}"

      #p body["resp_code"] #real response


      puts "MOBILE MONEY PAYMENT----------------------------------"
      puts res.status
      puts "type: #{res.status.class}"

      puts
        #puts encoded_payload
    rescue Faraday::SSLError

      puts
      puts "There was a problem sending the https request..."
      puts
    rescue Faraday::TimeoutError

      puts "Connection timeout error"

    rescue
      puts "Error"
    end
  end
end
