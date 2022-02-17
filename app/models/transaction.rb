class Transaction < ActiveRecord::Base
  ###########FROM USSD########################3
  #tigo constants
  require 'json'
  require 'faraday'
  require 'bcrypt'
  require 'sendgrid-ruby'
  require 'csv'
  require 'bigdecimal'

  include SendGrid
  include BCrypt

  attr_accessor :mobile_num, :netwk, :amt, :rec_name, :client_code, :disburse_status


  #first ussd body
  #FIRST_BODY = "200"


  # CONN = Faraday.new(:url => T24_URL, :ssl => {:verify => false}) do |faraday|
  #   faraday.response :logger                  # log requests to STDOUT
  #   faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  # end


  self.primary_key = :transaction_ref_id
  belongs_to :user
  belongs_to :payout, class_name: "Payout", foreign_key: :payout_id
  belongs_to :recipient, class_name: "Recipient", foreign_key: :recipient_id
  has_one :a_client, through: :recipient, foreign_key: :client_code
  has_one :callback_resp, class_name: 'CallbackResp', foreign_key: :mm_trnx_id
  has_many :user_client, class_name: "TransactionReprocess", foreign_key: :old_trnx_id


  validates :mobile_num, presence: true, allow_blank: false, :numericality => {greater_than_or_equal_to: 0, allow_nil: true}
  validates :rec_name, presence: true, allow_blank: false
  validates :netwk, presence: true, allow_blank: false
  # validates :reference, presence: {message: "Your Reference cannot be less than 10 characters or more than 50."}, allow_blank: false, length: {:maximum => 50, :minimum=> 10}
  validates :amt, presence: true, allow_blank: false, :numericality => {greater_than_or_equal_to: 0, allow_nil: true}

  def self.per_page
    30
  end

  def self.hash_pin(pin)
    hash = BCrypt::Password.create(pin.strip, :cost => 4).to_s
    puts "Generated hash: #{hash}"

    return hash
  end

  def self.verify_pin(pin, hashed_pin)
    r_bool = BCrypt::Password.new(hashed_pin) == pin
    puts "PIN check result: #{r_bool}"

    return r_bool
  end


  def self.get_current_balance(service_id, secret_key, client_key)
    url_endpoint = CHECK_BAL_END_POINT
    api_params = {
        service_id: service_id
    }

    api_params = api_params.to_json

    puts "API PARAMS FOR DISBURSEMENT CHECK BALANCE: #{api_params}"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    logger.info "API PARAMS FOR DISBURSEMENT CHECK BALANCE: #{api_params}"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    signature = computeSignature(secret_key, api_params)
    res = CHECK_BAL_CONN.post do |req|
      req.url url_endpoint
      req["Authorization"] = "#{client_key}:#{signature}"
      req.options.timeout = 30 # open/read timeout in seconds
      req.options.open_timeout = 30 # connection open timeout in seconds
      req.body = api_params
    end
    puts
    puts "Result from TEST: #{res.body}"
    begin
      resp = JSON.parse(res.body)
    rescue JSON::ParserError
      resp = {}
      puts "----------------------------------------there's an error with the json--------------------"
      puts res.body.inspect
    end
    logger.info "#{resp}"
    resp
  end

  def self.titling(str)
    str_list = str.split

    str_list.map {|word| word.capitalize
    word.split("-").map {|w| w.capitalize}.join("-")
    }.join(" ")
  end

  def self.name_search(name)
    #where("firstname LIKE "+"'%#{val}%'" +" OR lastname LIKE "+ "'%#{val}%'",{:name => name})
    if name.strip == ""
      ""
    else
      n = titling(name)
      name = "%#{n}%"

      # where("(firstname LIKE :name OR lastname LIKE :name OR CONCAT(firstname,' ',lastname) LIKE :name) AND changed_status = false AND subscribed = true",
      #       {:name =>name})
      " recipients.recipient_name iLIKE '#{name}' "
    end
  end

  def self.doPayout(list, client_code, trans_type = CREDIT)
    output = Hash.new

    client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('id desc')[0]

    list.each do |recipient|
      trnx_id = Transaction.genUniqueIDNew(client.acronym)
      mobile_number = recipient.mobile_number

      amount = recipient.amount
      nw = recipient.network
      reference = recipient.reference
      # sort_code = recipient.sort_code
      # swift_code = recipient.swift_code
      bank_code = recipient.bank_code
      recipient_name = recipient.recipient_name
      phone_number = recipient.phone_number

      nw_code = Transaction.get_nw_code(nw)

      check_recipient_trans = Transaction.where("recipient_id=?", recipient.id).exists?

      if check_recipient_trans
        logger.info "Recipient Exists::::#{recipient.inspect}"
      elsif !check_recipient_trans
        if trans_type == CREDIT
          if nw == BANK
            transaction = Transaction.create(
              mobile_number: mobile_number,
              trans_type: "MTC",
              amount: amount,
              network: BANK,
              payout_id: nil,
              recipient_id: recipient.id,
              transaction_ref_id: trnx_id,
              trnx_type: BANK,
              status: 0, #about to start first cycle
              reference: reference,
              acronym: client.acronym,
              # sort_code: sort_code,
              bank_code: bank_code,
              phone_number: phone_number
              # recipient_name: recipient_name
            )
          else
            transaction = Transaction.new(
              mobile_number: mobile_number,
              trans_type: DISBURSE,
              payout_id: nil,
              recipient_id: recipient.id,
              amount: amount,
              network: nw,
              transaction_ref_id: trnx_id,
              trnx_type: CREDIT,
              status: 0, #about to start first cycle
              reference: reference,

              acronym: client.acronym
            )
          end

          transaction.save(validate: false)

          updated_recipient = Recipient.where(id: recipient.id).update_all(disburse_status: true, transaction_id: trnx_id)
          logger.info "TRANSACTION OBJECT: #{transaction.inspect}"

          logger.info "RECIPIENT OBJECT: #{updated_recipient.inspect}"


        elsif trans_type == TOPUP
          transaction = Transaction.create(
              mobile_number: mobile_number,
              trans_type: AIRTIME,
              amount: amount,
              network: nw,
              payout_id: nil,
              recipient_id: recipient.id,
              transaction_ref_id: trnx_id,
              trnx_type: TOPUP,
              status: 0, #about to start first cycle
              reference: reference,
              acronym: client.acronym
          )

          logger.info "TRANSACTION OBJECT: #{transaction.inspect}"

        end

          Transaction.newMobilePayment(mobile_number, amount, nw_code, CREDIT_MM_CALLBACK_URL, client.client_id, transaction, trans_type, trnx_id, "", reference, bank_code, recipient_name)
      else

      end

      # recipient.disburse_status = true
      # recipient.save
    end
    #return good response
    output['status'] = true
    output['message'] = "Payout process successfully initiated."
  end


  def self.phone_search(phone_number)
    if phone_number.blank?
      ""
    else
      phone = "%#{phone_number}%"
      "transactions.mobile_number iLIKE '#{phone}'"
    end
  end

  def self.search_date(start = "", ended = "")
    if not start.blank? and not ended.blank?
      " transactions.created_at BETWEEN '#{start} 00:00:00.0' AND '#{ended} 23:59:59.9999' "
    elsif not start.blank?
      " transactions.created_at > '#{start} 00:00:00.0' "
    elsif not ended.blank?
      " transactions.created_at < '#{ended} 23:59:59.9999' "
    else
      ""
    end
  end

  def self.trans_id_search(id)
    trans_id = "#{id}"
    "transaction_ref_id = '#{trans_id}'"
  end

  def self.client_code_search(client_code)

    "recipients.client_code = '#{client_code}'"
  end


  def self.to_csv(client_code, page, perpage, search_str = nil, options = {})
    # column_names = %w{firstname lastname mobile_number amount trans_type account_number network_code final_status created_at }
    #
    #     column_names = %w{recipient_name mobile_number amount trans_type created_at
    # network transaction_ref_id
    # err_code nw_resp voucher_code}

    column_names = %w{created_at trnx_id transaction_ref_id company_name network mobile_number amount
err_code nw_resp }

    headers = %w{Date Telco_ID Trans_ID Client Network phone_number Amount Status Description}

    if page and perpage
      page = page.to_i
      perpage = perpage.to_i

      off = perpage * (page - 1)

      logger.info "THE LIMIT VALUE #{perpage}"

      CSV.generate(options) do |csv|
        csv << headers
        joiner(client_code).where(search_str).each do |request|
          row = request.attributes.values_at(*column_names)
          #row[18] = request.final_status ? 'Complete Success' : 'Failure'
          #row[22] = request.manually_closed ? 'Closed by User' : 'N/A'
          if row[7] == "000" || row[7] == "200"
            row[7] = "Success"
          elsif row[7] == "001"
            row[7] = "Failed"
          else
            row[7] = "Pending"
          end

          #row[4].strftime("%F %R")
          row[0] = row[0].strftime("%F %R")
          # if request.is_reversal
          #   row[23] = 'Reprocessed Successfully'
          # elsif request.is_reversal.nil?
          #   row[23] = 'N/A'
          # else
          #   row[23] = 'Reprocess Failed'
          # end
          csv << row
        end
      end

    else
      CSV.generate(options) do |csv|
        csv << headers
        joiner(client_code).where(search_str).each do |request|
          row = request.attributes.values_at(*column_names)
          # row[18] = request.final_status ? 'Complete Success' : 'Failure'
          # row[22] = request.manually_closed ? 'Closed by User' : 'N/A'

          if row[7] == "000" || row[7] == "200"
            row[7] = "Success"
          elsif row[7] == "001"
            row[7] = "Failed"
          else
            row[7] = "Pending"
          end

          #row[4].strftime("%F %R")
          row[0] = row[0].strftime("%F %R")

          # if request.is_reversal
          #   row[23] = 'Reprocessed Successfully'
          # elsif request.is_reversal.nil?
          #   row[23] = 'N/A'
          # else
          #   row[23] = 'Reprocess Failed'
          # end

          csv << row
        end
      end
    end

  end

  def self.to_admin_csv(page, perpage, search_str = nil, options = {})
    # column_names = %w{firstname lastname mobile_number amount trans_type account_number network_code final_status created_at }

    #     column_names = %w{recipient_name mobile_number amount trans_type created_at
    # network transaction_ref_id
    # err_code nw_resp voucher_code }

    column_names = %w{created_at trnx_id transaction_ref_id company_name network mobile_number amount
err_code nw_resp }

    headers = %w{Date Telco_ID Trans_ID Client Network phone_number Amount Status Description}

    if page and perpage
      page = page.to_i
      perpage = perpage.to_i

      logger.info "THE ADMIN LIMIT VALUE #{perpage}"

      off = perpage * (page - 1)

      CSV.generate(options) do |csv|
        csv << headers
        joiner_not.where(search_str).each do |request|
          row = request.attributes.values_at(*column_names)
          #logger.info "CSV VALUES #{row.inspect}"
          logger.info "CSV 0 #{row[0].inspect}"
          logger.info "CSV 1 #{row[1].inspect}"
          logger.info "CSV 2 #{row[2].inspect}"
          logger.info "CSV 3 #{row[3].inspect}"
          logger.info "CSV 4 #{row[4].inspect}"
          logger.info "CSV 5 #{row[5].inspect}"
          logger.info "CSV 6 #{row[6].inspect}"
          logger.info "CSV 7 #{row[7].inspect}"
          logger.info "CSV 8 #{row[8].inspect}"
          logger.info "CSV 9 #{row[9].inspect}"
          #row[18] = request.final_status ? 'Complete Success' : 'Failure'
          #row[22] = request.manually_closed ? 'Closed by User' : 'N/A'
          #
          if row[7] == "000" || row[7] == "200"
            row[7] = "Success"
          elsif row[7] == "001"
            row[7] = "Failed"
          else
            row[7] = "Pending"
          end

          #row[4].strftime("%F %R")
          row[0] = row[0].strftime("%F %R")

          # if request.is_reversal
          #   row[23] = 'Reprocessed Successfully'
          # elsif request.is_reversal.nil?
          #   row[23] = 'N/A'
          # else
          #   row[23] = 'Reprocess Failed'
          # end
          csv << row
        end
      end

    else
      CSV.generate(options) do |csv|
        csv << headers
        joiner_not.where(search_str).each do |request|
          row = request.attributes.values_at(*column_names)

          if row[7] == "000" || row[7] == "200"
            row[7] = "Success"
          elsif row[7] == "001"
            row[7] = "Failed"
          else
            row[7] = "Pending"
          end

          #row[4].strftime("%F %R")
          row[0] = row[0].strftime("%F %R")
          logger.info "EXL VALUES #{row.inspect}"
          # row[18] = request.final_status ? 'Complete Success' : 'Failure'
          # row[22] = request.manually_closed ? 'Closed by User' : 'N/A'
          # if request.is_reversal
          #   row[23] = 'Reprocessed Successfully'
          # elsif request.is_reversal.nil?
          #   row[23] = 'N/A'
          # else
          #   row[23] = 'Reprocess Failed'
          # end


          csv << row
        end
      end
    end

  end

  def self.reversed
    where("is_reversal IS NOT NULL")
  end

  def self.joiner_not

    #     joins(:recipient, :callback_resp, :a_client).select('transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
    # transactions.trans_type, transactions.created_at,
    # transactions.network, transactions.status,err_code,trnx_type,
    #  recipients.recipient_name, is_reversal,callback_resps.trnx_id,premium_clients.company_name').where("recipients.changed_status = false AND premium_clients.status = true AND premium_clients.changed_status = false")


    joins("LEFT JOIN recipients on transactions.recipient_id = recipients.id LEFT JOIN callback_resps on transactions.transaction_ref_id = callback_resps.mm_trnx_id
    LEFT JOIN premium_clients on recipients.client_code = premium_clients.client_code").
        where("recipients.changed_status = false AND premium_clients.status = true AND premium_clients.changed_status = false")
        .select("transactions.recipient_id, transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount, transactions.trans_type, transactions.created_at,
     transactions.network, transactions.status,transactions.err_code,transactions.trnx_type,transactions.is_reversal, recipients.recipient_name,callback_resps.trnx_id,premium_clients.company_name")

  end

  #   def self.joiner_not
  #     joins(:recipient).select('transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
  # transactions.trans_type, transactions.created_at,
  # transactions.network, transactions.status,err_code,trnx_type,
  #  recipients.recipient_name, is_reversal').where("recipients.changed_status = false")
  #   end

  def self.joiner(cur_user)
    #     joins(:recipient, :callback_resp, :a_client).select('transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
    # transactions.trans_type, transactions.created_at,
    # transactions.network, transactions.status,err_code,trnx_type,
    #  recipients.recipient_name, is_reversal,callback_resps.trnx_id, premium_clients.company_name').where("recipients.changed_status = false AND recipients.status = true AND recipients.disburse_status = true AND recipients.client_code = '#{cur_user}' AND premium_clients.status = true AND premium_clients.changed_status = false") #.where("recipients.client_code = '#{cur_user}'").where("premium_clients.status = true").where("premium_clients.changed_status = false")
    #

    joins("LEFT JOIN recipients on transactions.recipient_id = recipients.id LEFT JOIN callback_resps on transactions.transaction_ref_id = callback_resps.mm_trnx_id
    LEFT JOIN premium_clients on recipients.client_code = premium_clients.client_code").where("recipients.changed_status = false AND recipients.status = true AND recipients.disburse_status = true AND recipients.client_code = '#{cur_user}' AND premium_clients.status = true AND premium_clients.changed_status = false")
        .select("transactions.recipient_id, transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount, transactions.trans_type, transactions.created_at,
     transactions.network, transactions.status,transactions.err_code,transactions.trnx_type,transactions.is_reversal,recipients.recipient_name, callback_resps.trnx_id, premium_clients.company_name")

  end

  #   def self.joiner(client_code)
  #     joins("LEFT JOIN recipients ON transactions.recipient_id = recipients.id
  # LEFT JOIN premium_clients ON recipients.client_code = premium_clients.client_code
  # LEFT JOIN callback_resps ON transactions.transaction_ref_id = callback_resps.mm_trnx_id").select(
  #         "transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
  # transactions.trans_type, transactions.created_at,
  # transactions.network, transactions.status,err_code,trnx_type,
  #  recipients.recipient_name, is_reversal,callback_resps.trnx_id,premium_clients.company_name").where("recipients.changed_status = ?", false).where("recipients.client_code = ?",client_code)
  #   end

  #   def self.joiner_not
  #     joins("LEFT JOIN recipients ON transactions.recipient_id = recipients.id
  # LEFT JOIN premium_clients ON recipients.client_code = premium_clients.client_code
  # LEFT JOIN callback_resps ON transactions.transaction_ref_id = callback_resps.mm_trnx_id").select(
  #         "transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
  # transactions.trans_type, transactions.created_at,
  # transactions.network, transactions.status,err_code,trnx_type,
  #  recipients.recipient_name, is_reversal,callback_resps.trnx_id,premium_clients.company_name").where("recipients.changed_status = ?", false).where("recipients.status = ?", true)
  #
  # #         where(
  # #         "person_infos.status2 = false AND person_pref_jobs.status1 = true AND prev_edu_details.status1 = true AND prev_work_details.status1 = true AND person_code NOT IN (SELECT person_id from person_engaged_masters where status1 = true)").group(
  # #         "person_code, record_type_id, gender, dob, work_titles1.title, concat(surname_name, ' ', first_name, ' ', other_names), person_pref_jobs.work_title_id, person_infos.created_at
  # # ")
  #   end

  # LEFT JOIN prev_work_details ON person_infos.person_code = prev_work_details.person_id
  # LEFT JOIN edu_qualifs ON edu_qualifs.id = prev_edu_details.certificate_id
  # LEFT JOIN work_titles AS work_titles1 ON work_titles1.id = person_pref_jobs.work_title_id
  # LEFT JOIN work_titles AS work_titles2 ON work_titles2.id = prev_work_details.work_title_id

  def self.active
    where(changed_status: false)
  end

  # def self.bill_payment
  #   where("trans_type = 'BIL'")
  # end


  def self.trans_type_search(trans_type)
    "trans_type = '#{trans_type}'"
  end

  def self.network_search(network)
    "recipients.network = '#{network}'"
  end

  def self.status_search(status_code)

    if status_code == "pending"
      "transactions.err_code IS NULL"
    elsif status_code == "000" || status_code == "001"
      "transactions.err_code = '#{status_code}'"
    else
      ""
    end

  end

  def self.handle_amfp_reversal(mobile_number, amount, nw_code, trans_obj, trans_id, user_id)

    new_trans_id = self.genUniqueID
    acct_no = trans_obj.account_number
    reversal = TransactionReprocess.create(
        old_trnx_id: trans_id,
        new_trnx_id: new_trans_id,
        amount: amount,
        # acct_no: acct_no,
        auto: false,
        user_id: user_id
    )

    trans_obj.is_reversal = false #reversal has started. It's no more null
    trans_obj.save

    #newMobilePayment(MERCHANT_NUMBER_ANB, mobile_number, amount, nw_code, CREDIT_MM_CALLBACK_URL,CLIENT_ID, trans_obj, CREDIT, trans_id, reversing=true)

  end


  def self.genUniqueID
    time = Time.new
    randval = rand(999).to_s.center(3, rand(9).to_s)
    uniqcode = time.strftime("%y%m%d%H%M").to_s + randval.to_s

    return DISBURSE_ID_PRE + uniqcode
  end

  def self.genUniqueIDNew(client_acronym)
    time = Time.new
    randval = rand(99).to_s.center(2, rand(9).to_s)
    uniqid = ""
    public_id = loop do
      puts "======================================="
      puts "====== Generating next unique ID ======"
      uniqid = "#{DISBURSE_ID_PRE}" + "#{client_acronym}" + time.strftime("%S%d%L%H%M").to_s + randval.to_s
      puts "========== ID: #{uniqid} =============="
      puts

      break uniqid unless Transaction.exists?(transaction_ref_id: uniqid)
    end
  end

  def self.newMobilePayment(customer_number, amt, nw_code, callback_url, client_id, transaction, trans_type, trans_id, voucher_code, reference, bank_code, recipient_name)
    #trnx_type = PN, CR, DR, NW
    url = AMFP_URL
    endpoint = END_POINT
    client = PremiumClient.where(client_id: client_id, status: true).active.order('updated_at desc').first
    client_key = client.client_key
    client_name = client.company_name
    puts "CLIENT ID: #{client_id}"
    puts "CLIENT KEY: #{client_key}"
    logger.info "CLIENT ID: #{client_id}"
    logger.info "CLIENT KEY: #{client_key}"
    secret_key = client.secret_key
    puts "SECRET KEY: #{secret_key}"
    logger.info "SECRET KEY: #{secret_key}"

    client_acronymm = client.acronym
    puts "CLIENT ACRONYM: #{client_acronymm}"
    logger.info "CLIENT ACRONYM: #{client_acronymm}"

    if [AIRTEL_PARAM, TIGO_PARAM, VODA_PARAM, MTN_PARAM, BANK_PARAM].include? nw_code
      nw_param = nw_code
    else
      nw_param = get_network_param(nw_code)
    end
    puts
    puts
    puts "THIS IS THE NETWORK PARAM: #{nw_param}"
    puts
    puts


    ts = Time.now.strftime("%Y-%m-%d %H:%M:%S")

    conn = Faraday.new(:url => url, :headers => REQHDR, :ssl => {:verify => false}) do |faraday|
      faraday.response :logger # log requests to STDOUT
      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end


    puts "SENT CALL BACK CREATION BEGUN----------------------"
    n =
      if nw_code == BANK_CODE
      SentCallback.create(
        mobile_number: customer_number,
        trnx_type: BANK,
        trnx_id: transaction.id,
        amount: amt,
        network: nw_param,
        status: 1,
        )
      else
        SentCallback.create(
          mobile_number: customer_number,
          trnx_type: trans_type,
          trnx_id: transaction.id,
          amount: amt,
          network: nw_param,
          status: 1,
          )
        end

    p "SENT REQUEST OBJECT: #{n.inspect}"
    logger.info "+++++++++++++++++++++#{transaction.inspect}++++++++++++++++++++++++++++++++++++++++"

    puts
    puts
    puts "THIS IS THE NETWORK PARAM: #{nw_param}"
    puts
    puts
    acronym = client.acronym

    # if trans_type == DEBIT
    #   ref = DR_REF
    # elsif trans_type == CREDIT
    #   ref = CR_REF
    # elsif trans_type == TOPUP
    #   ref = ATP_REF
    # else
    #   ref = REF
    # end
    #
    # ref = acronym + ref

    ref = reference

    if nw_code == VODAFONE_CODE
      payload = {
          :voucher_code => voucher_code,
          :customer_number => customer_number,
          :reference => ref,
          :amount => amt,
          :exttrid =>transaction.id,
          :nw => nw_param,
          :trans_type => trans_type,
          :callback_url => callback_url,
          :ts => ts,
          :client_id => client_id,
      }
    elsif nw_code == BANK_CODE
      payload = {
        :customer_number => customer_number,
        :reference => ref,
        :amount => amt,
        :exttrid => transaction.id,
        :nw => nw_param,
        :trans_type => "MTC",
        :callback_url => callback_url,
        :ts => ts,
        :service_id => client_id,
        :bank_code => bank_code,
        :recipient_name => recipient_name
      }
    else
    payload = {
      :customer_number => customer_number,
      :reference => ref,
      :amount => amt,
      :exttrid => transaction.id,
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

    logger.info "############################################################################################################################################"
    logger.info "############################################################################################################################################"
    logger.info "############################################################################################################################################"
    logger.info "\n\n\n #################### payload description for either bank or momo. the entire endpoint payload  #{msg_endpoint} \n\n\n"
    logger.info "############################################################################################################################################"
    logger.info "############################################################################################################################################"

    puts

    signature = computeSignature(secret_key, msg_endpoint)

    begin
      res = conn.post do |req|
        req.url endpoint
        req.options.timeout = 30 # open/read timeout in seconds
        req.options.open_timeout = 30 # connection open timeout in seconds
        req["Authorization"] = "#{client_key}:#{signature}"
        req.body = json_payload
      end

      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"
      logger.info "->->->->->->->->->->->->->->"

      puts res
      puts "Response: #{res.body} OF TYPE: #{res.body.class}"
      logger.info "Response: #{res.body} OF TYPE: #{res.body.class}"

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




  def self.import_contacts(file, client_code, user_id, reference)

    positive_numbers = /^[+]?([0-9]+(?:[\.][0-9]*)?|\.[0-9]+)$/
    positives = /\d+/
    letters_only = /^[A-Za-z\s]+$/

    @recipients = []

    @client_info = PremiumClient.where(status: true, changed_status: false, client_code: client_code).order('created_at desc').last
    client_name = @client_info.sender_id

    d = DateTime.now
    d = d.strftime("%d-%m-%Y_%H:%M:%S")

    if !reference.empty? || !reference.blank?
      ref = reference
    else
      ref = "Payment from #{client_name}"
    end

    _file = file
    fileContentType = _file.content_type
    acceptContentType = "application/vnd.ms-excel"
    acceptContentType1 = "text/csv"
    logger.info "Original file #{file.inspect}"
    logger.info "Assigned file #{_file.inspect}"
    networks = ['MTN', 'AIR', 'TIG', 'VOD']

    the_msg = 0
    readVal = file.read
    logger.info "Read value #{readVal.inspect}"
    logger.info "Content Type #{fileContentType}"
    logger.info "Assigned Read value #{readVal.inspect}"
    fname = file.original_filename
    _filename = file.tempfile
    final_file_path = "./public/csv_files/#{@client_info.acronym}_#{d}_#{fname}"
    # reference = gets.chomp
    # _reference = reference
    if  acceptContentType  == fileContentType || acceptContentType1 == fileContentType # if acceptContentType == fileContentType


      check_file_existence = CsvUpload.where(user_id: user_id, client_code: client_code, file_name: fname).exists?

      logger.info "File exists? #{check_file_existence.inspect}"

      if check_file_existence
        the_msg = 9
      elsif !check_file_existence
        File.open("#{final_file_path}", 'wb') do |f|
          #f.write(_filename.read)
          f.write(readVal)
        end

        save_csv_file = CsvUpload.create(user_id: user_id, client_code: client_code, file_name: fname, file_path: final_file_path, reference: reference)
        save_csv_file.save

        @upload_id = CsvUpload.where(user_id: user_id, client_code: client_code, file_name: fname, file_path: final_file_path).order('created_at desc')[0]
        csv_upload_id = @upload_id.id

        # csv_upload_id = save_csv_file.id


        logger.info "Saved #{save_csv_file.inspect}"
        logger.info "Saved ID #{csv_upload_id}"
        logger.info "Saved User ID #{save_csv_file.user_id}"
        logger.info "Saved Client Code #{save_csv_file.client_code}"
        logger.info "Value from file\n#{readVal.inspect}"
        logger.info "Value from file\n#{_filename.inspect}"


        readVal = readVal.split(',').map {|val| val.strip}
        last = readVal[5].split("\n")
        last[0] = last[0].strip
        if last[0] == "alert_number\r"
          last[0] = "alert_number"
        end
        logger.info "First: #{readVal[0].inspect}"
        logger.info "Second: #{readVal[1].inspect}"
        logger.info "Third: #{readVal[2].inspect}"
        logger.info "Fourth: #{readVal[3].inspect}"
        logger.info "Fifth: #{readVal[4].inspect}"
        logger.info "Sixth: #{readVal[5].inspect}"
        logger.info "Last: #{last.inspect}"
        logger.info "HERE IS THE READVAL THINGY #{readVal.inspect}"


        if readVal[0] == "recipient_name" && readVal[1] == "mobile_number" && readVal[2] == "network" && readVal[3] == "amount" && readVal[4] == "bank_code" && last[0] == "alert_number"
          CSV.foreach(file.path, headers: true) do |row|
            logger.info 'This is it-----'
            logger.info row.inspect

            if row["mobile_number"].present? && row["network"].present? && row["amount"].present? && row["recipient_name"].present?
              unless row["amount"].match(positive_numbers)
                the_msg = 8
              end
              name = User.titling(row['recipient_name']) #name
              logger.info "NAME: #{name}"

              if row["network"] != "BNK" && row["mobile_number"].scan(/\D/i).length == 0
                if !row["mobile_number"].match(positive_numbers)
                  the_msg = 4
                else
                  number = phone_formatter(row["mobile_number"])
                  number = 0 unless number
                  network = row['network'].upcase

                  unless networks.include?(network)
                    #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "Unknown network")
                    the_msg = 1
                    return the_msg
                  end

                  #check recipient name
                  #
                  if row["recipient_name"].blank?
                    #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "No recipient name")

                    return the_msg = 3
                  end


                  if row["recipient_name"].match(positive_numbers) #if !row["recipient_name"].match(letters_only)
                    #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "No recipient name")
                    return the_msg = 3
                  end

                  if reference.blank?

                  elsif reference.length < 10 || reference.length > 25
                    return the_msg = 10
                  end

                  if number.length == 12
                    @recipients << Recipient.new(recipient_name: name, mobile_number: number, network: network, csv_uploads_id: csv_upload_id, amount: row['amount'], disburse_status: false, client_code: client_code, user_id: user_id, reference: ref )
                  else
                    the_msg = 4
                    #Recipient.create(recipient_name: name, mobile_number: number, network: network, disburse_status: false, client_code: client_code, status: false, fail_reason: "Wrong mobile number")
                  end

                end

              elsif row["network"] == "BNK"
                if row["bank_code"].present? && row["alert_number"].present?
                  mob_num = row["mobile_number"]
                  fone_num = phone_formatter(row["alert_number"])
                  if fone_num.blank? || !fone_num.match(positive_numbers)
                    return the_msg = 12
                  end
                  # mob_num = mob_num.to_f.to_i.to_s
                  mob_num = mob_num.to_s
                  logger.info " the mob is #{mob_num} @@@@@@@@@@@"
                  @recipients << Recipient.new(recipient_name: name, mobile_number: mob_num, network: row["network"], csv_uploads_id: csv_upload_id, amount: row['amount'], disburse_status: false, client_code: client_code, bank_code:row['bank_code'], user_id: user_id, reference: ref, phone_number: fone_num )
                else
                  the_msg = 11
                end
                # unless row["amount"] >= 1
                #   the_msg = 12
                # end
              else
                the_msg = 5
                #Recipient.create(recipient_name: name, mobile_number: number, network: network, disburse_status: false, client_code: client_code, status: false, fail_reason: "Wrong mobile number format")
              end
            else
              the_msg = 6
              #Recipient.create(recipient_name: name, mobile_number: number, network: network, disburse_status: false, client_code: client_code, status: false, fail_reason: "Invalid row, missing parameters")
            end
          end
        else
          return "2"
        end
      end
      logger.info "**********************************************************"
      logger.info "#{@recipients.inspect}"
      logger.info "#{the_msg}"
      logger.info "**********************************************************"


      if the_msg == 0
        Recipient.import @recipients
        @recipients.clear
      else
        @recipients.clear
      end
    else
      return "7"
    end
    @recipients.clear
    return the_msg
  end

  def self.get_nw_code(network)
    case network
    when AIRTEL;
      return AIRTEL_CODE
    when MTN;
      return MTN_CODE
    when TIGO;
      return TIGO_CODE
    when VODAFONE;
      return VODAFONE_CODE
    when BANK;
      return BANK_CODE
    else
      false
    end
  end

  def self.phone_formatter(number)
    #changes customer number format to match 233247876554 || accountnumber
    the_match = /\d+/

    if number[0] == '0'
      num = number[1..number.size]
      "233" + num
    elsif number[0] == '+'
      number[1..number.size]
    elsif number[0..2] == '233'
      number
    elsif number[0] == '2' or number[0] == '5'
      '233' + number
    else
      false
    end
  end

  def self.acount_formatter(acct_number)
    the_match = /\d+/
    if acct_number.match(the_match) && acct_number.length >= 12
      acct_number
    end
  end

  def self.get_network_param(code)
    "THIS IS THE CODE: #{code}"
    case code
    when MTN_CODE;
      return MTN_PARAM
    when VODAFONE_CODE;
      return VODA_PARAM
    when TIGO_CODE;
      return TIGO_PARAM
    when AIRTEL_CODE;
      return AIRTEL_PARAM
    when BANK_CODE;
      return BANK_PARAM
    else
      false
    end
  end

  # def self.sendmsg(senderID, receipient, txtmsg)
  #     strUser="tester"
  #     strPass="foobar"
  #     strIP= "184.173.139.74"#"localhost"
  #     strHostPort="13013"
  #     ####http://184.173.139.74:8198
  #
  #     time=Time.new
  #     msgID=strtm=time.strftime("%y%m%d%H%M%S%L")
  #
  #     strDlrUrl="http://#{strIP}:#{strHostPort}/Dlr?msgID=#{msgID}&smsc_reply=%A&sendsms_user=%n&ani=%P&bni=%p&dlr_val=%d&smsdate=%t&smscid=%i&charset=%C&mclass=%m&bmsg=%b&msg=%a"
  #
  #     uri=URI("http://#{strIP}:#{strHostPort}/cgi-bin/sendsms")
  #     uri.query=URI.encode_www_form([["username", strUser], ["password", strPass], ["charset", "UTF-8"], ["to", receipient], ["dlr-mask", "31"], ["from", senderID], ["text", txtmsg], ["smsc","airtel"],["dlr-url", strDlrUrl]])
  #
  #     res = Net::HTTP.get_response(uri)
  #     puts res.code
  #     puts res.body
  #
  #
  #     p resp=Msg.create(msg_id: senderID, phone_number: receipient, msg: txtmsg, resp_code: res.code, resp_desc: res.body, status: 1)
  # end

  def self.get_sender_id(client_code)
    client = PremiumClient.where(client_code: client_code).active.order('id asc').last


    sender_id = client.sender_id

  end

  def self.sendmsg(recipient_number, message_body, client_code, api_key, src = "API")
    puts "CLIENT CODE: #{client_code}"
    logger.info "CLIENT CODE: #{client_code}"


    client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('id desc').first
    client_id=client.client_id

    client = PremiumClient.where(client_id: client_id, status: true).active.order('updated_at desc').first
    client_key = client.client_key
    puts "CLIENT ID: #{client_id}"
    puts "CLIENT KEY: #{client_key}"
    logger.info "CLIENT ID: #{client_id}"
    logger.info "CLIENT KEY: #{client_key}"
    secret_key = client.secret_key
    puts "SECRET KEY: #{secret_key}"
    logger.info "SECRET KEY: #{secret_key}"



    # client = PremiumClient.where(client_code: client_code).active.order('created_at desc').last
    # client_id = client.client_id
    # puts "CLIENT ID: #{client_id}"
    # logger.info "CLIENT ID: #{client_id}"
    # client_key = client.client_key
    # puts "CLIENT KEY: #{client_key}"
    # logger.info "CLIENT KEY: #{client_key}"
    # secret_key = client.secret_key
    # puts "SECRET KEY: #{secret_key}"
    # logger.info "SECRET KEY: #{secret_key}"
    api_key = client.sms_key
    puts "API KEY: #{api_key}"
    logger.info "API KEY: #{api_key}"

    sender_id = get_sender_id(client_code)

    url_endpoint = SMS_END_POINT
    api_params = {
        sender_id: sender_id,
        recipient_number: recipient_number,
        msg_body: message_body,
        unique_id: genUniqueIDNew(client.acronym),
        msg_type: "T",
        trans_type: "SMS",
        service_id: client_id
    }

    # api_params = {
    #     sender_id: sender_id,
    #     recipient_number: recipient_number,
    #     msg_body: message_body,
    #     unique_id: genUniqueID,
    #     src: src,
    #     api_key: api_key,
    #     service_id: client_id
    # }

    api_params = api_params.to_json

    puts "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    logger.info "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    # def computeSignature(secret, data)
    #     digest=OpenSSL::Digest.new('sha256')
    #     signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
    #     return signature
    # end
    signature = computeSignature(secret_key, api_params)
    #begin
    res = SMS_CONN.post do |req|
      req.url url_endpoint
      req.options.timeout = 30 # open/read timeout in seconds
      req.options.open_timeout = 30 # connection open timeout in seconds
      req['Authorization'] = "#{client_key}:#{signature}"
      req.body = api_params
    end
    puts
    puts "Result from TEST: #{res.body}"
    begin
      resp = JSON.parse(res.body)
    rescue JSON::ParserError
      resp = {}
      puts "----------------------------------------there's an error with the json--------------------"
      puts res.body.inspect
    end
    puts
    p resp = Msg.create(msg_id: sender_id, phone_number: recipient_number, msg: message_body, resp_code: resp['resp_code'], resp_desc: resp['resp_desc'], status: 1)
  end

  def self.sendPayoutMsg(recipient_number, payout_id, client_code, amount, trans_ref, recipient_name, reference)
    puts "CLIENT CODE: #{client_code}"
    logger.info "CLIENT CODE: #{client_code}"
    logger.info "PAYOUT ID: #{payout_id}"
    if !payout_id.nil? #!payout_id.present?
      user_id_pay = Payout.where(id: payout_id).order('updated_at desc').first
      logger.info "Payout Details: #{user_id_pay.inspect}"
      client = PremiumClient.where(user_id: user_id_pay.user_id).active.order('created_at desc').first
      logger.info "Client Details: #{client.inspect}"
      logger.info "Client Id: #{client.client_id}"
      logger.info "Client Key: #{client.client_key}"
      logger.info "Secret Key: #{client.secret_key}"
      logger.info "Company Name: #{client.company_name}"
    else
      client = PremiumClient.where(client_code: client_code).active.order('created_at desc').first
      logger.info "#{client}"
    end
    puts "CLIENT: #{client}"

    client_id = client.client_id
    puts "CLIENT ID: #{client_id}"
    logger.info "CLIENT ID: #{client_id}"


    client_key = client.client_key
    puts "CLIENT KEY: #{client_key}"
    logger.info "CLIENT KEY: #{client_key}"
    secret_key = client.secret_key
    puts "SECRET KEY: #{secret_key}"
    logger.info "SECRET KEY: #{secret_key}"
    api_key = client.sms_key
    puts "API KEY: #{api_key}"
    logger.info "API KEY: #{api_key}"

    if payout_id.present?
      sender_id = get_sender_id(client.client_code)
    else
      sender_id = get_sender_id(client_code)
    end
    message_body = "Dear #{recipient_name}, you have received an amount of GHS #{amount} from #{sender_id}. Ref: #{reference}. Trans ID: #{trans_ref}. Thank you."

    url_endpoint = SMS_END_POINT
    api_params = {
        sender_id: sender_id,
        recipient_number: recipient_number,
        msg_body: message_body,
        unique_id: genUniqueIDNew(client.acronym),
        msg_type: "T",
        trans_type: "SMS",
        service_id: client_id
    }

    # api_params = {
    #     sender_id: sender_id,
    #     recipient_number: recipient_number,
    #     msg_body: message_body,
    #     unique_id: genUniqueID,
    #     src: src,
    #     api_key: api_key,
    #     service_id: client_id
    # }

    api_params = api_params.to_json

    puts "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    logger.info "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    puts "-------------------------------------------------------------"
    logger.info "----------------------------------------------------------"
    # def computeSignature(secret, data)
    #     digest=OpenSSL::Digest.new('sha256')
    #     signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
    #     return signature
    # end
    signature = computeSignature(secret_key, api_params)
    #begin
    res = SMS_CONN.post do |req|
      req.url url_endpoint
      req.options.timeout = 180 # open/read timeout in seconds
      req.options.open_timeout = 180 # connection open timeout in seconds
      req['Authorization'] = "#{client_key}:#{signature}"
      req.body = api_params
    end
    puts
    puts "Result from TEST: #{res.body}"
    begin
      resp = JSON.parse(res.body)
    rescue JSON::ParserError
      resp = {}
      puts "----------------------------------------there's an error with the json--------------------"
      puts res.body.inspect
    end
    puts
    p resp = Msg.create(msg_id: sender_id, phone_number: recipient_number, msg: message_body, resp_code: resp['resp_code'], resp_desc: resp['resp_desc'], status: 1)
  end

  def self.computeSignature(secret, data)
    digest = OpenSSL::Digest.new('sha256')
    signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
    return signature
  end

  def self.get_network(code)
    case code
    when MTN_CODE;
      return MTN
    when VODAFONE_CODE;
      return VODAFONE
    when TIGO_CODE;
      return TIGO
    when AIRTEL_CODE;
      return AIRTEL
    when BANK_CODE;
      return BANK

    else
      false
    end
  end

  # def self.phone_formatter(number)
  #     #changes phone number format to match 233247876554
  #     if number[0] == '0'
  #         num = number[1..number.size]
  #         "233"+num
  #
  #     elsif number[0] == '+'
  #         number[1..number.size]
  #
  #     elsif number[0] == '2'
  #         number
  #     else
  #         false
  #     end
  #
  # end
end











































# class Transaction < ActiveRecord::Base
#   ###########FROM USSD########################3
#   #tigo constants
#   require 'json'
#   require 'csv'
#   require 'faraday'
#   require 'bcrypt'
#   require 'sendgrid-ruby'
#
#   include SendGrid
#   include BCrypt
#
#   attr_accessor :mobile_num, :netwk, :amt, :rec_name, :client_code, :disburse_status
#
#
# #first ussd body
# #FIRST_BODY = "200"
#
#
# # CONN = Faraday.new(:url => T24_URL, :ssl => {:verify => false}) do |faraday|
# #   faraday.response :logger                  # log requests to STDOUT
# #   faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
# # end
#
#
#   self.primary_key = :transaction_ref_id
#   belongs_to :user
#   belongs_to :payout, class_name: "Payout", foreign_key: :payout_id
#   belongs_to :recipient, class_name: "Recipient", foreign_key: :recipient_id
#   has_one :a_client, through: :recipient, foreign_key: :client_code
#   has_one :callback_resp, class_name: 'CallbackResp', foreign_key: :mm_trnx_id
#   has_many :user_client, class_name: "TransactionReprocess", foreign_key: :old_trnx_id
#
#
#   validates :mobile_num, presence: true, allow_blank: false, :numericality => {greater_than_or_equal_to: 0, allow_nil: true}
#   validates :rec_name, presence: true, allow_blank: false
#   validates :netwk, presence: true, allow_blank: false
#   validates :amt, presence: true, allow_blank: false, :numericality => {greater_than_or_equal_to: 0, allow_nil: true}
#
#   def self.per_page
#     30
#   end
#
#   def self.hash_pin(pin)
#     hash = BCrypt::Password.create(pin.strip, :cost => 4).to_s
#     puts "Generated hash: #{hash}"
#
#     return hash
#   end
#
#   def self.verify_pin(pin, hashed_pin)
#     r_bool = BCrypt::Password.new(hashed_pin) == pin
#     puts "PIN check result: #{r_bool}"
#
#     return r_bool
#   end
#
#
#   def self.get_current_balance(service_id, secret_key, client_key)
#     url_endpoint = CHECK_BAL_END_POINT
#     api_params = {
#         service_id: service_id
#     }
#
#     api_params = api_params.to_json
#
#     puts "API PARAMS FOR DISBURSEMENT CHECK BALANCE: #{api_params}"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     logger.info "API PARAMS FOR DISBURSEMENT CHECK BALANCE: #{api_params}"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     signature = computeSignature(secret_key, api_params)
#     res = CHECK_BAL_CONN.post do |req|
#       req.url url_endpoint
#       req["Authorization"] = "#{client_key}:#{signature}"
#       req.options.timeout = 30 # open/read timeout in seconds
#       req.options.open_timeout = 30 # connection open timeout in seconds
#       req.body = api_params
#     end
#     puts
#     puts "Result from TEST: #{res.body}"
#     begin
#       resp = JSON.parse(res.body)
#     rescue JSON::ParserError
#       resp = {}
#       puts "----------------------------------------there's an error with the json--------------------"
#       puts res.body.inspect
#     end
#     logger.info "#{resp}"
#     resp
#   end
#
#   def self.titling(str)
#     str_list = str.split
#
#     str_list.map {|word| word.capitalize
#     word.split("-").map {|w| w.capitalize}.join("-")
#     }.join(" ")
#   end
#
#   def self.name_search(name)
#     #where("firstname LIKE "+"'%#{val}%'" +" OR lastname LIKE "+ "'%#{val}%'",{:name => name})
#     if name.strip == ""
#       ""
#     else
#       n = titling(name)
#       name = "%#{n}%"
#
#       # where("(firstname LIKE :name OR lastname LIKE :name OR CONCAT(firstname,' ',lastname) LIKE :name) AND changed_status = false AND subscribed = true",
#       #       {:name =>name})
#       " recipients.recipient_name iLIKE '#{name}' "
#     end
#   end
#
#   def self.doPayout(list, client_code, trans_type = CREDIT)
#     output = Hash.new
#
#     client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('id desc')[0]
#
#     list.each do |recipient|
#       trnx_id = Transaction.genUniqueIDNew(client.acronym)
#       mobile_number = recipient.mobile_number
#
#       amount = recipient.amount
#       nw = recipient.network
#
#       # nw_code = Transaction.get_nw_code(nw)
#       nw_code = Transaction.get_network(nw)
#
#       check_recipient_trans = Transaction.where("recipient_id=?", recipient.id).exists?
#
#       if check_recipient_trans
#         logger.info "Recipient Exists::::#{recipient.inspect}"
#       elsif !check_recipient_trans
#         if trans_type == CREDIT
#           transaction = Transaction.new(
#               mobile_number: mobile_number,
#               trans_type: DISBURSE,
#               payout_id: nil,
#               recipient_id: recipient.id,
#               amount: amount,
#               network: nw,
#               transaction_ref_id: trnx_id,
#               trnx_type: CREDIT,
#               status: 0, #about to start first cycle
#
#               acronym: client.acronym
#           )
#           transaction.save(validate: false)
#
#           updated_recipient = Recipient.where(id: recipient.id).update_all(disburse_status: true, transaction_id: trnx_id)
#           logger.info "TRANSACTION OBJECT: #{transaction.inspect}"
#
#           logger.info "RECIPIENT OBJECT: #{updated_recipient.inspect}"
#
#
#         elsif trans_type == TOPUP
#           transaction = Transaction.create(
#               mobile_number: mobile_number,
#               trans_type: AIRTIME,
#               amount: amount,
#               network: nw,
#               payout_id: nil,
#               recipient_id: recipient.id,
#               transaction_ref_id: trnx_id,
#               trnx_type: TOPUP,
#               status: 0, #about to start first cycle
#
#               acronym: client.acronym
#           )
#
#           logger.info "TRANSACTION OBJECT: #{transaction.inspect}"
#
#         end
#         Transaction.newMobilePayment(mobile_number, amount, nw, CREDIT_MM_CALLBACK_URL, client.client_id, transaction, trans_type, trnx_id, "")
#       else
#       end
#
#
#       #
#       # recipient.disburse_status = true
#       # recipient.save
#     end
#
#
#     #return good response
#     output['status'] = true
#     output['message'] = "Payout process successfully initiated."
#   end
#
#
#   def self.phone_search(phone_number)
#     if phone_number.blank?
#       ""
#     else
#       phone = "%#{phone_number}%"
#       "transactions.mobile_number iLIKE '#{phone}'"
#     end
#   end
#
#   def self.search_date(start = "", ended = "")
#     if not start.blank? and not ended.blank?
#       " transactions.created_at BETWEEN '#{start} 00:00:00.0' AND '#{ended} 23:59:59.9999' "
#     elsif not start.blank?
#       " transactions.created_at > '#{start} 00:00:00.0' "
#     elsif not ended.blank?
#       " transactions.created_at < '#{ended} 23:59:59.9999' "
#     else
#       ""
#     end
#   end
#
#   def self.trans_id_search(id)
#     trans_id = "#{id}"
#     "transaction_ref_id = '#{trans_id}'"
#   end
#
#   def self.client_code_search(client_code)
#
#     "recipients.client_code = '#{client_code}'"
#   end
#
#
#   def self.to_csv(client_code, page, perpage, search_str = nil, options = {})
#     # column_names = %w{firstname lastname mobile_number amount trans_type account_number network_code final_status created_at }
#     #
#     #     column_names = %w{recipient_name mobile_number amount trans_type created_at
#     # network transaction_ref_id
#     # err_code nw_resp voucher_code}
#
#     column_names = %w{created_at trnx_id transaction_ref_id company_name network mobile_number amount
# err_code nw_resp }
#
#     headers = %w{Date Telco_ID Trans_ID Client Network phone_number Amount Status Description}
#
#     if page and perpage
#       page = page.to_i
#       perpage = perpage.to_i
#
#       off = perpage * (page - 1)
#
#       logger.info "THE LIMIT VALUE #{perpage}"
#
#       CSV.generate(options) do |csv|
#         csv << headers
#         joiner(client_code).where(search_str).each do |request|
#           row = request.attributes.values_at(*column_names)
#           #row[18] = request.final_status ? 'Complete Success' : 'Failure'
#           #row[22] = request.manually_closed ? 'Closed by User' : 'N/A'
#           if row[7] == "000" || row[7] == "200"
#             row[7] = "Success"
#           elsif row[7] == "001"
#             row[7] = "Failed"
#           else
#             row[7] = "Pending"
#           end
#
#           #row[4].strftime("%F %R")
#           row[0] = row[0].strftime("%F %R")
#           # if request.is_reversal
#           #   row[23] = 'Reprocessed Successfully'
#           # elsif request.is_reversal.nil?
#           #   row[23] = 'N/A'
#           # else
#           #   row[23] = 'Reprocess Failed'
#           # end
#           csv << row
#         end
#       end
#
#     else
#       CSV.generate(options) do |csv|
#         csv << headers
#         joiner(client_code).where(search_str).each do |request|
#           row = request.attributes.values_at(*column_names)
#           # row[18] = request.final_status ? 'Complete Success' : 'Failure'
#           # row[22] = request.manually_closed ? 'Closed by User' : 'N/A'
#
#           if row[7] == "000" || row[7] == "200"
#             row[7] = "Success"
#           elsif row[7] == "001"
#             row[7] = "Failed"
#           else
#             row[7] = "Pending"
#           end
#
#           #row[4].strftime("%F %R")
#           row[0] = row[0].strftime("%F %R")
#
#           # if request.is_reversal
#           #   row[23] = 'Reprocessed Successfully'
#           # elsif request.is_reversal.nil?
#           #   row[23] = 'N/A'
#           # else
#           #   row[23] = 'Reprocess Failed'
#           # end
#
#           csv << row
#         end
#       end
#     end
#
#   end
#
#   def self.to_admin_csv(page, perpage, search_str = nil, options = {})
#     # column_names = %w{firstname lastname mobile_number amount trans_type account_number network_code final_status created_at }
#
#     #     column_names = %w{recipient_name mobile_number amount trans_type created_at
#     # network transaction_ref_id
#     # err_code nw_resp voucher_code }
#
#     column_names = %w{created_at trnx_id transaction_ref_id company_name network mobile_number amount
# err_code nw_resp }
#
#     headers = %w{Date Telco_ID Trans_ID Client Network phone_number Amount Status Description}
#
#     if page and perpage
#       page = page.to_i
#       perpage = perpage.to_i
#
#       logger.info "THE ADMIN LIMIT VALUE #{perpage}"
#
#       off = perpage * (page - 1)
#
#       CSV.generate(options) do |csv|
#         csv << headers
#         joiner_not.where(search_str).each do |request|
#           row = request.attributes.values_at(*column_names)
#           #logger.info "CSV VALUES #{row.inspect}"
#           logger.info "CSV 0 #{row[0].inspect}"
#           logger.info "CSV 1 #{row[1].inspect}"
#           logger.info "CSV 2 #{row[2].inspect}"
#           logger.info "CSV 3 #{row[3].inspect}"
#           logger.info "CSV 4 #{row[4].inspect}"
#           logger.info "CSV 5 #{row[5].inspect}"
#           logger.info "CSV 6 #{row[6].inspect}"
#           logger.info "CSV 7 #{row[7].inspect}"
#           logger.info "CSV 8 #{row[8].inspect}"
#           logger.info "CSV 9 #{row[9].inspect}"
#           #row[18] = request.final_status ? 'Complete Success' : 'Failure'
#           #row[22] = request.manually_closed ? 'Closed by User' : 'N/A'
#           #
#           if row[7] == "000" || row[7] == "200"
#             row[7] = "Success"
#           elsif row[7] == "001"
#             row[7] = "Failed"
#           else
#             row[7] = "Pending"
#           end
#
#           #row[4].strftime("%F %R")
#           row[0] = row[0].strftime("%F %R")
#
#           # if request.is_reversal
#           #   row[23] = 'Reprocessed Successfully'
#           # elsif request.is_reversal.nil?
#           #   row[23] = 'N/A'
#           # else
#           #   row[23] = 'Reprocess Failed'
#           # end
#           csv << row
#         end
#       end
#
#     else
#       CSV.generate(options) do |csv|
#         csv << headers
#         joiner_not.where(search_str).each do |request|
#           row = request.attributes.values_at(*column_names)
#
#           if row[7] == "000" || row[7] == "200"
#             row[7] = "Success"
#           elsif row[7] == "001"
#             row[7] = "Failed"
#           else
#             row[7] = "Pending"
#           end
#
#           #row[4].strftime("%F %R")
#           row[0] = row[0].strftime("%F %R")
#           logger.info "EXL VALUES #{row.inspect}"
#           # row[18] = request.final_status ? 'Complete Success' : 'Failure'
#           # row[22] = request.manually_closed ? 'Closed by User' : 'N/A'
#           # if request.is_reversal
#           #   row[23] = 'Reprocessed Successfully'
#           # elsif request.is_reversal.nil?
#           #   row[23] = 'N/A'
#           # else
#           #   row[23] = 'Reprocess Failed'
#           # end
#
#
#           csv << row
#         end
#       end
#     end
#
#   end
#
#   def self.reversed
#     where("is_reversal IS NOT NULL")
#   end
#
#   def self.joiner_not
# #     joins(:recipient, :callback_resp, :a_client).select('transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
# # transactions.trans_type, transactions.created_at,
# # transactions.network, transactions.status,err_code,trnx_type,
# #  recipients.recipient_name, is_reversal,callback_resps.trnx_id,premium_clients.company_name').where("recipients.changed_status = false AND premium_clients.status = true AND premium_clients.changed_status = false")
#
#     joins("LEFT JOIN recipients on transactions.recipient_id = recipients.id LEFT JOIN callback_resps on transactions.transaction_ref_id = callback_resps.mm_trnx_id
#     LEFT JOIN premium_clients on recipients.client_code = premium_clients.client_code").where("recipients.changed_status = false AND premium_clients.status = true AND premium_clients.changed_status = false")
#     .select("transactions.recipient_id, transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount, transactions.trans_type, transactions.created_at,
#      transactions.network, transactions.status,transactions.err_code,transactions.trnx_type,transactions.is_reversal, recipients.recipient_name,callback_resps.trnx_id,premium_clients.company_name")
#
#     # return @joiner_not
#
#   end
#
# #   def self.joiner_not
# #     joins(:recipient).select('transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
# # transactions.trans_type, transactions.created_at,
# # transactions.network, transactions.status,err_code,trnx_type,
# #  recipients.recipient_name, is_reversal').where("recipients.changed_status = false")
# #   end
#
#   def self.joiner(cur_user)
# #     joins(:recipient, :callback_resp, :a_client).select('transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
# # transactions.trans_type, transactions.created_at,
# # transactions.network, transactions.status,err_code,trnx_type,
# #  recipients.recipient_name, is_reversal,callback_resps.trnx_id, premium_clients.company_name').where("recipients.changed_status = false AND recipients.status = true AND recipients.disburse_status = true AND recipients.client_code = '#{cur_user}' AND premium_clients.status = true AND premium_clients.changed_status = false")
#     #.where("recipients.client_code = '#{cur_user}'").where("premium_clients.status = true").where("premium_clients.changed_status = false")
#
#     joins("LEFT JOIN recipients on transactions.recipient_id = recipients.id LEFT JOIN callback_resps on transactions.transaction_ref_id = callback_resps.mm_trnx_id
#     LEFT JOIN premium_clients on recipients.client_code = premium_clients.client_code").where("recipients.changed_status = false AND recipients.status = true AND recipients.disburse_status = true AND recipients.client_code = '#{cur_user}' AND premium_clients.status = true AND premium_clients.changed_status = false")
#     .select("transactions.recipient_id, transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount, transactions.trans_type, transactions.created_at,
#      transactions.network, transactions.status,transactions.err_code,transactions.trnx_type,transactions.is_reversal,recipients.recipient_name, callback_resps.trnx_id, premium_clients.company_name")
#
#     # return @joiner
#
#
#   end
#
# #   def self.joiner(client_code)
# #     joins("LEFT JOIN recipients ON transactions.recipient_id = recipients.id
# # LEFT JOIN premium_clients ON recipients.client_code = premium_clients.client_code
# # LEFT JOIN callback_resps ON transactions.transaction_ref_id = callback_resps.mm_trnx_id").select(
# #         "transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
# # transactions.trans_type, transactions.created_at,
# # transactions.network, transactions.status,err_code,trnx_type,
# #  recipients.recipient_name, is_reversal,callback_resps.trnx_id,premium_clients.company_name").where("recipients.changed_status = ?", false).where("recipients.client_code = ?",client_code)
# #   end
#
# #   def self.joiner_not
# #     joins("LEFT JOIN recipients ON transactions.recipient_id = recipients.id
# # LEFT JOIN premium_clients ON recipients.client_code = premium_clients.client_code
# # LEFT JOIN callback_resps ON transactions.transaction_ref_id = callback_resps.mm_trnx_id").select(
# #         "transactions.recipient_id,transactions.id, transactions.nw_resp,transactions.transaction_ref_id, transactions.mobile_number, transactions.amount,
# # transactions.trans_type, transactions.created_at,
# # transactions.network, transactions.status,err_code,trnx_type,
# #  recipients.recipient_name, is_reversal,callback_resps.trnx_id,premium_clients.company_name").where("recipients.changed_status = ?", false).where("recipients.status = ?", true)
# #
# # #         where(
# # #         "person_infos.status2 = false AND person_pref_jobs.status1 = true AND prev_edu_details.status1 = true AND prev_work_details.status1 = true AND person_code NOT IN (SELECT person_id from person_engaged_masters where status1 = true)").group(
# # #         "person_code, record_type_id, gender, dob, work_titles1.title, concat(surname_name, ' ', first_name, ' ', other_names), person_pref_jobs.work_title_id, person_infos.created_at
# # # ")
# #   end
#
# # LEFT JOIN prev_work_details ON person_infos.person_code = prev_work_details.person_id
# # LEFT JOIN edu_qualifs ON edu_qualifs.id = prev_edu_details.certificate_id
# # LEFT JOIN work_titles AS work_titles1 ON work_titles1.id = person_pref_jobs.work_title_id
# # LEFT JOIN work_titles AS work_titles2 ON work_titles2.id = prev_work_details.work_title_id
#
#   def self.active
#     where(changed_status: false)
#   end
#
# # def self.bill_payment
# #   where("trans_type = 'BIL'")
# # end
#
#
#   def self.trans_type_search(trans_type)
#     "trans_type = '#{trans_type}'"
#   end
#
#   def self.network_search(network)
#     "recipients.network = '#{network}'"
#   end
#
#   def self.status_search(status_code)
#
#     if status_code == "pending"
#       "transactions.err_code IS NULL"
#     elsif status_code == "000" || status_code == "001"
#       "transactions.err_code = '#{status_code}'"
#     else
#       ""
#     end
#
#   end
#
#   def self.handle_amfp_reversal(mobile_number, amount, nw_code, trans_obj, trans_id, user_id)
#
#     new_trans_id = self.genUniqueID
#     acct_no = trans_obj.account_number
#     reversal = TransactionReprocess.create(
#         old_trnx_id: trans_id,
#         new_trnx_id: new_trans_id,
#         amount: amount,
#         # acct_no: acct_no,
#         auto: false,
#         user_id: user_id
#     )
#
#     trans_obj.is_reversal = false #reversal has started. It's no more null
#     trans_obj.save
#
#     #newMobilePayment(MERCHANT_NUMBER_ANB, mobile_number, amount, nw_code, CREDIT_MM_CALLBACK_URL,CLIENT_ID, trans_obj, CREDIT, trans_id, reversing=true)
#
#   end
#
#
#   def self.genUniqueID
#     time = Time.new
#     randval = rand(999).to_s.center(3, rand(9).to_s)
#     uniqcode = time.strftime("%y%m%d%H%M").to_s + randval.to_s
#
#     return DISBURSE_ID_PRE + uniqcode
#   end
#
#   def self.genUniqueIDNew(client_acronym)
#     time = Time.new
#     randval = rand(99).to_s.center(2, rand(9).to_s)
#     uniqid = ""
#     public_id = loop do
#       puts "======================================="
#       puts "====== Generating next unique ID ======"
#       uniqid = "#{DISBURSE_ID_PRE}" + "#{client_acronym}" + time.strftime("%S%d%L%H%M").to_s + randval.to_s
#       puts "========== ID: #{uniqid} =============="
#       puts
#
#       break uniqid unless Transaction.exists?(transaction_ref_id: uniqid)
#     end
#   end
#
#   def self.newMobilePayment(customer_number, amt, nw_code, callback_url, client_id, transaction, trans_type = CREDIT, trans_id, voucher_code)
# #trnx_type = PN, CR, DR, NW
#     url = AMFP_URL
#     endpoint = END_POINT
#     client = PremiumClient.where(client_id: client_id, status: true).active.order('updated_at desc').first
#     client_key = client.client_key
#     puts "CLIENT KEY: #{client_key}"
#     logger.info "CLIENT KEY: #{client_key}"
#     secret_key = client.secret_key
#     puts "SECRET KEY: #{secret_key}"
#     logger.info "SECRET KEY: #{secret_key}"
#
#     client_acronymm = client.acronym
#     puts "CLIENT ACRONYM: #{client_acronymm}"
#     logger.info "CLIENT ACRONYM: #{client_acronymm}"
#
#     if [AIRTEL_PARAM, TIGO_PARAM, VODA_PARAM, MTN_PARAM].include? nw_code
#       nw_param = nw_code
#     else
#       nw_param = get_network_param(nw_code)
#     end
#     puts
#     puts
#     puts "THIS IS THE NETWORK PARAM: #{nw_param}"
#     puts
#     puts
#
#
#     ts = Time.now.strftime("%Y-%m-%d %H:%M:%S")
#
#     conn = Faraday.new(:url => url, :headers => REQHDR, :ssl => {:verify => false}) do |faraday|
#       faraday.response :logger # log requests to STDOUT
#       faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
#     end
#
#
#     puts "SENT CALL BACK CREATION BEGUN----------------------"
#     n = SentCallback.create(
#         mobile_number: customer_number,
#         trnx_type: trans_type,
#         trnx_id: trans_id,
#         amount: amt,
#         network: nw_param,
#         status: 1,
#     )
#
#     p "SENT REQUEST OBJECT: #{n.inspect}"
#
#
#     puts
#     puts
#     puts "THIS IS THE NETWORK PARAM: #{nw_param}"
#     puts
#     puts
#     acronym = client.acronym
#
#
#     if trans_type == DEBIT
#       ref = DR_REF
#     elsif trans_type == CREDIT
#       ref = CR_REF
#     elsif trans_type == TOPUP
#       ref = ATP_REF
#     else
#       ref = REF
#     end
#
#     ref = acronym + ref
#
#     if nw_code == VODAFONE_CODE
#       payload = {
#           :voucher_code => voucher_code,
#           :customer_number => customer_number,
#           :reference => ref,
#           :amount => amt,
#           :exttrid => trans_id,
#           :nw => nw_param,
#           :trans_type => trans_type,
#           :callback_url => callback_url,
#           :ts => ts,
#           :client_id => client_id,
#       }
#     else
#       payload = {
#           # :merchant_number=> merchant_number,
#           :customer_number => customer_number,
#           :reference => ref,
#           :amount => amt,
#           :exttrid => trans_id,
#           :nw => nw_param,
#           :trans_type => trans_type,
#           :callback_url => callback_url,
#           :ts => ts,
#           :client_id => client_id,
#
#       }
#     end
#
#     json_payload = JSON.generate(payload)
#     msg_endpoint = "#{json_payload}"
#
#     puts
#     puts msg_endpoint
#     puts
#
#     signature = computeSignature(secret_key, msg_endpoint)
#
#     begin
#       res = conn.post do |req|
#         req.url endpoint
#         req.options.timeout = 30 # open/read timeout in seconds
#         req.options.open_timeout = 30 # connection open timeout in seconds
#         req["Authorization"] = "#{client_key}:#{signature}"
#         req.body = json_payload
#       end
#
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#       logger.info "->->->->->->->->->->->->->->"
#
#       puts
#       puts "Response: #{res.body} OF TYPE: #{res.body.class}"
#       logger.info "Response: #{res.body} OF TYPE: #{res.body.class}"
#
#       #p body["resp_code"] #real response
#
#
#       puts "MOBILE MONEY PAYMENT----------------------------------"
#       puts res.status
#       puts "type: #{res.status.class}"
#
#       puts
#         #puts encoded_payload
#     rescue Faraday::SSLError
#
#       puts
#       puts "There was a problem sending the https request..."
#       puts
#     rescue Faraday::TimeoutError
#
#       puts "Connection timeout error"
#
#     rescue
#       puts "Error"
#     end
#   end
#
#   def self.import_contacts(file, client_code, user_id)
#
#     positive_numbers = /^[+]?([0-9]+(?:[\.][0-9]*)?|\.[0-9]+)$/
#     letters_only = /^[A-Za-z\s]+$/
#
#
#     @recipients = []
#
#     @client_info = PremiumClient.where(status: true, changed_status: false, client_code: client_code).order('created_at desc').last
#
#     d = DateTime.now
#     d = d.strftime("%d-%m-%Y_%H:%M:%S")
#
#     _file = file
#     fileContentType = _file.content_type
#     acceptContentType = "application/vnd.ms-excel"
#     acceptContentType1 = "text/csv"
#     logger.info "Original file #{file.inspect}"
#     logger.info "Assigned file #{_file.inspect}"
#     networks = ['MTN', 'AIR', 'TIG', 'VOD']
#
#     the_msg = 0
#     readVal = file.read
#     logger.info "Read value #{readVal.inspect}"
#     logger.info "Content Type #{fileContentType}"
#     logger.info "Assigned Read value #{readVal.inspect}"
#     fname = file.original_filename
#     _filename = file.tempfile
#     final_file_path = "./public/csv_files/#{@client_info.acronym}_#{d}_#{fname}"
#     if  acceptContentType   == fileContentType || acceptContentType1 == fileContentType
#
#
#       check_file_existence = CsvUpload.where(user_id: user_id, client_code: client_code, file_name: fname).exists?
#
#       logger.info "File exists? #{check_file_existence.inspect}"
#
#       if check_file_existence
#         the_msg = 9
#       elsif !check_file_existence
#         File.open("#{final_file_path}", 'wb') do |f|
#           #f.write(_filename.read)
#           f.write(readVal)
#         end
#
#         save_csv_file = CsvUpload.create(user_id: user_id, client_code: client_code, file_name: fname, file_path: final_file_path)
#
#         save_csv_file.save
#
#         csv_upload_id = save_csv_file.id
#
#
#
#         # save_csv_file = CsvUpload.create(user_id: user_id, client_code: client_code, file_name: fname, file_path: final_file_path)
#         # save_csv_file.save
#         #
#         # @upload_id = CsvUpload.where(user_id: user_id, client_code: client_code, file_name: fname, file_path: final_file_path).order('created_at desc')[0]
#         # csv_upload_id = @upload_id.id
#
#
#         logger.info "Saved #{save_csv_file.inspect}"
#         logger.info "Saved ID #{save_csv_file.id}"
#         logger.info "Saved User ID #{save_csv_file.user_id}"
#         logger.info "Saved Client Code #{save_csv_file.client_code}"
#         logger.info "Value from file\n#{readVal.inspect}"
#         logger.info "Value from file\n#{_filename.inspect}"
#
#
#         readVal = readVal.split(',').map {|val| val.strip}
#         last = readVal[3].split("\n")
#         last[0] = last[0].strip
#         if last[0] == "amount\r"
#           last[0] = "amount"
#         end
#         logger.info "First: #{readVal[0].inspect}"
#         logger.info "Second: #{readVal[1].inspect}"
#         logger.info "Third: #{readVal[2].inspect}"
#         logger.info "Last: #{last.inspect}"
#         logger.info "HERE IS THE READVAL THINGY #{readVal.inspect}"
#
#
#         if readVal[0] == "recipient_name" && readVal[1] == "mobile_number" && readVal[2] == "network" && last[0] == "amount"
#           CSV.foreach(file.path, headers: true) do |row|
#             logger.info 'This is it-----'
#             logger.info row.inspect
#
#             if row["mobile_number"].present? && row["network"].present? && row["amount"].present? && row["recipient_name"].present?
#               unless row["amount"].match(positive_numbers)
#
#                 the_msg = 8
#               end
#               if row["mobile_number"].scan(/\D/i).length == 0
#                 if !row["mobile_number"].match(positive_numbers)
#                   the_msg = 4
#                 else
#                   number = phone_formatter(row["mobile_number"])
#
#                   number = 0 unless number
#
#                   network = row['network'].upcase
#                   name = User.titling(row['recipient_name']) #name
#                   logger.info "NAME: #{name}"
#
#                   unless networks.include?(network)
#                     #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "Unknown network")
#                     the_msg = 1
#                     return the_msg
#                   end
#
#                   #check recipient name
#                   #
#                   if row["recipient_name"].blank?
#                     #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "No recipient name")
#
#                     return the_msg = 3
#                   end
#
#
#                   if row["recipient_name"].match(positive_numbers)
#                     #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "No recipient name")
#
#                     return the_msg = 3
#                   end
#
#                   if number.length == 12
#                     @recipients << Recipient.new(recipient_name: name, mobile_number: number, network: network, csv_uploads_id: csv_upload_id, amount: row['amount'], disburse_status: false, client_code: client_code, user_id: user_id)
#                   else
#                     the_msg = 4
#                     #Recipient.create(recipient_name: name, mobile_number: number, network: network, disburse_status: false, client_code: client_code, status: false, fail_reason: "Wrong mobile number")
#                   end
#                 end
#               else
#                 the_msg = 5
#                 #Recipient.create(recipient_name: name, mobile_number: number, network: network, disburse_status: false, client_code: client_code, status: false, fail_reason: "Wrong mobile number format")
#               end
#             else
#               the_msg = 6
#               #Recipient.create(recipient_name: name, mobile_number: number, network: network, disburse_status: false, client_code: client_code, status: false, fail_reason: "Invalid row, missing parameters")
#             end
#           end
#         else
#           return "2"
#         end
#       end
#       logger.info "**********************************************************"
#       logger.info "#{@recipients.inspect}"
#       logger.info "#{the_msg}"
#       logger.info "**********************************************************"
#
#
#       if the_msg == 0
#         Recipient.import @recipients
#         @recipients.clear
#       else
#         @recipients.clear
#       end
#     else
#       return "7"
#     end
#     @recipients.clear
#     return the_msg
#   end
#
#   def self.phone_formatter(number)
#     #changes phone number format to match 233247876554
#     if number[0] == '0'
#       num = number[1..number.size]
#       "233" + num
#
#     elsif number[0] == '+'
#       number[1..number.size]
#
#     elsif number[0..2] == '233'
#       number
#     elsif number[0] == '2' or number[0] == '5'
#       '233' + number
#     else
#       false
#     end
#
#   end
#
#   def self.get_network_param(code)
#     "THIS IS THE CODE: #{code}"
#     case code
#     when MTN_CODE;
#       return MTN_PARAM
#     when VODAFONE_CODE;
#       return VODA_PARAM
#     when TIGO_CODE;
#       return TIGO_PARAM
#     when AIRTEL_CODE;
#       return AIRTEL_PARAM
#
#     else
#       false
#     end
#   end
#
# # def self.sendmsg(senderID, receipient, txtmsg)
# #     strUser="tester"
# #     strPass="foobar"
# #     strIP= "184.173.139.74"#"localhost"
# #     strHostPort="13013"
# #     ####http://184.173.139.74:8198
# #
# #     time=Time.new
# #     msgID=strtm=time.strftime("%y%m%d%H%M%S%L")
# #
# #     strDlrUrl="http://#{strIP}:#{strHostPort}/Dlr?msgID=#{msgID}&smsc_reply=%A&sendsms_user=%n&ani=%P&bni=%p&dlr_val=%d&smsdate=%t&smscid=%i&charset=%C&mclass=%m&bmsg=%b&msg=%a"
# #
# #     uri=URI("http://#{strIP}:#{strHostPort}/cgi-bin/sendsms")
# #     uri.query=URI.encode_www_form([["username", strUser], ["password", strPass], ["charset", "UTF-8"], ["to", receipient], ["dlr-mask", "31"], ["from", senderID], ["text", txtmsg], ["smsc","airtel"],["dlr-url", strDlrUrl]])
# #
# #     res = Net::HTTP.get_response(uri)
# #     puts res.code
# #     puts res.body
# #
# #
# #     p resp=Msg.create(msg_id: senderID, phone_number: receipient, msg: txtmsg, resp_code: res.code, resp_desc: res.body, status: 1)
# # end
#
#   def self.get_sender_id(client_code)
#     client = PremiumClient.where(client_code: client_code).active.order('id asc').last
#
#
#     sender_id = client.sender_id
#
#   end
#
#   # def self.sendmsg(recipient_number, message_body, client_code, api_key, src = "API")
#   #   puts "CLIENT CODE: #{client_code}"
#   #   logger.info "CLIENT CODE: #{client_code}"
#   #   client = PremiumClient.where(client_code: client_code).active.order('created_at desc').last
#   #   client_id = client.client_id
#   #   puts "CLIENT ID: #{client_id}"
#   #   logger.info "CLIENT ID: #{client_id}"
#   #   client_key = client.client_key
#   #   puts "CLIENT KEY: #{client_key}"
#   #   logger.info "CLIENT KEY: #{client_key}"
#   #   secret_key = client.secret_key
#   #   puts "SECRET KEY: #{secret_key}"
#   #   logger.info "SECRET KEY: #{secret_key}"
#   #   api_key = client.sms_key
#   #   puts "API KEY: #{api_key}"
#   #   logger.info "API KEY: #{api_key}"
#   #
#   #   sender_id = get_sender_id(client_code)
#   #
#   #   url_endpoint = SMS_END_POINT
#   #   api_params = {
#   #       sender_id: sender_id,
#   #       recipient_number: recipient_number,
#   #       msg_body: message_body,
#   #       unique_id: genUniqueIDNew(client.acronym),
#   #       msg_type: "T",
#   #       trans_type: "SMS",
#   #       service_id: client_id
#   #   }
#   #
#   #   # api_params = {
#   #   #     sender_id: sender_id,
#   #   #     recipient_number: recipient_number,
#   #   #     msg_body: message_body,
#   #   #     unique_id: genUniqueID,
#   #   #     src: src,
#   #   #     api_key: api_key,
#   #   #     service_id: client_id
#   #   # }
#   #
#   #   api_params = api_params.to_json
#   #
#   #   puts "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   logger.info "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   puts "-------------------------------------------------------------"
#   #   logger.info "----------------------------------------------------------"
#   #   # def computeSignature(secret, data)
#   #   #     digest=OpenSSL::Digest.new('sha256')
#   #   #     signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
#   #   #     return signature
#   #   # end
#   #   signature = computeSignature(secret_key, api_params)
#   #   #begin
#   #   res = SMS_CONN.post do |req|
#   #     req.url url_endpoint
#   #     req.options.timeout = 30 # open/read timeout in seconds
#   #     req.options.open_timeout = 30 # connection open timeout in seconds
#   #     req['Authorization'] = "#{client_key}:#{signature}"
#   #     req.body = api_params
#   #   end
#   #   puts
#   #   puts "Result from TEST: #{res.body}"
#   #   begin
#   #     resp = JSON.parse(res.body)
#   #   rescue JSON::ParserError
#   #     resp = {}
#   #     puts "----------------------------------------there's an error with the json--------------------"
#   #     puts res.body.inspect
#   #   end
#   #   puts
#   #   p resp = Msg.create(msg_id: sender_id, phone_number: recipient_number, msg: message_body, resp_code: resp['resp_code'], resp_desc: resp['resp_desc'], status: 1)
#   # end
#
#
#   def self.sendmsg(recipient_number, message_body, client_code, api_key, src = "API")
#     puts "CLIENT CODE: #{client_code}"
#     logger.info "CLIENT CODE: #{client_code}"
#
#
#     client = PremiumClient.where(client_code: client_code, status: true, changed_status: false).order('id desc')[0]
#     client_id = client.client_id
#
#     client = PremiumClient.where(client_id: client_id, status: true).active.order('updated_at desc').first
#     client_key = client.client_key
#     puts "CLIENT ID: #{client_id}"
#     puts "CLIENT KEY: #{client_key}"
#     logger.info "CLIENT ID: #{client_id}"
#     logger.info "CLIENT KEY: #{client_key}"
#     secret_key = client.secret_key
#     puts "SECRET KEY: #{secret_key}"
#     logger.info "SECRET KEY: #{secret_key}"
#
#
#
#     # client = PremiumClient.where(client_code: client_code).active.order('created_at desc').last
#     # client_id = client.client_id
#     # puts "CLIENT ID: #{client_id}"
#     # logger.info "CLIENT ID: #{client_id}"
#     # client_key = client.client_key
#     # puts "CLIENT KEY: #{client_key}"
#     # logger.info "CLIENT KEY: #{client_key}"
#     # secret_key = client.secret_key
#     # puts "SECRET KEY: #{secret_key}"
#     # logger.info "SECRET KEY: #{secret_key}"
#     api_key = client.sms_key
#     puts "API KEY: #{api_key}"
#     logger.info "API KEY: #{api_key}"
#
#     sender_id = get_sender_id(client_code)
#
#     url_endpoint = SMS_END_POINT
#     api_params = {
#         sender_id: sender_id,
#         recipient_number: recipient_number,
#         msg_body: message_body,
#         unique_id: genUniqueIDNew(client.acronym),
#         msg_type: "T",
#         trans_type: "SMS",
#         service_id: client_id
#     }
#
#     # api_params = {
#     # sender_id: sender_id,
#     # recipient_number: recipient_number,
#     # msg_body: message_body,
#     # unique_id: genUniqueID,
#     # src: src,
#     # api_key: api_key,
#     # service_id: client_id
#     # }
#
#     api_params = api_params.to_json
#
#     puts "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     logger.info "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     # def computeSignature(secret, data)
#     # digest=OpenSSL::Digest.new('sha256')
#     # signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
#     # return signature
#     # end
#     signature = computeSignature(secret_key, api_params)
#     #begin
#     res = SMS_CONN.post do |req|
#       req.url url_endpoint
#       req.options.timeout = 30 # open/read timeout in seconds
#       req.options.open_timeout = 30 # connection open timeout in seconds
#       req['Authorization'] = "#{client_key}:#{signature}"
#       req.body = api_params
#     end
#     puts
#     puts "Result from TEST: #{res.body}"
#     begin
#       resp = JSON.parse(res.body)
#     rescue JSON::ParserError
#       resp = {}
#       puts "----------------------------------------there's an error with the json--------------------"
#       puts res.body.inspect
#     end
#     puts
#     p resp = Msg.create(msg_id: sender_id, phone_number: recipient_number, msg: message_body, resp_code: resp['resp_code'], resp_desc: resp['resp_desc'], status: 1)
#   end
#
#   def self.sendPayoutMsg(recipient_number, payout_id, client_code, amount, trans_ref, recipient_name)
#     puts "CLIENT CODE: #{client_code}"
#     logger.info "CLIENT CODE: #{client_code}"
#     logger.info "PAYOUT ID: #{payout_id}"
#     if payout_id.present?
#       user_id_pay = Payout.where(id: payout_id).order('updated_at desc')[0]
#       logger.info "Payout Details: #{user_id_pay.inspect}"
#       client = PremiumClient.where(user_id: user_id_pay.user_id).active.order('created_at desc').last
#       logger.info "Client Details: #{client.inspect}"
#       logger.info "Client Id: #{client.client_id}"
#       logger.info "Client Key: #{client.client_key}"
#       logger.info "Secret Key: #{client.secret_key}"
#       logger.info "Company Name: #{client.company_name}"
#     else
#       client = PremiumClient.where(client_code: client_code).active.order('created_at desc').last
#       logger.info "#{client}"
#     end
#     puts "CLIENT: #{client}"
#
#     client_id = client.client_id
#     puts "CLIENT ID: #{client_id}"
#     logger.info "CLIENT ID: #{client_id}"
#
#
#     client_key = client.client_key
#     puts "CLIENT KEY: #{client_key}"
#     logger.info "CLIENT KEY: #{client_key}"
#     secret_key = client.secret_key
#     puts "SECRET KEY: #{secret_key}"
#     logger.info "SECRET KEY: #{secret_key}"
#     api_key = client.sms_key
#     puts "API KEY: #{api_key}"
#     logger.info "API KEY: #{api_key}"
#
#     if payout_id.present?
#       sender_id = get_sender_id(client.client_code)
#     else
#       sender_id = get_sender_id(client_code)
#     end
#     message_body = "Dear #{recipient_name}, you have received an amount of GHS #{amount} from #{sender_id}. Reference ID: #{trans_ref}. Thank you."
#
#     url_endpoint = SMS_END_POINT
#     api_params = {
#         sender_id: sender_id,
#         recipient_number: recipient_number,
#         msg_body: message_body,
#         unique_id: genUniqueIDNew(client.acronym),
#         msg_type: "T",
#         trans_type: "SMS",
#         service_id: client_id
#     }
#
#     # api_params = {
#     #     sender_id: sender_id,
#     #     recipient_number: recipient_number,
#     #     msg_body: message_body,
#     #     unique_id: genUniqueID,
#     #     src: src,
#     #     api_key: api_key,
#     #     service_id: client_id
#     # }
#
#     api_params = api_params.to_json
#
#     puts "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     logger.info "API PARAMS FOR DISBURSEMENT SENDMSG: #{api_params}"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     puts "-------------------------------------------------------------"
#     logger.info "----------------------------------------------------------"
#     # def computeSignature(secret, data)
#     #     digest=OpenSSL::Digest.new('sha256')
#     #     signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
#     #     return signature
#     # end
#     signature = computeSignature(secret_key, api_params)
#     #begin
#     res = SMS_CONN.post do |req|
#       req.url url_endpoint
#       req.options.timeout = 30 # open/read timeout in seconds
#       req.options.open_timeout = 30 # connection open timeout in seconds
#       req['Authorization'] = "#{client_key}:#{signature}"
#       req.body = api_params
#     end
#     puts
#     puts "Result from TEST: #{res.body}"
#     begin
#       resp = JSON.parse(res.body)
#     rescue JSON::ParserError
#       resp = {}
#       puts "----------------------------------------there's an error with the json--------------------"
#       puts res.body.inspect
#     end
#     puts
#     p resp = Msg.create(msg_id: sender_id, phone_number: recipient_number, msg: message_body, resp_code: resp['resp_code'], resp_desc: resp['resp_desc'], status: 1)
#   end
#
#   def self.computeSignature(secret, data)
#     digest = OpenSSL::Digest.new('sha256')
#     signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
#     return signature
#   end
#
#   def self.get_network(code)
#     case code
#     when MTN_CODE;
#       return MTN
#     when VODAFONE_CODE;
#       return VODAFONE
#     when TIGO_CODE;
#       return TIGO
#     when AIRTEL_CODE;
#       return AIRTEL
#
#     else
#       false
#     end
#   end
#
#   # def self.phone_formatter(number)
#   #     #changes phone number format to match 233247876554
#   #     if number[0] == '0'
#   #         num = number[1..number.size]
#   #         "233"+num
#   #
#   #     elsif number[0] == '+'
#   #         number[1..number.size]
#   #
#   #     elsif number[0] == '2'
#   #         number
#   #     else
#   #         false
#   #     end
#   #
#   # end
# end
