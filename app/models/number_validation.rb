class NumberValidation < ActiveRecord::Base
self.primary_key = :id


  def self.phone_formatter(number)
    #changes phone number format to match 233247876554
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


def self.computeSignature(secret, data)
  digest=OpenSSL::Digest.new('sha256')
  signature = OpenSSL::HMAC.hexdigest(digest, secret.to_s, data)
  return signature
end

def self.json_validate(json)
  JSON.parse(json)
  return true
rescue JSON::ParserError => e
  return false
end

def self.validate_truecaller(customer_number,bank_code,trans_type)

  puts "######################### ORCHARD TRUECALLER - API #########################"
  puts "######################### ORCHARD TRUECALLER - API #########################"
  puts "######################### ORCHARD TRUECALLER - API #########################"

  str_client_key = "JYAX4rhY3FI3LtzFwKGoVdnAMOkH3a51hAu3TdHv0cYiCTD4AjqqecZTzdgFjRcuDlGSEnhZQ2HC5BobsHLERQ==" #"ifdkP1moBvGpAk3dTdGABV8sSkckMpm0du+sUQSbJJhFJirbjxu6LoAhtzoqBSvJh+puHTuKe0k+t+q4LpoyCg==" #your client key / public key
  str_secret_key = "Na+oh2ElZk3fDy3kKQItvXm0L+9vZ5j2cPfTX2/bLpFnDZOOxhINR4ouc0kBinwZSeX/68eHkPvwByMhNx7raw==" #"MNDOujByAxjmHTN0zi1gX/EX4wGTVbgOEsUHryTYmj35yoyGdeDuXW9BtsDWRgpxBEc7P65eHBzgpYEh+AUtQA=="
  service_id = "1" #"275"

  payload={
      :customer_number=> customer_number,
      :bank_code=> bank_code,
      :trans_type=>trans_type,
      :service_id=>service_id,
  }

  puts payload

  json_payload=JSON.generate(payload)
  puts
  puts "######################### FLY TV - API The request payload: #{json_payload} #########################"
  puts

  signature=computeSignature(str_secret_key, json_payload.to_s)
  begin
    res=Orch_Test_conn.post do |req|
      req.url "/accountInquiry"
      req.options.timeout = 180 # open/read timeout in seconds
      req.options.open_timeout = 180 # connection open timeout in seconds
      req["Authorization"]="#{str_client_key}:#{signature}"
      req.body = json_payload
    end
    resp = resp_code = ""
    is_json = json_validate(res.body)
    if is_json
      puts res.body
      if !res.body.nil?
        resp = JSON.parse(res.body)
        resp_code = resp['resp_code']
        resp_desc = resp['resp_desc']
        message = ""
      else
        puts "RESPONSE FROM API is Empty"
      end
    else
      resp_code = 998
      message = { "resp_code": resp_code,"resp_desc": "Not a json response" }
      return message.to_json
    end

  rescue Faraday::ConnectionFailed
    resp = {}
    puts "----------- ConnectionFailed ------------"
    puts "---------------------------------"
    puts "-----------ConnectionFailed------------"

    resp_code = ERR_CONNECTION_FAILED_CODE
    resp_desc = ERR_CONNECTION_FAILED_DESC

    time=Time.new
    datetime = time.strftime("%d-%B-%Y %I:%M %p")

    email_sub = "Orchard TrueCaller- Orchard Payment Connection Failure"

    str_email=""
    str_email="Dear Engineer,\n\n"
    str_email << "There's an error connecting to Orchard TrueCaller endpoint. Find below the error details: \n\n"
    str_email << "Error Type: Connection Failure. \n\n"
    str_email << "Endpoint: orchard_truecaller. \n\n"
    str_email << "customer_number: #{customer_number}. \n\n"
    str_email << "Others: #{resp_desc}. \n\n"
    str_email << "Date: #{datetime}. \n\n"
    str_email << "\n\nRegards,\n#{EMAIL_SENDER}\n"

    log_error(email_sub,str_email)

  rescue Faraday::TimeoutError
    resp = {}
    puts "-----------TIMED OUT------------"
    puts "---------------------------------"
    puts "-----------TIMED OUT------------"
    puts "---------------------------------"
    puts "-----------TIMED OUT------------"
    puts "SEND MSG TIMED OUT"

  end

  #Request successfully received for processing
  if !resp_code.nil? && resp_code == "015" then
    message = ERR_PAYMENT_REQ
  else
    message = resp
  end

  puts "######################### ORCHARD TRUECALLER - API #########################"
  puts "######################### ORCHARD TRUECALLER - API #########################"
  puts "######################### ORCHARD TRUECALLER - API #########################"


  if !resp["resp_code"].nil?

    if resp["resp_code"] == "027"
      message = { "resp_code": resp["resp_code"],"resp_desc": resp["resp_desc"], "remote_trid": resp["remote_trid"], "account_name": resp["account_name"] }
    else
      message = { "resp_code": resp["resp_code"],"resp_desc": resp["resp_desc"] }
    end

  else
    message = { "resp_code": "999","resp_desc": "Record not returned" }

  end
  message.to_json

