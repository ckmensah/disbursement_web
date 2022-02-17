class PayoutsController < ApplicationController
  before_action :authenticate_user!, except: [:disburse_callback]
  before_action :set_payout, only: [:show, :edit, :update, :destroy, :approve_payout]


  # GET /payouts
  # GET /payouts.json
  def index
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    if params[:per_page] && params[:per_page].size > 0
      per_page = params[:per_page]
    else
      per_page = Transaction.per_page
    end

    if params[:page] && params[:page].size > 0
      page = params[:page].to_i
    else
      page = 1
    end


    if current_user.ultra? || current_user.s_user?
      @payouts = Payout.paginate(:page => page, :per_page => 10).order("updated_at desc")
    else

      @payouts = Payout.joins(:user).where('users.client_code = ?', current_user.client_code).paginate(:page => page, :per_page => per_page).order('payouts.updated_at desc')
    end
    @transactions = Transaction.joiner(current_user.client_code).paginate(:page => page, :per_page => per_page).order("updated_at desc")
    # respond_to do |format|
    if current_user.is_client && @user_app.needs_approval
      render 'payouts/index'
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render 'payouts/index'
    end
    # end
  end

  def payout_index
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    if params[:per_page] && params[:per_page].size > 0
      per_page = params[:per_page]
    else
      per_page = Transaction.per_page
    end

    if params[:page] && params[:page].size > 0
      page = params[:page].to_i
    else
      page = 1
    end


    if current_user.ultra? || current_user.s_user?
      @payouts = Payout.paginate(:page => page, :per_page => 10).order("created_at desc")
    else

      @payouts = Payout.joins(:user).where('users.client_code = ?', current_user.client_code).paginate(:page => page, :per_page => per_page).order('payouts.created_at desc')
    end
    @transactions = Transaction.joiner(current_user.client_code).paginate(:page => page, :per_page => per_page).order("created_at desc")
    if current_user.is_client && @user_app.needs_approval
      render 'payouts/index'
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render 'payouts/index'
    end
  end

  # GET /payouts/1
  # GET /payouts/1.json
  def show

    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @recipients = Recipient.where(group_id: @payout.group_id, status: true, changed_status: false)
    @approvers = PayoutApproval.where(payout_id: @payout.id).order('level ASC')

    logger.info "Recipients::::::#{@recipients.inspect}"
    logger.info "Approvers:::::::#{@approvers.inspect}"

    logger.info "user_app:::::::#{@user_app.inspect}"

    if current_user.is_client && @user_app.needs_approval
      render 'payouts/show'
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render 'payouts/show'
    end

  end

  def disburse
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    group_id = params[:group_id]
    client_code = params[:client_code]
    disburse_type = params[:disburse_type]
    payout_id = params[:payout_id]

    logger.info "INCOMING PARAMS: group_id #{group_id}, client_code: #{client_code}," +
                    "disburse_type: #{disburse_type}, payout_id: #{payout_id}\n"
    logger.info "-------------------------------------------------------------------"
    recipients = Recipient.where(group_id: group_id, status: true, changed_status: false)

    logger.info "RECIPIENTS: #{recipients.inspect}"
    response = RecipientGroup.payout(recipients, client_code, payout_id, disburse_type)


    logger.info "RESPONSE: #{response.inspect}"

    respond_to do |format|

      format.html {redirect_to payouts_path, notice: response['message']}
      format.json {render :show, status: :created, location: @payout}
    end

  end

  def disburse_callback
    logger.info "Callback Working"
    logger.info "COntenet of the params " + params.inspect
    # {"message": "Success", "trans_status": "000/200", "trans_id": "MP151224.1621.C00005", "trans_ref": "1512241630284"}

    message = params[:message]
    trans_status = params[:trans_status]
    trans_id = params[:trans_id]
    trans_ref = params[:trans_ref]

    check_for_callback = CallbackResp.where(mm_trnx_id: trans_ref).exists?

    if check_for_callback

    elsif !check_for_callback
      trans_status_split = trans_status.split("/")

      trans_info = Transaction.where(transaction_ref_id: trans_ref).order(updated_at: :desc).first
      recipient_info = Recipient.where(id: trans_info.recipient_id).order(updated_at: :desc).first

      logger.info trans_info.inspect
      logger.info "###############################################################"
      logger.info "###############################################################"
      logger.info recipient_info.inspect
      logger.info "###############################################################"
      logger.info "###############################################################"
      if trans_status_split[0] == '000' || message == "Success"
        update_trans = Transaction.where(transaction_ref_id: trans_ref).update_all(status: true, err_code: trans_status_split[0], nw_resp: message)
        if trans_info.phone_number.present?
        # phone_numb = trans_info.phone_number[0]
        # logger.info " @@@@@@@@@@@@@@  #{phone_numb.inspect} @@@@@@@@@@@@@@@@@@@"
        sms = Transaction.sendPayoutMsg(trans_info.phone_number, trans_info.payout_id, recipient_info.client_code, trans_info.amount, trans_ref, recipient_info.recipient_name, trans_info.reference)
        else
        sms = Transaction.sendPayoutMsg(trans_info.mobile_number, trans_info.payout_id, recipient_info.client_code, trans_info.amount, trans_ref, recipient_info.recipient_name, trans_info.reference)
        end
      else
        update_trans = Transaction.where(transaction_ref_id: trans_ref).update_all(status: false, err_code: trans_status_split[0], nw_resp: message)
      end


      logger.info "###############################################################"
      logger.info "###############################################################"
      logger.info update_trans.inspect
      logger.info "###############################################################"
      logger.info "###############################################################"
      logger.info trans_info.inspect
      logger.debug "the content of trans_status split " + trans_status_split[0].inspect
      logger.info "###############################################################"
      logger.info "###############################################################"

      n = CallbackResp.create(
          mobile_number: trans_info.mobile_number,
          trnx_id: trans_id,
          network: trans_info.network,
          mm_trnx_id: trans_ref,
          resp_code: trans_status,
          resp_desc: message,
          )

      n.save


      logger.info "###############################################################"
      logger.info "###############################################################"
      logger.info update_trans.inspect
      logger.info "###############################################################"
      logger.info "###############################################################"
      logger.info "####################### SMS INFO ############################"
      logger.info sms.inspect
      logger.info "###############################################################"
    else
    end

    render :nothing => true, :status => trans_status_split[0], :content_type => 'application/json'
    # render fallback_location: transactions_path, :status => trans_status_split[0], notice: "Your transactions have been processed"
    # respond_to do |format|
    #   format.html {redirect_to transactions_index_path,:status => trans_status_split[0], notice: "Your transactions have been processed."}
    # end
  end


  def set_approver_levels
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    category_id = params[:category_id]
    @approvers = ApproversCategory.find(category_id).approvers.active
  end

  # GET /payouts/new
  def new
    @payout = Payout.new

    if current_user.ultra? || current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
      @approver_categories = ApproversCategory.all
      @recipient_group = RecipientGroup.all
    elsif current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
      @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
      @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
    else
      @approver_categories = []
      @recipient_group = []
    end
    if current_user.is_client && @user_app.needs_approval
      render 'payouts/new'
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render 'payouts/new'
    end
  end

  # GET /payouts/1/edit
  def edit
    if current_user.ultra? || current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
      @approver_categories = ApproversCategory.all
      @recipient_group = RecipientGroup.all

    elsif current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
      @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
      @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
    else
      @approver_categories = []
      @recipient_group = []
    end

    if current_user.is_client && @user_app.needs_approval
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first

      render :edit
    elsif current_user.is_client && !@user_app.needs_approval
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).first
      render :edit
    end
  end

  def approve_payout
    respond_to do |format|

      if params[:disapprove]
        logger.info "DISAPPROVE PAYOUT STARTED..."
        @payout.approve(@payout.id, current_user.id, false, params[:dis_reason])
        logger.info "DISAPPROVE DONE.."
        url = request.referer
        notice = 'Payout disapproved.'
      else
        logger.info "APPROVE PAYOUT STARTED..."
        @payout.approve(@payout.id, current_user.id)
        logger.info "APPROVE DONE.."
        Payout.notify_approvers(@payout.id, @payout.approver_cat_id)
        url = request.referer.nil? ? payouts_path : request.referer
        notice = 'Payout Successfully approved'
      end

      format.html {redirect_to url, notice: notice}
    end

  end

  # POST /payouts
  # POST /payouts.json
  def create
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @payout = Payout.new(payout_params)

    if current_user.is_client && @user_app.needs_approval
      respond_to do |format|
        if @payout.save

          #create approvals
          #"approval"=>{"APPR3"=>"1"}
          if params[:approval].present?
            params[:approval].each do |approver_code, level|
              PayoutApproval.create(
                  payout_id: @payout.id,
                  approver_code: approver_code,
                  level: level
              )
            end

            #notify
            Payout.notify_approvers(@payout.id, @payout.approver_cat_id)
          else
            PayoutApproval.create(
                payout_id: @payout.id,
                approver_code: '',
                level: ''
            )
          end


          format.html {redirect_to payouts_path, notice: 'Payout was successfully created.'}
          format.json {render :show, status: :created, location: @payout}
        else
          if current_user.ultra? || current_user.s_user?
            @approver_categories = ApproversCategory.all
            @recipient_group = RecipientGroup.all
          elsif current_user.is_client
            @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
            @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
          else
            @approver_categories = []
            @recipient_group = []
          end


          format.html {render :new}
          format.json {render json: @payout.errors, status: :unprocessable_entity}
        end
      end
    elsif current_user.is_client && !@user_app.needs_approval
      respond_to do |format|
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    else
      respond_to do |format|
        if @payout.save

          #create approvals
          #"approval"=>{"APPR3"=>"1"}
          if params[:approval].present?
            params[:approval].each do |approver_code, level|
              PayoutApproval.create(
                  payout_id: @payout.id,
                  approver_code: approver_code,
                  level: level
              )
            end

            #notify
            Payout.notify_approvers(@payout.id, @payout.approver_cat_id)
          else
            PayoutApproval.create(
                payout_id: @payout.id,
                approver_code: '',
                level: ''
            )
          end


          format.html {redirect_to payouts_path, notice: 'Payout was successfully created.'}
          format.json {render :show, status: :created, location: @payout}
        else
          if current_user.ultra? || current_user.s_user?
            @approver_categories = ApproversCategory.all
            @recipient_group = RecipientGroup.all
          elsif current_user.is_client
            @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
            @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
          else
            @approver_categories = []
            @recipient_group = []
          end


          format.html {render :new}
          format.json {render json: @payout.errors, status: :unprocessable_entity}
        end
      end
    end
  end

  # PATCH/PUT /payouts/1
  # PATCH/PUT /payouts/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    if current_user.is_client && @user_app.needs_approval
      respond_to do |format|
        if @payout.update(payout_params)
          format.html {redirect_to payouts_path, notice: 'Payout was successfully updated.'}
          format.json {render :show, status: :ok, location: @payout}
        else
          if current_user.ultra? || current_user.s_user?
            @approver_categories = ApproversCategory.all
            @recipient_group = RecipientGroup.all
          elsif current_user.is_client
            @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
            @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
          else
            @approver_categories = []
            @recipient_group = []
          end

          format.html {render :edit}
          format.json {render json: @payout.errors, status: :unprocessable_entity}
        end
      end
    elsif current_user.is_client && !@user_app.needs_approval
      respond_to do |format|
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    else
      respond_to do |format|
        if @payout.update(payout_params)
          format.html {redirect_to payouts_path, notice: 'Payout was successfully updated.'}
          format.json {render :show, status: :ok, location: @payout}
        else
          if current_user.ultra? || current_user.s_user?
            @approver_categories = ApproversCategory.all
            @recipient_group = RecipientGroup.all
          elsif current_user.is_client
            @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
            @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
          else
            @approver_categories = []
            @recipient_group = []
          end

          format.html {render :edit}
          format.json {render json: @payout.errors, status: :unprocessable_entity}
        end
      end
    end


    # respond_to do |format|
    #   if @user_app.needs_approval
    #
    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end
  end

  # DELETE /payouts/1
  # DELETE /payouts/1.json
  def destroy
    @payout.destroy
    respond_to do |format|
      format.html {redirect_to payouts_url, notice: 'Payout was successfully destroyed.'}
      format.json {head :no_content}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_payout
    @payout = Payout.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def payout_params
    params.require(:payout).permit(:disapproval_reason, :user_id, :needs_approval, :group_id, :title, :approval_status, :approver_cat_id, :comment, :processed)
  end

