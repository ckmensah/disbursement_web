class Recipient < ActiveRecord::Base
  require 'csv'

  has_one :bank_transaction, class_name: "Transaction", foreign_key: :transaction_id, primary_key: :transaction_ref_id

  belongs_to :group, class_name: "RecipientGroup", foreign_key: :group_id
  belongs_to :a_client, class_name: "PremiumClient", foreign_key: :client_code


  # params.require(:recipient).permit(:disburse_status, :transaction_id, :mobile_number, :network, :amount, :group_id, :status, :changed_status)
  validates :mobile_number, presence: true, allow_blank: false, :numericality => {greater_than_or_equal_to: 0, allow_nil: true, message: "Invalid mobile number"}
  validates :recipient_name, presence: true, allow_blank: false
  validates :network, presence: true, allow_blank: false
  # validates :reference, presence: {message: "Your Reference cannot be less than 10 characters or more than 50."}, allow_blank: false, length: {:maximum => 50, :minimum=> 10}
  validates :amount, presence: true, allow_blank: false, :numericality => {greater_than_or_equal_to: 0, allow_nil: true,message: "Invalid amount"}


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

  def self.active
    where(status: true, changed_status: false)
  end

  def self.failed
    where(status: false, changed_status: false)
  end

  #########################################################################################
  def self.import_contacts(file, group_id)
    @recipients = []
    networks = ['MTN', 'AIR', 'TIG', 'VOD']
    #mobile_number, network, amount
    the_msg = 0
    readVal = file.read
    readVal = readVal.split(',').map {|val| val.strip}
    last = readVal[3].split("\n")
    last[0] = last[0].strip
    if last[0] == "amount\r"
      last[0] = "amount"
    end

    logger.info "Last: #{last.inspect}"
    logger.info "HERE IS THE READVAL THINGY #{readVal.inspect}"

    if readVal[0] == "recipient_name" && readVal[1] == "mobile_number" && readVal[2] == "network" && last[0] == "amount"
      CSV.foreach(file.path, headers: true) do |row|
        logger.info 'This is it-----'
        logger.info row.inspect

#Recipient name, mobile_number, network, amount
        if row["mobile_number"].present? && row["network"].present? && row["amount"].present? && row["recipient_name"].present?

          if row["mobile_number"].scan(/\D/i).length == 0
            number = phone_formatter(row["mobile_number"])

            number = 0 unless number

            network = row['network'].upcase
            name = User.titling(row['recipient_name']) #name
            logger.info "NAME: #{name}"

            unless networks.include?(network)
              Recipient.create(recipient_name: name, mobile_number: number, group_id: group_id, status: false, fail_reason: "Unknown network")
              the_msg = 1
              return the_msg
            end

            #check recipient name
            if row["recipient_name"].blank?
              Recipient.create(recipient_name: name, mobile_number: number, group_id: group_id, status: false, fail_reason: "No recipient name")

              return the_msg = 1
            end

            if number.length == 12
              check = Recipient.where(mobile_number: number, network: network, group_id: group_id).exists?
              if check
                the_msg = 1
              else
                final_check = Recipient.where(mobile_number: number, group_id: group_id).exists?
                if final_check
                  the_msg = 1
                  Recipient.create(recipient_name: name, mobile_number: number, group_id: group_id, status: false, fail_reason: "Mobile money number already exists")
                else
                  @recipients << Recipient.new(recipient_name: name, mobile_number: number, network: network, amount: row['amount'], group_id: group_id)
                end
              end
            else
              the_msg = 1
              Recipient.create(recipient_name: name, mobile_number: number, network: network, group_id: group_id, status: false, fail_reason: "Wrong mobile number")
            end
          else
            the_msg = 1
            Recipient.create(recipient_name: name, mobile_number: number, network: network, group_id: group_id, status: false, fail_reason: "Wrong mobile number format")
          end
        else
          the_msg = 1
          Recipient.create(recipient_name: name, mobile_number: number, network: network, group_id: group_id, status: false, fail_reason: "Invalid row, missing parameters")
        end
      end
    else
      return "2"
    end
    Recipient.import @recipients
    @recipients.clear
    return the_msg
  end
#########################################################################################

end
