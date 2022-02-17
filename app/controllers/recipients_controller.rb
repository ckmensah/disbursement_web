class RecipientsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_recipient, only: [:show, :edit, :update, :destroy]
  protect_from_forgery with: :null_session
  # GET /recipients
  # GET /recipients.json
  def index
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @recipients = Recipient.active.where(status: true, changed_status: false, user_id: current_user.id).order('created_at desc')
    @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
    @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
  end

  # GET /recipients/1
  # GET /recipients/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  def sample_csv
    send_file("#{Rails.root}/public/sample.csv", filename: "sample.csv", type: "application/csv")
  end

  def bank_sample_csv
    send_file("#{Rails.root}/public/sample_bank_code.csv", filename: "sample_bank_code.csv", type: "application/csv")
  end

  # GET /recipients/new
  def new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    logger.info " @@@@@@@@@@@@@@  #{@user_app.inspect} @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

   @group_id = params[:group_id]


    @recipient = Recipient.new

    logger.info "#{params.inspect}"
    logger.info "#{@recipient.inspect}"

    @recipients = Recipient.active.where(group_id: @group_id)
    @failed_recipients = Recipient.failed.where(group_id: @group_id)
    session[:back_to] = request.referer
  end

  # GET /recipients/1/edit
  def edit
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @group_id = params[:group_id]

    @recipients = Recipient.active.where(group_id: @group_id).order('recipients.created_at desc')
    @failed_recipients = Recipient.failed.where(group_id: @group_id).order('recipients.created_at desc')
    session[:back_to] = request.referer
  end

  def failed
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @group_id = params[:group_id]
    @failed_recipients = Recipient.where(group_id: @group_id).failed.order('recipients.created_at desc')

    logger.info "FAILED RECIPIENTS: #{@failed_recipients.inspect}"

    session[:back_to] = request.referer
  end


  ####################################################################################
  def recipients_import

    # @recipients_master = RecipientsMaster.new(recipients_master_params)
    #
    # @groups = RecipientGroup.where(entity_id: current_user.entity_id)
    #


    bulk = params[:recipient]

    group_id = session.delete(:group_id)

    user_id = current_user.id
    client = current_user.client_code

    status = 1

    # entity_id = current_user.entity_id
    @error_code = 0
    respond_to do |format|
      if params[:file].nil?

        @error_code = 2

        format.html {redirect_to request.referer, :locals => {error_code: @error_code}}
      else
        the_feed_back = Recipient.import_contacts(params[:file], group_id, client, user_id)
        if the_feed_back.to_i == 0
          format.html {redirect_to request.referer, notice: 'Recipients were successfully Imported.'}
        elsif the_feed_back.to_i == 2
          format.html {redirect_to request.referer, alert: 'Wrong file headers. Please download the sample csv file for the right headers'}
        elsif the_feed_back.to_i == 1
          format.html {redirect_to request.referer, notice: 'Recipients were successfully imported with some issues.'}
        elsif the_feed_back.to_i == 3
          format.html {redirect_to request.referer, alert: 'Bank code or alert number cannot be blank for bank recipient.'}
        elsif the_feed_back.to_i == 4
          format.html {redirect_to request.referer, alert: 'Invalid alert number for bank recipient.'}
        else
        end
      end
    end
  end

  ####################################################################################

  # POST /recipients
  # POST /recipients.json
  def create
    @recipient = Recipient.new(recipient_params)
    @recip = Recipient.new
    #@recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
    #@recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    #@recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
    #@recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)

    respond_to do |format|
      if @recipient.valid?

        @recip.mobile_number = Transaction.phone_formatter(recipient_params[:mobile_number])
        @recip.network = recipient_params[:network]
        @recip.recipient_name = recipient_params[:recipient_name]
        @recip.amount = recipient_params[:amount]
        @recip.group_id = recipient_params[:group_id]
        @recip.client_code = recipient_params[:client_code]
        @recip.user_id = current_user.id
        @recip.status = true
        @recip.changed_status = false
        @recip.save

        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)

        format.html {redirect_to request.referer, notice: 'Recipient was successfully created.'}
        format.json {render :show, status: :created, location: @recipient}
      else

        @group_id = session.delete(:group_id)
        logger.info "GROUP ID IN CREATE... #{@group_id}"
        @recipient = Recipient.new

        @recipients = Recipient.active.where(group_id: @group_id).order('recipients.created_at desc')
        @failed_recipients = Recipient.failed.where(group_id: @group_id).order('recipients.created_at desc')
        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)

        format.html {render :new}
        format.json {render json: @recipient.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /recipients/1
  # PATCH/PUT /recipients/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    @transaction = Transaction.new
    @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id)
    #@recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
    # @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
    if current_user.is_client && @user_app.needs_approval
      #render 'recipient_groups/index'

      if @recipient.update(recipient_params)
        respond_to do |format|
          @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
          @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
          format.html {redirect_to new_recipient_path(group_id: @recipient.group_id), notice: 'Recipient was successfully updated.'}
          format.json {render :show, status: :ok, location: @recipient}
        end
      else

        # @group_id = params[:group_id]
        # logger.info "GROUP ID IN CREATE... #{@group_id}"
        # @recipient = Recipient.new
        #
        # @recipients = Recipient.active.where(group_id: @group_id)
        # @failed_recipients = Recipient.failed.where(group_id: @group_id)
        respond_to do |format|
          @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
          @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
          format.html {render :edit}
          format.json {render json: @recipient.errors, status: :unprocessable_entity}
        end
      end

    elsif current_user.is_client && !@user_app.needs_approval
      # render 'transactions/index'
      if @recipient.update(recipient_params)
        respond_to do |format|
          @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
          @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
          flash.now[:notice] = "Recipient was successfully updated."
          format.js {render 'transactions/new', notice: 'Recipient was successfully updated.'}
          format.json {render :new, status: :ok, location: @recipient}
        end
      else
        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
        # @group_id = params[:group_id]
        # logger.info "GROUP ID IN CREATE... #{@group_id}"
        # @recipient = Recipient.new
        #
        # @recipients = Recipient.active.where(group_id: @group_id)
        # @failed_recipients = Recipient.failed.where(group_id: @group_id)
        respond_to do |format|
          @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
          @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
          format.js {render :edit}
          format.json {render json: @recipient.errors, status: :unprocessable_entity}
        end
      end

    else
      if @recipient.update(recipient_params)
        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
        respond_to do |format|
          format.html {redirect_to new_recipient_path(group_id: @recipient.group_id), notice: 'Recipient was successfully updated.'}
          format.json {render :show, status: :ok, location: @recipient}
        end
      else
        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)

        # @group_id = params[:group_id]
        # logger.info "GROUP ID IN CREATE... #{@group_id}"
        # @recipient = Recipient.new
        #
        # @recipients = Recipient.active.where(group_id: @group_id)
        # @failed_recipients = Recipient.failed.where(group_id: @group_id)
        respond_to do |format|
          format.html {render :edit}
          format.json {render json: @recipient.errors, status: :unprocessable_entity}
        end
      end
    end

    # respond_to do |format|
    #
    #   if @user_app.needs_approval
    #     # format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
    #     # format.json {head :no_content}
    #
    #     if @recipient.update(recipient_params)
    #       format.html {redirect_to new_recipient_path(group_id: @recipient.group_id), notice: 'Recipient was successfully updated.'}
    #       format.json {render :show, status: :ok, location: @recipient}
    #     else
    #
    #       # @group_id = params[:group_id]
    #       # logger.info "GROUP ID IN CREATE... #{@group_id}"
    #       # @recipient = Recipient.new
    #       #
    #       # @recipients = Recipient.active.where(group_id: @group_id)
    #       # @failed_recipients = Recipient.failed.where(group_id: @group_id)
    #
    #       format.html {render :edit}
    #       format.json {render json: @recipient.errors, status: :unprocessable_entity}
    #     end
    #
    #   elsif !@user_app.needs_approval
    #     # flash.now[:notice] = "Recipient was successfully deleted.."
    #     # format.js {render :layout => false, notice: 'Recipient was successfully deleted.'}
    #     # format.json {head :no_content}
    #
    #     if @recipient.update(recipient_params)
    #       flash.now[:notice] = "Recipient was successfully updated."
    #       format.js {render 'transactions/new', notice: 'Recipient was successfully updated.'}
    #       format.json {render :new, status: :ok, location: @recipient}
    #     else
    #
    #       # @group_id = params[:group_id]
    #       # logger.info "GROUP ID IN CREATE... #{@group_id}"
    #       # @recipient = Recipient.new
    #       #
    #       # @recipients = Recipient.active.where(group_id: @group_id)
    #       # @failed_recipients = Recipient.failed.where(group_id: @group_id)
    #
    #       format.js {render :edit}
    #       format.json {render json: @recipient.errors, status: :unprocessable_entity}
    #     end
    #
    #
    #   end
    #
    # end
  end

  # DELETE /recipients/1
  # DELETE /recipients/1.json
  def selected_delete

    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    #@recipient.destroy

    logger.info "ThIS IS THE ID FOR USER:::::#{@recipient.inspect}"
    logger.info "ThIS IS THE ID FOR USER:::::#{params.inspect}"
    logger.info "ThIS IS THE ID FOR USER:::::#{params[:recipien]}"

    selected_items_arr = params[:recipien]

    selected_items_arr.each do |item|
      logger.info "################### #{item}"
    end

    if selected_items_arr.any?

      selected_items_arr.each do |item|
        @deleted_rep = Recipient.where(id: item).update_all(changed_status: true, status: false)
      end
      logger.info "**********************************************************"
      logger.info "**********************************************************"
      logger.info "**********************************************************"
      logger.info "Deleted Record:::::#{@deleted_rep.inspect}"
      logger.info "**********************************************************"
      logger.info "**********************************************************"
      logger.info "**********************************************************"

      @transaction = Transaction.new
      @recipient = Recipient.new
      @recipients = Recipient.active.where(status: true, changed_status: false, user_id: current_user.id).order('created_at desc')
      @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
      @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)

      if current_user.is_client && @user_app.needs_approval
        #render 'recipient_groups/index'
        respond_to do |format|
          format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
          format.json {head :no_content}
        end
      elsif current_user.is_client && !@user_app.needs_approval
        # render 'transactions/index'
        respond_to do |format|
          flash.now[:notice] = "Recipient was successfully deleted.."
          format.js {render :layout => false, notice: 'Recipient was successfully deleted.'}
          format.json {head :no_content}
        end
      else
        respond_to do |format|
          format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
          format.json {head :no_content}
        end
      end
    else
      respond_to do |format|

        format.js {render :layout => false}
        format.json {head :no_content}
      end
    end
  end

  # def delete_all
  #
  #   if current_user.is_client
  #     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
  #   else
  #     @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
  #   end
  #   #@recipient.destroy
  #
  #   logger.info "ThIS IS THE ID FOR USER:::::#{@recipient.inspect}"
  #   logger.info "ThIS IS THE ID FOR USER:::::#{params.inspect}"
  #   logger.info "ThIS IS THE ID FOR USER:::::#{params[:recipien]}"
  #
  #   #if selected_items_arr.any?
  #   @rec = Recipient.where(status: true, changed_status: false, client_code: current_user.client_code, user_id: current_user.id)
  #   logger.info "**********************************************************"
  #   logger.info "**********************************************************"
  #   logger.info "**********************************************************"
  #   logger.info "Recipients Record:::::#{@rec.inspect}"
  #   @rec.each do |recipients|
  #     @deleted_rep = Recipient.where(id: recipients.id).update_all(changed_status: true, status: false)
  #   end
  #   logger.info "**********************************************************"
  #   logger.info "**********************************************************"
  #   logger.info "**********************************************************"
  #   logger.info "Deleted Record:::::#{@deleted_rep.inspect}"
  #   logger.info "**********************************************************"
  #   logger.info "**********************************************************"
  #   logger.info "**********************************************************"
  #
  #   @transaction = Transaction.new
  #   @recipient = Recipient.new
  #   @recipients = Recipient.active.where(status: true, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).order('created_at desc')
  #   @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
  #   @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
  #
  #   if current_user.is_client && @user_app.needs_approval
  #     #render 'recipient_groups/index'
  #     respond_to do |format|
  #       format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
  #       format.json {head :no_content}
  #       #     format.js {render :layout => false}
  #       #     format.json {head :no_content}
  #     end
  #   elsif current_user.is_client && !@user_app.needs_approval
  #     # render 'transactions/index'
  #     respond_to do |format|
  #       flash.now[:notice] = "Recipient was successfully deleted.."
  #       format.js {render :layout => false, notice: 'Recipient was successfully deleted.'}
  #       format.json {head :no_content}
  #     end
  #   else
  #     respond_to do |format|
  #       # format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
  #       # format.json {head :no_content}
  #       format.js {render :layout => false}
  #       format.json {head :no_content}
  #     end
  #   end
  #   # else
  #   #   respond_to do |format|
  #   #
  #   #     format.js {render :layout => false}
  #   #     format.json {head :no_content}
  #   #   end
  #   # end
  # end

  def delete_all

    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    #@recipient.destroy

    @upload_id = CsvUpload.where(user_id: current_user.id, client_code: current_user.client_code).order('created_at desc')[0]
    @uploaded = @upload_id.id

    logger.info "ThIS IS THE ID FOR USER:::::#{@recipient.inspect}"
    logger.info "ThIS IS THE ID FOR USER:::::#{params.inspect}"
    logger.info "ThIS IS THE ID FOR USER:::::#{params[:recipien]}"

    #if selected_items_arr.any?
    @rec = Recipient.where(status: true, csv_uploads_id: @uploaded, changed_status: false, client_code: current_user.client_code, user_id: current_user.id)
    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "Recipients Record:::::#{@rec.inspect}"
    @rec.each do |recipients|
      @deleted_rep = Recipient.where(id: recipients.id, csv_uploads_id: @uploaded).update_all(changed_status: true, status: false)
    end
    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "Deleted Record:::::#{@deleted_rep.inspect}"
    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "**********************************************************"

    @transaction = Transaction.new
    @recipient = Recipient.new
    @recipients = Recipient.active.where(status: true, csv_uploads_id: @uploaded, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).order('created_at desc')
    @recipients_count = Recipient.where(status: true, csv_uploads_id: @uploaded, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
    @recipients_total_amount = Recipient.where(status: true, csv_uploads_id: @uploaded, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)

    if current_user.is_client && @user_app.needs_approval
      #render 'recipient_groups/index'
      respond_to do |format|
        flash.now[:notice] = "Recipients was successfully deleted."
        format.html {redirect_to request.referer, notice: 'Recipients was successfully deleted.'}
        format.json {head :no_content}
        format.js {render :layout => false, notice: 'Recipients was successfully deleted.'}
        # format.json {head :no_content}
      end
    elsif current_user.is_client && !@user_app.needs_approval
      # render 'transactions/index'
      respond_to do |format|
        flash.now[:notice] = "Recipients was successfully deleted."
        format.html {redirect_to request.referer, notice: 'Recipients was successfully deleted.'}
        format.js {render :layout => false, notice: 'Recipients was successfully deleted.'}
        format.json {head :no_content}
      end
    else
      respond_to do |format|
        # format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
        # format.json {head :no_content}
        format.js {render :layout => false}
        format.json {head :no_content}
      end
    end
  end

  def destroy
    # @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
    # @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    #@recipient.destroy

    logger.info "ThIS IS THE ID FOR USER:::::#{params[:id]}"

    @deleted_rep = Recipient.where(id: params[:id]).update_all(changed_status: true)

    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "Deleted Record:::::#{@deleted_rep.inspect}"
    logger.info "**********************************************************"
    logger.info "**********************************************************"
    logger.info "**********************************************************"

    @transaction = Transaction.new
    @recipient = Recipient.new
    @recipients = Recipient.active.where(status: true, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).order('created_at desc')
    @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
    @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)

    if current_user.is_client && @user_app.needs_approval
      #render 'recipient_groups/index'
      respond_to do |format|
        format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
        format.json {head :no_content}
      end
    elsif current_user.is_client && !@user_app.needs_approval
      # render 'transactions/index'
      respond_to do |format|
        flash.now[:notice] = "Recipient was successfully deleted.."
        format.js {render :layout => false, notice: 'Recipient was successfully deleted.'}
        format.json {head :no_content}
      end
    else
      respond_to do |format|
        format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
        format.json {head :no_content}
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_recipient
    @recipient = Recipient.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def recipient_params
    params.require(:recipient).permit(:disburse_status, :transaction_id, :mobile_number, :network, :amount, :csv_uploads_id, :group_id, :status, :changed_status, :client_code, :user_id, :swift_code,:sort_code, :bank_code, :recipient_name, :phone_number)
  end