end












# class PayoutsController < ApplicationController
#   before_action :authenticate_user!, except: [:disburse_callback]
#   before_action :set_payout, only: [:show, :edit, :update, :destroy, :approve_payout]
#
#
#   # GET /payouts
#   # GET /payouts.json
#   def index
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     if params[:per_page] && params[:per_page].size > 0
#       per_page = params[:per_page]
#     else
#       per_page = Transaction.per_page
#     end
#
#     if params[:page] && params[:page].size > 0
#       page = params[:page].to_i
#     else
#       page = 1
#     end
#
#
#     if current_user.ultra? || current_user.s_user?
#       @payouts = Payout.paginate(:page => page, :per_page => 10).order("updated_at desc")
#     else
#
#       @payouts = Payout.joins(:user).where('users.client_code = ?', current_user.client_code).paginate(:page => page, :per_page => per_page).order('payouts.updated_at desc')
#     end
#     @transactions = Transaction.joiner(current_user.client_code).paginate(:page => page, :per_page => per_page).order("updated_at desc")
#     # respond_to do |format|
#     if current_user.is_client && @user_app.needs_approval
#       render 'payouts/index'
#     elsif current_user.is_client && !@user_app.needs_approval
#       render 'transactions/index'
#       # format.html {redirect_to :controller => 'transactions', :action => 'index'}
#       #format.json {render json: {status: true}}
#     else
#       render 'payouts/index'
#     end
#     # end
#   end
#
#   def payout_index
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     if params[:per_page] && params[:per_page].size > 0
#       per_page = params[:per_page]
#     else
#       per_page = Transaction.per_page
#     end
#
#     if params[:page] && params[:page].size > 0
#       page = params[:page].to_i
#     else
#       page = 1
#     end
#
#
#     if current_user.ultra? || current_user.s_user?
#       @payouts = Payout.paginate(:page => page, :per_page => 10).order("created_at desc")
#     else
#
#       @payouts = Payout.joins(:user).where('users.client_code = ?', current_user.client_code).paginate(:page => page, :per_page => per_page).order('payouts.created_at desc')
#     end
#     @transactions = Transaction.joiner(current_user.client_code).paginate(:page => page, :per_page => per_page).order("created_at desc")
#     if current_user.is_client && @user_app.needs_approval
#       render 'payouts/index'
#     elsif current_user.is_client && !@user_app.needs_approval
#       render 'transactions/index'
#       # format.html {redirect_to :controller => 'transactions', :action => 'index'}
#       #format.json {render json: {status: true}}
#     else
#       render 'payouts/index'
#     end
#   end
#
#   # GET /payouts/1
#   # GET /payouts/1.json
#   def show
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @recipients = Recipient.where(group_id: @payout.group_id, status: true, changed_status: false)
#     @approvers = PayoutApproval.where(payout_id: @payout.id).order('level ASC')
#
#     logger.info "Recipients::::::#{@recipients.inspect}"
#     logger.info "Approvers:::::::#{@approvers.inspect}"
#
#     if current_user.is_client && @user_app.needs_approval
#       render 'payouts/show'
#     elsif current_user.is_client && !@user_app.needs_approval
#       render 'transactions/index'
#       # format.html {redirect_to :controller => 'transactions', :action => 'index'}
#       #format.json {render json: {status: true}}
#     else
#       render 'payouts/show'
#     end
#
#   end
#
#   def disburse
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     group_id = params[:group_id]
#     client_code = params[:client_code]
#     disburse_type = params[:disburse_type]
#     payout_id = params[:payout_id]
#
#     logger.info "INCOMING PARAMS: group_id #{group_id}, client_code: #{client_code}" +
#                     "disburse_type: #{disburse_type}, payout_id: #{payout_id}\n"
#     logger.info "-------------------------------------------------------------------"
#     recipients = Recipient.where(group_id: group_id, status: true, changed_status: false)
#
#     logger.info "RECIPIENTS: #{recipients.inspect}"
#     response = RecipientGroup.payout(recipients, client_code, payout_id, disburse_type)
#
#
#     logger.info "RESPONSE: #{response.inspect}"
#
#     respond_to do |format|
#
#       format.html {redirect_to payouts_path, notice: response['message']}
#       format.json {render :show, status: :created, location: @payout}
#     end
#
#   end
#
#   def disburse_callback
#     logger.info "Callback Working"
#     logger.info params.inspect
#     # {"message": "Success", "trans_status": "000/200", "trans_id": "MP151224.1621.C00005", "trans_ref": "1512241630284"}
#
#     message = params[:message]
#     trans_status = params[:trans_status]
#     trans_id = params[:trans_id]
#     trans_ref = params[:trans_ref]
#
#     check_for_callback = CallbackResp.where(mm_trnx_id: trans_ref).exists?
#
#     if check_for_callback
#
#     elsif !check_for_callback
#       trans_status_split = trans_status.split("/")
#
#       trans_info = Transaction.where(transaction_ref_id: trans_ref).order('updated_at DESC')[0]
#       recipient_info = Recipient.where(id: trans_info.recipient_id).order('updated_at DESC')[0]
#
#       logger.info trans_info.inspect
#       logger.info "###############################################################"
#       logger.info "###############################################################"
#       logger.info recipient_info.inspect
#       logger.info "###############################################################"
#       logger.info "###############################################################"
#       if trans_status_split[0] == '000' || message == "Success"
#         update_trans = Transaction.where(transaction_ref_id: trans_ref).update_all(status: true, err_code: trans_status_split[0], nw_resp: message)
#         sms = Transaction.sendPayoutMsg(trans_info.mobile_number, trans_info.payout_id, recipient_info.client_code, trans_info.amount, trans_ref, recipient_info.recipient_name)
#       else
#         update_trans = Transaction.where(transaction_ref_id: trans_ref).update_all(status: false, err_code: trans_status_split[0], nw_resp: message)
#       end
#
#
#       logger.info "###############################################################"
#       logger.info "###############################################################"
#       logger.info update_trans.inspect
#       logger.info "###############################################################"
#       logger.info "###############################################################"
#       logger.info trans_info.inspect
#       logger.info "###############################################################"
#       logger.info "###############################################################"
#
#       n = CallbackResp.create(
#           mobile_number: trans_info.mobile_number,
#           trnx_id: trans_id,
#           network: trans_info.network,
#           mm_trnx_id: trans_ref,
#           resp_code: trans_status,
#           resp_desc: message,
#           )
#
#       n.save
#
#
#       logger.info "###############################################################"
#       logger.info "###############################################################"
#       logger.info update_trans.inspect
#       logger.info "###############################################################"
#       logger.info "###############################################################"
#       logger.info "####################### SMS INFO ############################"
#       logger.info sms.inspect
#       logger.info "###############################################################"
#     else
#     end
#
#   render :nothing => true, :status => trans_status_split[0], :content_type => 'application/json'
# end
#
#
# def set_approver_levels
#   if current_user.is_client
#     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#   else
#     @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#   end
#   category_id = params[:category_id]
#   @approvers = ApproversCategory.find(category_id).approvers.active
# end
#
# # GET /payouts/new
# def new
#   @payout = Payout.new
#
#   if current_user.ultra? || current_user.s_user?
#     @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
#     @approver_categories = ApproversCategory.all
#     @recipient_group = RecipientGroup.all
#   elsif current_user.is_client
#     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
#     @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
#     @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
#   else
#     @approver_categories = []
#     @recipient_group = []
#   end
#   if current_user.is_client && @user_app.needs_approval
#     render 'payouts/new'
#   elsif current_user.is_client && !@user_app.needs_approval
#     render 'transactions/index'
#     # format.html {redirect_to :controller => 'transactions', :action => 'index'}
#     #format.json {render json: {status: true}}
#   else
#     render 'payouts/new'
#   end
# end
#
# # GET /payouts/1/edit
# # def edit
# #   if current_user.ultra? || current_user.s_user?
# #     @approver_categories = ApproversCategory.all
# #     @recipient_group = RecipientGroup.all
# #   elsif current_user.is_client
# #     @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
# #     @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
# #   else
# #     @approver_categories = []
# #     @recipient_group = []
# #   end
# #
# #   if current_user.is_client && @user_app.needs_approval
# #     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
# #
# #     render :edit
# #   elsif current_user.is_client && !@user_app.needs_approval
# #     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
# #     render 'transactions/index'
# #     # format.html {redirect_to :controller => 'transactions', :action => 'index'}
# #     #format.json {render json: {status: true}}
# #   else
# #     @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
# #     render :edit
# #   end
# # end
#
#   def edit
#     if current_user.ultra? || current_user.s_user?
#       @approver_categories = ApproversCategory.all
#       @recipient_group = RecipientGroup.all
#     elsif current_user.is_client
#       @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
#       @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
#     else
#       @approver_categories = []
#       @recipient_group = []
#     end
#     if @user_app == nil
#       if current_user.is_client
#         @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
#         render :edit
#       else
#         @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
#         render :edit
#       end
#     else
#       if current_user.is_client && @user_app.needs_approval
#         @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
#
#         render :edit
#       elsif current_user.is_client && !@user_app.needs_approval
#         @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
#         render 'transactions/index'
#         # format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         #format.json {render json: {status: true}}
#       else
#         @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
#         render :edit
#       end
#     end
#
#   end
#
# def approve_payout
#   respond_to do |format|
#
#     if params[:disapprove]
#       logger.info "DISAPPROVE PAYOUT STARTED..."
#       @payout.approve(@payout.id, current_user.id, false, params[:dis_reason])
#       logger.info "DISAPPROVE DONE.."
#       url = request.referer
#       notice = 'Payout disapproved.'
#     else
#       logger.info "APPROVE PAYOUT STARTED..."
#       @payout.approve(@payout.id, current_user.id)
#       logger.info "APPROVE DONE.."
#       Payout.notify_approvers(@payout.id, @payout.approver_cat_id)
#       url = request.referer.nil? ? payouts_path : request.referer
#       notice = 'Payout Successfully approved'
#     end
#
#     format.html {redirect_to url, notice: notice}
#   end
#
# end
#
# # POST /payouts
# # POST /payouts.json
# def create
#   if current_user.is_client
#     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#   else
#     @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#   end
#   @payout = Payout.new(payout_params)
#
#   if current_user.is_client && @user_app.needs_approval
#     respond_to do |format|
#       if @payout.save
#
#         #create approvals
#         #"approval"=>{"APPR3"=>"1"}
#         if params[:approval].present?
#           params[:approval].each do |approver_code, level|
#             PayoutApproval.create(
#                 payout_id: @payout.id,
#                 approver_code: approver_code,
#                 level: level
#             )
#           end
#
#           #notify
#           Payout.notify_approvers(@payout.id, @payout.approver_cat_id)
#         else
#           PayoutApproval.create(
#               payout_id: @payout.id,
#               approver_code: '',
#               level: ''
#           )
#         end
#
#
#         format.html {redirect_to payouts_path, notice: 'Payout was successfully created.'}
#         format.json {render :show, status: :created, location: @payout}
#       else
#         if current_user.ultra? || current_user.s_user?
#           @approver_categories = ApproversCategory.all
#           @recipient_group = RecipientGroup.all
#         elsif current_user.is_client
#           @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
#           @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
#         else
#           @approver_categories = []
#           @recipient_group = []
#         end
#
#
#         format.html {render :new}
#         format.json {render json: @payout.errors, status: :unprocessable_entity}
#       end
#     end
#   elsif current_user.is_client && !@user_app.needs_approval
#     respond_to do |format|
#       format.html {redirect_to :controller => 'transactions', :action => 'index'}
#       format.json {render json: {status: true}}
#     end
#   else
#     respond_to do |format|
#       if @payout.save
#
#         #create approvals
#         #"approval"=>{"APPR3"=>"1"}
#         if params[:approval].present?
#           params[:approval].each do |approver_code, level|
#             PayoutApproval.create(
#                 payout_id: @payout.id,
#                 approver_code: approver_code,
#                 level: level
#             )
#           end
#
#           #notify
#           Payout.notify_approvers(@payout.id, @payout.approver_cat_id)
#         else
#           PayoutApproval.create(
#               payout_id: @payout.id,
#               approver_code: '',
#               level: ''
#           )
#         end
#
#
#         format.html {redirect_to payouts_path, notice: 'Payout was successfully created.'}
#         format.json {render :show, status: :created, location: @payout}
#       else
#         if current_user.ultra? || current_user.s_user?
#           @approver_categories = ApproversCategory.all
#           @recipient_group = RecipientGroup.all
#         elsif current_user.is_client
#           @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
#           @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
#         else
#           @approver_categories = []
#           @recipient_group = []
#         end
#
#
#         format.html {render :new}
#         format.json {render json: @payout.errors, status: :unprocessable_entity}
#       end
#     end
#   end
# end
#
# # PATCH/PUT /payouts/1
# # PATCH/PUT /payouts/1.json
# def update
#   if current_user.is_client
#     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#   else
#     @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#   end
#
#   if current_user.is_client && @user_app.needs_approval
#     respond_to do |format|
#       if @payout.update(payout_params)
#         format.html {redirect_to payouts_path, notice: 'Payout was successfully updated.'}
#         format.json {render :show, status: :ok, location: @payout}
#       else
#         if current_user.ultra? || current_user.s_user?
#           @approver_categories = ApproversCategory.all
#           @recipient_group = RecipientGroup.all
#         elsif current_user.is_client
#           @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
#           @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
#         else
#           @approver_categories = []
#           @recipient_group = []
#         end
#
#         format.html {render :edit}
#         format.json {render json: @payout.errors, status: :unprocessable_entity}
#       end
#     end
#   elsif current_user.is_client && !@user_app.needs_approval
#     respond_to do |format|
#       format.html {redirect_to :controller => 'transactions', :action => 'index'}
#       format.json {render json: {status: true}}
#     end
#   else
#     respond_to do |format|
#       if @payout.update(payout_params)
#         format.html {redirect_to payouts_path, notice: 'Payout was successfully updated.'}
#         format.json {render :show, status: :ok, location: @payout}
#       else
#         if current_user.ultra? || current_user.s_user?
#           @approver_categories = ApproversCategory.all
#           @recipient_group = RecipientGroup.all
#         elsif current_user.is_client
#           @approver_categories = ApproversCategory.where(client_code: current_user.client_code)
#           @recipient_group = RecipientGroup.where(client_code: current_user.client_code)
#         else
#           @approver_categories = []
#           @recipient_group = []
#         end
#
#         format.html {render :edit}
#         format.json {render json: @payout.errors, status: :unprocessable_entity}
#       end
#     end
#   end
#
#
#   # respond_to do |format|
#   #   if @user_app.needs_approval
#   #
#   #   elsif !@user_app.needs_approval
#   #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
#   #     format.json {render json: {status: true}}
#   #   end
#   # end
# end
#
# # DELETE /payouts/1
# # DELETE /payouts/1.json
# def destroy
#   @payout.destroy
#   respond_to do |format|
#     format.html {redirect_to payouts_url, notice: 'Payout was successfully destroyed.'}
#     format.json {head :no_content}
#   end
# end
#
# private
#
# # Use callbacks to share common setup or constraints between actions.
# def set_payout
#   @payout = Payout.find(params[:id])
# end
#
# # Never trust parameters from the scary internet, only allow the white list through.
# def payout_params
#   params.require(:payout).permit(:disapproval_reason, :user_id, :needs_approval, :group_id, :title, :approval_status, :approver_cat_id, :comment, :processed)
# end
#
# end
