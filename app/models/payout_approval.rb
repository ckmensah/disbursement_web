class PayoutApproval < ActiveRecord::Base
  belongs_to :approver, class_name: "Approver", foreign_key: :approver_code
end