end





# class RecipientsController < ApplicationController
#   skip_before_action :verify_authenticity_token
#   before_action :set_recipient, only: [:show, :edit, :update, :destroy]
#   protect_from_forgery with: :null_session
#   # GET /recipients
#   # GET /recipients.json
#   def index
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @recipients = Recipient.active.where(status: true, changed_status: false, user_id: current_user.id).order('created_at desc')
#     @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#     @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#   end
#
#   # GET /recipients/1
#   # GET /recipients/1.json
#   def show
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#   end
#
#   def sample_csv
#     send_file("#{Rails.root}/public/sample.csv", filename: "sample.csv", type: "application/csv")
#   end
#
#   # GET /recipients/new
#   def new
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @group_id = params[:group_id]
#
#
#     @recipient = Recipient.new
#
#     logger.info "#{params.inspect}"
#     logger.info "#{@recipient.inspect}"
#
#     @recipients = Recipient.active.where(group_id: @group_id)
#     @failed_recipients = Recipient.failed.where(group_id: @group_id)
#     session[:back_to] = request.referer
#   end
#
#   # GET /recipients/1/edit
#   def edit
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @group_id = params[:group_id]
#
#     @recipients = Recipient.active.where(group_id: @group_id).order('recipients.created_at desc')
#     @failed_recipients = Recipient.failed.where(group_id: @group_id).order('recipients.created_at desc')
#     session[:back_to] = request.referer
#   end
#
#   def failed
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @group_id = params[:group_id]
#     @failed_recipients = Recipient.where(group_id: @group_id).failed.order('recipients.created_at desc')
#
#     logger.info "FAILED RECIPIENTS: #{@failed_recipients.inspect}"
#
#     session[:back_to] = request.referer
#   end
#
#
#   ####################################################################################
#   def recipients_import
#
#     # @recipients_master = RecipientsMaster.new(recipients_master_params)
#     #
#     # @groups = RecipientGroup.where(entity_id: current_user.entity_id)
#     #
#
#
#     bulk = params[:recipient]
#
#     group_id = session.delete(:group_id)
#
#     status = 1
#
#     # entity_id = current_user.entity_id
#     @error_code = 0
#     respond_to do |format|
#       if params[:file].nil?
#
#         @error_code = 2
#
#         format.html {redirect_to request.referer, :locals => {error_code: @error_code}}
#       else
#         the_feed_back = Recipient.import_contacts(params[:file], group_id)
#         if the_feed_back.to_i == 0
#           format.html {redirect_to request.referer, notice: 'Recipients were successfully Imported.'}
#         elsif the_feed_back.to_i == 2
#           format.html {redirect_to request.referer, alert: 'Wrong file headers. Please download the sample csv file for the right headers'}
#         elsif the_feed_back.to_i == 1
#
#           format.html {redirect_to request.referer, notice: 'Recipients were successfully imported with some issues.'}
#
#         end
#       end
#     end
#   end
#
#   ####################################################################################
#
#   # POST /recipients
#   # POST /recipients.json
#   def create
#     @recipient = Recipient.new(recipient_params)
#     @recip = Recipient.new
#     #@recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
#     #@recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     #@recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
#     #@recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
#
#     respond_to do |format|
#       if @recipient.valid?
#
#         @recip.mobile_number = Transaction.phone_formatter(recipient_params[:mobile_number])
#         @recip.network = recipient_params[:network]
#         @recip.recipient_name = recipient_params[:recipient_name]
#         @recip.amount = recipient_params[:amount]
#         @recip.group_id = recipient_params[:group_id]
#         @recip.client_code = recipient_params[:client_code]
#         @recip.user_id = current_user.id
#         @recip.status = true
#         @recip.changed_status = false
#         @recip.save
#
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#
#         format.html {redirect_to request.referer, notice: 'Recipient was successfully created.'}
#         format.json {render :show, status: :created, location: @recipient}
#       else
#
#         @group_id = session.delete(:group_id)
#         logger.info "GROUP ID IN CREATE... #{@group_id}"
#         @recipient = Recipient.new
#
#         @recipients = Recipient.active.where(group_id: @group_id).order('recipients.created_at desc')
#         @failed_recipients = Recipient.failed.where(group_id: @group_id).order('recipients.created_at desc')
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#
#         format.html {render :new}
#         format.json {render json: @recipient.errors, status: :unprocessable_entity}
#       end
#     end
#   end
#
#   # PATCH/PUT /recipients/1
#   # PATCH/PUT /recipients/1.json
#   def update
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     @transaction = Transaction.new
#     @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id)
#     #@recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
#     # @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
#     if current_user.is_client && @user_app.needs_approval
#       #render 'recipient_groups/index'
#
#       if @recipient.update(recipient_params)
#         respond_to do |format|
#           @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#           @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#           format.html {redirect_to new_recipient_path(group_id: @recipient.group_id), notice: 'Recipient was successfully updated.'}
#           format.json {render :show, status: :ok, location: @recipient}
#         end
#       else
#
#         # @group_id = params[:group_id]
#         # logger.info "GROUP ID IN CREATE... #{@group_id}"
#         # @recipient = Recipient.new
#         #
#         # @recipients = Recipient.active.where(group_id: @group_id)
#         # @failed_recipients = Recipient.failed.where(group_id: @group_id)
#         respond_to do |format|
#           @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#           @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#           format.html {render :edit}
#           format.json {render json: @recipient.errors, status: :unprocessable_entity}
#         end
#       end
#
#     elsif current_user.is_client && !@user_app.needs_approval
#       # render 'transactions/index'
#       if @recipient.update(recipient_params)
#         respond_to do |format|
#           @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#           @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#           flash.now[:notice] = "Recipient was successfully updated."
#           format.js {render 'transactions/new', notice: 'Recipient was successfully updated.'}
#           format.json {render :new, status: :ok, location: @recipient}
#         end
#       else
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#         # @group_id = params[:group_id]
#         # logger.info "GROUP ID IN CREATE... #{@group_id}"
#         # @recipient = Recipient.new
#         #
#         # @recipients = Recipient.active.where(group_id: @group_id)
#         # @failed_recipients = Recipient.failed.where(group_id: @group_id)
#         respond_to do |format|
#           @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#           @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#           format.js {render :edit}
#           format.json {render json: @recipient.errors, status: :unprocessable_entity}
#         end
#       end
#
#     else
#       if @recipient.update(recipient_params)
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#         respond_to do |format|
#           format.html {redirect_to new_recipient_path(group_id: @recipient.group_id), notice: 'Recipient was successfully updated.'}
#           format.json {render :show, status: :ok, location: @recipient}
#         end
#       else
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#
#         # @group_id = params[:group_id]
#         # logger.info "GROUP ID IN CREATE... #{@group_id}"
#         # @recipient = Recipient.new
#         #
#         # @recipients = Recipient.active.where(group_id: @group_id)
#         # @failed_recipients = Recipient.failed.where(group_id: @group_id)
#         respond_to do |format|
#           format.html {render :edit}
#           format.json {render json: @recipient.errors, status: :unprocessable_entity}
#         end
#       end
#     end
#
#     # respond_to do |format|
#     #
#     #   if @user_app.needs_approval
#     #     # format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
#     #     # format.json {head :no_content}
#     #
#     #     if @recipient.update(recipient_params)
#     #       format.html {redirect_to new_recipient_path(group_id: @recipient.group_id), notice: 'Recipient was successfully updated.'}
#     #       format.json {render :show, status: :ok, location: @recipient}
#     #     else
#     #
#     #       # @group_id = params[:group_id]
#     #       # logger.info "GROUP ID IN CREATE... #{@group_id}"
#     #       # @recipient = Recipient.new
#     #       #
#     #       # @recipients = Recipient.active.where(group_id: @group_id)
#     #       # @failed_recipients = Recipient.failed.where(group_id: @group_id)
#     #
#     #       format.html {render :edit}
#     #       format.json {render json: @recipient.errors, status: :unprocessable_entity}
#     #     end
#     #
#     #   elsif !@user_app.needs_approval
#     #     # flash.now[:notice] = "Recipient was successfully deleted.."
#     #     # format.js {render :layout => false, notice: 'Recipient was successfully deleted.'}
#     #     # format.json {head :no_content}
#     #
#     #     if @recipient.update(recipient_params)
#     #       flash.now[:notice] = "Recipient was successfully updated."
#     #       format.js {render 'transactions/new', notice: 'Recipient was successfully updated.'}
#     #       format.json {render :new, status: :ok, location: @recipient}
#     #     else
#     #
#     #       # @group_id = params[:group_id]
#     #       # logger.info "GROUP ID IN CREATE... #{@group_id}"
#     #       # @recipient = Recipient.new
#     #       #
#     #       # @recipients = Recipient.active.where(group_id: @group_id)
#     #       # @failed_recipients = Recipient.failed.where(group_id: @group_id)
#     #
#     #       format.js {render :edit}
#     #       format.json {render json: @recipient.errors, status: :unprocessable_entity}
#     #     end
#     #
#     #
#     #   end
#     #
#     # end
#   end
#
#   # DELETE /recipients/1
#   # DELETE /recipients/1.json
#   def selected_delete
#
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     #@recipient.destroy
#
#
#     # @upload_id = CsvUpload.where(user_id: current_user.id, client_code: current_user.client_code).order('created_at desc')[0]
#     # @uploaded = @upload_id.id
#
#     logger.info "ThIS IS THE ID FOR USER:::::#{@recipient.inspect}"
#     logger.info "ThIS IS THE ID FOR USER:::::#{params.inspect}"
#     logger.info "ThIS IS THE ID FOR USER:::::#{params[:recipien]}"
#
#     selected_items_arr = params[:recipien]
#
#     selected_items_arr.each do |item|
#       logger.info "################### #{item}"
#     end
#
#     if selected_items_arr.any?
#
#       selected_items_arr.each do |item|
#         @deleted_rep = Recipient.where(id: item).update_all(changed_status: true, status: false)
#       end
#       logger.info "**********************************************************"
#       logger.info "**********************************************************"
#       logger.info "**********************************************************"
#       logger.info "Deleted Record:::::#{@deleted_rep.inspect}"
#       logger.info "**********************************************************"
#       logger.info "**********************************************************"
#       logger.info "**********************************************************"
#
#       @transaction = Transaction.new
#       @recipient = Recipient.new
#       @recipients = Recipient.active.where(status: true, changed_status: false, user_id: current_user.id).order('created_at desc')
#       @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#       @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#
#       if current_user.is_client && @user_app.needs_approval
#         #render 'recipient_groups/index'
#         respond_to do |format|
#           format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
#           format.json {head :no_content}
#         end
#       elsif current_user.is_client && !@user_app.needs_approval
#         # render 'transactions/index'
#         respond_to do |format|
#           flash.now[:notice] = "Recipient was successfully deleted.."
#           format.js {render :layout => false, notice: 'Recipient was successfully deleted.'}
#           format.json {head :no_content}
#         end
#       else
#         respond_to do |format|
#           format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
#           format.json {head :no_content}
#         end
#       end
#     else
#       respond_to do |format|
#
#         format.js {render :layout => false}
#         format.json {head :no_content}
#       end
#     end
#   end
#
#   def delete_all
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     #@recipient.destroy
#
#     @upload_id = CsvUpload.where(user_id: current_user.id, client_code: current_user.client_code).order('created_at desc')[0]
#     @uploaded = @upload_id.id
#
#     logger.info "ThIS IS THE ID FOR USER:::::#{@recipient.inspect}"
#     logger.info "ThIS IS THE ID FOR USER:::::#{params.inspect}"
#     logger.info "ThIS IS THE ID FOR USER:::::#{params[:recipien]}"
#
#     #if selected_items_arr.any?
#     @rec = Recipient.where(status: true, csv_uploads_id: @uploaded, changed_status: false, client_code: current_user.client_code, user_id: current_user.id)
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "Recipients Record:::::#{@rec.inspect}"
#     @rec.each do |recipients|
#       @deleted_rep = Recipient.where(id: recipients.id, csv_uploads_id: @uploaded).update_all(changed_status: true, status: false)
#     end
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "Deleted Record:::::#{@deleted_rep.inspect}"
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#
#     @transaction = Transaction.new
#     @recipient = Recipient.new
#     @recipients = Recipient.active.where(status: true, csv_uploads_id: @uploaded, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).order('created_at desc')
#     @recipients_count = Recipient.where(status: true, csv_uploads_id: @uploaded, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#     @recipients_total_amount = Recipient.where(status: true, csv_uploads_id: @uploaded, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#
#     if current_user.is_client && @user_app.needs_approval
#       #render 'recipient_groups/index'
#       respond_to do |format|
#         flash.now[:notice] = "Recipients was successfully deleted."
#         format.html {redirect_to request.referer, notice: 'Recipients was successfully deleted.'}
#         format.json {head :no_content}
#         format.js {render :layout => false, notice: 'Recipients was successfully deleted.'}
#         # format.json {head :no_content}
#       end
#     elsif current_user.is_client && !@user_app.needs_approval
#       # render 'transactions/index'
#       respond_to do |format|
#         flash.now[:notice] = "Recipients was successfully deleted."
#         format.html {redirect_to request.referer, notice: 'Recipients was successfully deleted.'}
#         format.js {render :layout => false, notice: 'Recipients was successfully deleted.'}
#         format.json {head :no_content}
#       end
#     else
#       respond_to do |format|
#         # format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
#         # format.json {head :no_content}
#         format.js {render :layout => false}
#         format.json {head :no_content}
#       end
#     end
#   end
#
#   def destroy
#     # @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
#     # @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     #@recipient.destroy
#
#     logger.info "ThIS IS THE ID FOR USER:::::#{params[:id]}"
#
#     @deleted_rep = Recipient.where(id: params[:id]).update_all(changed_status: true)
#
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "Deleted Record:::::#{@deleted_rep.inspect}"
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#     logger.info "**********************************************************"
#
#     @transaction = Transaction.new
#     @recipient = Recipient.new
#     @recipients = Recipient.active.where(status: true, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).order('created_at desc')
#     @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).count
#     @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id).sum(:amount)
#
#     if current_user.is_client && @user_app.needs_approval
#       #render 'recipient_groups/index'
#       respond_to do |format|
#         format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
#         format.json {head :no_content}
#       end
#     elsif current_user.is_client && !@user_app.needs_approval
#       # render 'transactions/index'
#       respond_to do |format|
#         flash.now[:notice] = "Recipient was successfully deleted.."
#         format.js {render :layout => false, notice: 'Recipient was successfully deleted.'}
#         format.json {head :no_content}
#       end
#     else
#       respond_to do |format|
#         format.html {redirect_to request.referer, notice: 'Recipient was successfully deleted.'}
#         format.json {head :no_content}
#       end
#     end
#   end
#
#   private
#
#   # Use callbacks to share common setup or constraints between actions.
#   def set_recipient
#     @recipient = Recipient.find(params[:id])
#   end
#
#   # Never trust parameters from the scary internet, only allow the white list through.
#   def recipient_params
#     params.require(:recipient).permit(:disburse_status, :transaction_id, :mobile_number, :network, :amount, :csv_uploads_id, :group_id, :status, :changed_status, :client_code, :user_id, :recipient_name)
#   end
# end
