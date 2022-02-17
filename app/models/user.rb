class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  belongs_to :role
  belongs_to :client, class_name: "PremiumClient", foreign_key: :client_code
  # Include default devise modules. Others available are:
  # :confirmable, :lockable,  and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable
  # timeoutable
  validates :password, presence: true, :unless => :update?
  # validates :username, presence: true, :unless => :update?
  validates :password_confirmation, presence: true, :unless => :update?

  validates_uniqueness_of :username, :unless => :update?
  validates_uniqueness_of :email, :unless => :update?

  validates :mobile_number,:presence => { message: "Enter a 10 (02xxxxxxxx) or 12 (233xxxxxxxxx) digit phone number"},
            :numericality => {message: "Enter a 10 (02xxxxxxxx) or 12 (233xxxxxxxxx) digit phone number"},
            :length => { :minimum => 10, :maximum => 12 }
  validate :password_complexity
  validates :role_id, presence: {message: "Role cannot be left blank."}

  before_save :check_phone




  def password_complexity
    return if password.blank? || password =~ /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])/

    errors.add :password, 'Password not strong enough. Please use: 1 uppercase, 1 lowercase, 1 digit and 1 special character'
  end


  def self.client_results(client_code)
    where(client_code: client_code)
  end

  def s_user?
    self.role_id == 2
  end

  def admin?
    self.role_id == 3
  end

  def user?
    self.role_id == 4
  end

  def ultra?
    self.role_id == 5
  end

  def approver?
    self.role_id == 6
  end

  #
  def is_client
    not self.client_code.blank?
  end



  def update?
    self.persisted? #will it work?? yet to test
  end

  def phone_formatter(number)
    #changes phone number format to match 233247876554
    if number[0] == '0'
      num = number[1..number.size]
      "233"+num

    elsif number[0] == '+'
      number[1..number.size]

    elsif number[0] == '2'
      number
    else
      false
    end

  end

  def check_phone
    self.mobile_number = phone_formatter(mobile_number)
  end


  def self.titling(str)
    str_list = str.split

    str_list.map { |word| word.capitalize
    word.split("-").map{|w| w.capitalize }.join("-")
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
      " (other_names LIKE '#{name}' OR lastname LIKE '#{name}' OR CONCAT(other_names,' ',lastname) LIKE '#{name}') "
    end
  end

  def self.search_username(username)
    if username.strip == ""
      ""
    else
      username = "%#{username}%"
      " username LIKE '#{username}' "
    end
  end

  def self.search_role(role)
    if role.strip == ""
      ""
    else
      role = "%#{role}%"
      " role LIKE '#{role}' "
    end
  end

  def self.joiner
    joins(:role).select("users.*, roles.role")
  end

  def self.active
    where(active_status: true)
  end



end
