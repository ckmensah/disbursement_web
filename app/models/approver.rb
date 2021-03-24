class Approver < ActiveRecord::Base

  belongs_to :user, foreign_key: :user_approver_id
  belongs_to :category, foreign_key: :category_id, class_name: "ApproversCategory"

  validates :category_id, presence: true, allow_blank: false
  validates :user_approver_id, presence: true, allow_blank: false
  self.primary_key = :approver_code
  # belongs_to :subscription, class_name: "Subscription", foreign_key: :subscriber_code
  def self.generate_approver_code
    sql = "select nextval('approver_seq')"
    val = ActiveRecord::Base.connection.execute(sql)
    val = val.values[0][0]

    "APPR#{val}"
  end

  def is_blank
  end


  def self.active
    where(changed_status: false, status: true)
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
