class Payout < ActiveRecord::Base
  belongs_to :recipient_group, class_name: "RecipientGroup", foreign_key: :group_id
  belongs_to :app_cat, class_name: "ApproversCategory", foreign_key: :approver_cat_id
  belongs_to :user
  belongs_to :deleted_user, class_name: "DeletedUser", foreign_key: :user_id
  #params.require(:payout).permit(:user_id,:needs_approval,:group_id, :title, :approval_status, :approver_cat_id, :comment, :processed)

  validates :group_id, presence: true
  validates :title, presence: true
  #validates :approver_cat_id, presence: true if :needs_approval?

  def needs_approval?
    self.needs_approval
  end

  def self.notify_approvers(payout_id, category_id)
    category = ApproversCategory.find(category_id)
    approvers_ids = category.approvers.map {|approver| approver.id}
    notify_these = PayoutApproval.where(payout_id: payout_id, approver_code: approvers_ids, notified: false)
    if notify_these.blank? #empty list
      return false
    end
    #############################################################
    #############################################################
    #notify according to levels
    notify_these = notify_these.sort_by {|obj|
      obj.level

      logger.info "Levels::::::::::#{obj.level}"
    }
    logger.info "Those To Notify::::::::::#{notify_these.inspect}"

    approval_obj = notify_these[0]
    approver_code = approval_obj.approver_code #next approver
    user = Approver.find(approver_code).user
    mobile_number = user.mobile_number

    #get message_sender_id
    client_code = user.client.client_code

    sms_key = user.client.sms_key
    ##############################################################
    ##############################################################


    if category.leveled

      Transaction.sendmsg(mobile_number, "Please approve payout", client_code, sms_key)
      approval_obj.notified = true
      approval_obj.save

    else
      #send to all
      #get if notified false
      notify_these.each do |approval|
        user = Approver.find(approval.approver_code).user
        mobile_number = user.mobile_number

        Transaction.sendmsg(mobile_number, "Please approve payout", client_code, sms_key)
        approval.notified = true
        approval.save
      end
    end
  end


  def see_approve_btn(payout_id, user_id)
    payout = Payout.find(payout_id)
    category = ApproversCategory.find(payout.approver_cat_id)

    approvers_ids = category.approvers.map {|approver| approver.id}
    approval_obj = PayoutApproval.where(payout_id: payout_id, approver_code: approvers_ids, approved: false).order("id asc").first

    if approval_obj.present? #empty list
      return true
    else
      return false
    end

    if category.leveled
      # show_these_button = show_these_button.sort_by {|obj| obj.level}
      # approval_obj = show_these_button[0]
      approver_code = approval_obj.approver_code #next approver
      user = Approver.find(approver_code).user
      return user.id == user_id
    else
      approval_obj.each do |approval|
        logger.info "APPROVAL: #{approval.inspect}"
        user = Approver.find(approval.approver_code).user
        logger.info "USER: #{user.inspect}"
        return user.id == user_id
      end
    end
  end

  def approve(payout_id, user_id, approve = true, dis_reason = "")
    logger.info "APPROVE FUNCTION STARTED"
    payout = Payout.find(payout_id)
    category = ApproversCategory.find(payout.approver_cat_id)
    approver = Approver.where(user_approver_id: user_id, status: true, changed_status: false, category_id: category.id).order('id desc')[0]

    logger.info "APPROVER: #{approver.inspect}"
    approval = PayoutApproval.where(approver_code: approver.approver_code, payout_id: payout_id).order('id desc')[0]

    if approval.blank? #nil?
      logger.info "APPROVAL BLANK..."
      return false
    end

    if approve
      approval.approved = true
      approval.save #approval done
    else
      # approval.approved = false
      # approval.save #approval done
      payout.update(disapprove: true, disapproval_reason: dis_reason)
      approval.update(disapprove: true, approved: false, disapproval_reason: dis_reason)
      return false
    end


    logger.info "APPROVAL OBJECT: #{approval.inspect}"

    #check if completed
    approvers_ids = category.approvers.map {|approver| approver.id}

    approvals_left = PayoutApproval.where(payout_id: payout_id, approver_code: approvers_ids, approved: false)
    if approvals_left.blank?
      payout.approval_status = true
      payout.save #completed
    end
    #return true for success
    true

  end
end




