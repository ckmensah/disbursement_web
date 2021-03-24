class ApproversCategory < ActiveRecord::Base
  has_many :approvers, class_name: "Approver", foreign_key: :category_id


  validates :category_name, presence: true
  validates :client_code, presence: true
  validates_uniqueness_of :category_name

  def self.active
    where(status: true, changed_status: false)
  end
end
