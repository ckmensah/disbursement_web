class PremiumClient < ActiveRecord::Base

  validates :company_name, presence: true
  validates :email, presence: true
  validates :contact_number, :presence => {message: "Enter a 10 (02xxxxxxxx) or 12 (233xxxxxxxxx) digit phone number"},
            :numericality => {message: "Enter a 10 (02xxxxxxxx) or 12 (233xxxxxxxxx) digit phone number"},
            :length => {:minimum => 10, :maximum => 12}

  validates :client_id, presence: true
  validates :client_key, presence: true
  validates :secret_key, presence: true
  validates :sender_id, presence: true, :length => {:minimum => 4, :maximum => 8}

  has_many :recipients, class_name: "Recipient", foreign_key: :client_code

  validates :acronym, presence: {message: "Acronym is needed in tagging transactions"}


  self.table_name = "premium_clients"
  self.primary_key = :client_code
  #belongs_to :subscription, class_name: "Subscription", foreign_key: :subscriber_code
  #has_many :accounts, class_name: "ClientAcctNumber", foreign_key: :client_code
  #has_one :api_key, class_name: "ApiKey", foreign_key: :client_code
  #has_one :premium_service, class_name: "PremiumService", foreign_key: :client_id

  def self.generate_client_code
    sql = "select nextval('client_seq')"
    val = ActiveRecord::Base.connection.execute(sql)
    val = val.values[0][0]

    "CL#{val}"

  end

  def self.active
    where(status: true, changed_status: false)
  end


  before_save do

    self.created_at ||= DateTime.now if self.created_at.nil?
    self.updated_at ||= DateTime.now if self.updated_at.nil?
  end

  protected

  def timestamp_attributes_for_create
    [:created_at]
  end

end