# class Payout < ActiveRecord::Base
#   belongs_to :recipient_group, class_name: "RecipientGroup", foreign_key: :group_id
#   belongs_to :app_cat, class_name: "ApproversCategory", foreign_key: :approver_cat_id
#   belongs_to :user
#   belongs_to :deleted_user, class_name: "DeletedUser", foreign_key: :user_id
#   #params.require(:payout).permit(:user_id,:needs_approval,:group_id, :title, :approval_status, :approver_cat_id, :comment, :processed)
#
#   validates :group_id, presence: true
#   validates :title, presence: true
#   #validates :approver_cat_id, presence: true if :needs_approval?
#
#   def needs_approval?
#     self.needs_approval
#   end
#
#   def self.notify_approvers(payout_id, category_id)
#     category = ApproversCategory.find(category_id)
#     approvers_ids = category.approvers.map {|approver| approver.id}
#     notify_these = PayoutApproval.where(payout_id: payout_id, approver_code: approvers_ids, notified: false)
#     if notify_these.blank? #empty list
#       return false
#     end
#     #############################################################
#     #############################################################
#     #notify according to levels
#     notify_these = notify_these.sort_by {|obj|
#       obj.level
#
#       logger.info "Levels::::::::::#{obj.level}"
#     }
#     logger.info "Those To Notify::::::::::#{notify_these.inspect}"
#
#     approval_obj = notify_these[0]
#     approver_code = approval_obj.approver_code #next approver
#     user = Approver.find(approver_code).user
#     mobile_number = user.mobile_number
#
#     #get message_sender_id
#     client_code = user.client.client_code
#
#     sms_key = user.client.sms_key
#     ##############################################################
#     ##############################################################
#
#
#     if category.leveled
#
#       Transaction.sendmsg(mobile_number, "Please approve payout", client_code, sms_key)
#       approval_obj.notified = true
#       approval_obj.save
#
#     else
#       #send to all
#       #get if notified false
#       notify_these.each do |approval|
#         user = Approver.find(approval.approver_code).user
#         mobile_number = user.mobile_number
#
#         Transaction.sendmsg(mobile_number, "Please approve payout", client_code, sms_key)
#         approval.notified = true
#         approval.save
#       end
#     end
#   end
#
#
#   def see_approve_btn(payout_id, user_id)
#     payout = Payout.find(payout_id)
#     category = ApproversCategory.find(payout.approver_cat_id)
#
#     approvers_ids = category.approvers.map {|approver| approver.id}
#     show_these_button = PayoutApproval.where(payout_id: payout_id, approver_code: approvers_ids, approved: false)
#
#     if show_these_button.blank? #empty list
#       return false
#     end
#
#     if category.leveled
#       show_these_button = show_these_button.sort_by {|obj| obj.level}
#       approval_obj = show_these_button[0]
#       approver_code = approval_obj.approver_code #next approver
#       user = Approver.find(approver_code).user
#       return user.id == user_id
#     else
#       show_these_button.each do |approval|
#         logger.info "APPROVAL: #{approval.inspect}"
#         user = Approver.find(approval.approver_code).user
#         logger.info "USER: #{user.inspect}"
#         return user.id == user_id
#       end
#     end
#   end
#
#   def approve(payout_id, user_id, approve = true, dis_reason = "")
#     logger.info "APPROVE FUNCTION STARTED"
#     payout = Payout.find(payout_id)
#     category = ApproversCategory.find(payout.approver_cat_id)
#     approver = Approver.where(user_approver_id: user_id, status: true, changed_status: false, category_id: category.id).order('id desc')[0]
#
#     logger.info "APPROVER: #{approver.inspect}"
#     approval = PayoutApproval.where(approver_code: approver.approver_code, payout_id: payout_id).order('id desc')[0]
#     if approval.blank? #nil?
#       logger.info "APPROVAL BLANK..."
#       return false
#     end
#
#     if approve
#       approval.approved = true
#       approval.save #approval done
#     else
#       # approval.approved = false
#       # approval.save #approval done
#       payout.update(disapprove: true, disapproval_reason: dis_reason)
#       approval.update(disapprove: true, approved: false, disapproval_reason: dis_reason)
#       return false
#     end
#
#
#     logger.info "APPROVAL OBJECT: #{approval.inspect}"
#
#     #check if completed
#     approvers_ids = category.approvers.map {|approver| approver.id}
#
#     approvals_left = PayoutApproval.where(payout_id: payout_id, approver_code: approvers_ids, approved: false)
#     if approvals_left.blank?
#       payout.approval_status = true
#       payout.save #completed
#     end
#     #return true for success
#     true
#
#   end
# end