end



  def self.validate_import(file, client_code, user_id)

    positive_numbers = /^[+]?([0-9]+(?:[\.][0-9]*)?|\.[0-9]+)$/
    letters_only = /^[A-Za-z\s]+$/

    @validatees = []

    @client_info = PremiumClient.where(status: true, changed_status: false, client_code: client_code).order('created_at desc').last

    d = DateTime.now
    d = d.strftime("%d-%m-%Y_%H:%M:%S")

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
    if  acceptContentType   == fileContentType || acceptContentType1 == fileContentType


      check_file_existence = CsvUpload.where(user_id: user_id, client_code: client_code, file_name: fname).exists?

      logger.info "File exists? #{check_file_existence.inspect}"

      if check_file_existence
        the_msg = 9
      elsif !check_file_existence
        File.open("#{final_file_path}", 'wb') do |f|
          #f.write(_filename.read)
          f.write(readVal)
        end

        save_csv_file = CsvUpload.create(user_id: user_id, client_code: client_code, file_name: fname, file_path: final_file_path)

        save_csv_file.save

        csv_upload_id = save_csv_file.id

        logger.info "Saved #{save_csv_file.inspect}"
        logger.info "Saved ID #{save_csv_file.id}"
        logger.info "Saved User ID #{save_csv_file.user_id}"
        logger.info "Saved Client Code #{save_csv_file.client_code}"
        logger.info "Value from file\n#{readVal.inspect}"
        logger.info "Value from file\n#{_filename.inspect}"


        readVal = readVal.split(',').map {|val| val.strip}
        last = readVal[1].split("\n")
        last[0] = last[0].strip
        if last[0] == "network\r"
          last[0] = "network"
        end
        logger.info "First: #{readVal[0].inspect}"
        logger.info "Second: #{readVal[1].inspect}"
        logger.info "Last: #{last.inspect}"
        logger.info "HERE IS THE READVAL THINGY #{readVal.inspect}"


        if readVal[0] == "mobile_number" && readVal[1] == "network"
          CSV.foreach(file.path, headers: true) do |row|
            logger.info 'This is it-----'
            logger.info row.inspect

            if row["mobile_number"].present? && row["network"].present?
              # unless row["amount"].match(positive_numbers)
              #
              #   the_msg = 8
              # end
              if row["mobile_number"].scan(/\D/i).length == 0
                if !row["mobile_number"].match(positive_numbers)
                  the_msg = 4
                else
                  number = phone_formatter(row["mobile_number"])

                  number = 0 unless number

                  network = row['network'].upcase
                  # name = User.titling(row['recipient_name']) #name
                  # logger.info "NAME: #{name}"

                  unless networks.include?(network)
                    #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "Unknown network")
                    the_msg = 1
                    return the_msg
                  end

                  #check recipient name
                  #
                  # if row["recipient_name"].blank?
                  #   #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "No recipient name")
                  #
                  #   return the_msg = 3
                  # end
                  # if row["recipient_name"].match(positive_numbers)
                  #   #Recipient.create(recipient_name: name, mobile_number: number, disburse_status: false, client_code: client_code, status: false, fail_reason: "No recipient name")
                  #
                  #   return the_msg = 3
                  # end

                  if number.length == 12
                    @recipients_validate << NumberValidation.new(mobile_number: number, network: network, csv_upload_id: csv_upload_id, client_code: client_code, user_id: user_id)
                  else
                    the_msg = 4
                    #Recipient.create(recipient_name: name, mobile_number: number, network: network, disburse_status: false, client_code: client_code, status: false, fail_reason: "Wrong mobile number")
                  end
                end
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
      logger.info "#{@recipients_validate.inspect}"
      logger.info "#{the_msg}"
      logger.info "**********************************************************"


      if the_msg == 0
        NumberValidation.import @recipients_validate
        @recipients_validate.clear
      else
        @recipients_validate.clear
      end
    else
      return "7"
    end
    @recipients_validate.clear
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
    else
      false
    end
  end
end
