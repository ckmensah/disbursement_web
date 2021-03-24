class NumberValidationsController < ApplicationController
  before_action :set_number_validation, only: [:show, :edit, :update, :destroy]

  # GET /number_validations
  # GET /number_validations.json
  # def index
  #   @number_validations = NumberValidation.all
  # end

  # GET /number_validations/1
  # GET /number_validations/1.json
  def show
  end

  # GET /number_validations/new
  def new
    # @number_validation = NumberValidation.new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @number_validation = NumberValidation.new
    # @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code, user_id: current_user.id)
    # @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
  end

  # GET /number_validations/1/edit
  # def edit
  # end


  # def validate_index_one
  #   if current_user.is_client
  #     @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
  #   else
  #     @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
  #   end
  #   @number_validation = NumberValidation.new(number_validation_params)
  #   @recipient = Recipient.new
  #
  #   respond_to do |format|
  #
  #     @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, user_id: current_user.id, client_code: current_user.client_code)
  #     puts "#{@transaction.errors.messages.inspect}"
  #
  #     if @transaction.valid?
  #       @recipient = Recipient.new
  #
  #       @recipient.mobile_number = Transaction.phone_formatter(transaction_params[:mobile_num])
  #       @recipient.network = transaction_params[:netwk]
  #       @recipient.recipient_name = transaction_params[:rec_name]
  #       @recipient.amount = transaction_params[:amt]
  #       @recipient.client_code = transaction_params[:client_code]
  #       @recipient.user_id = current_user.id
  #       @recipient.status = true
  #       @recipient.changed_status = false
  #       @recipient.disburse_status = transaction_params[:disburse_status]
  #       @recipient.save
  #
  #       puts format.inspect
  #       flash.now[:notice] = "Recipient was successfully added."
  #       @transaction = Transaction.new
  #
  #
  #       @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
  #       @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
  #
  #       if @user_app.present? || !@user_app.nil?
  #         if @user_app.client_id.present? || !@user_app.client_id.nil?
  #           @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
  #           puts "Per Page = #{params[:per_page]}"
  #           puts "Current User :::::::::: #{@user_app.inspect}"
  #           puts "UUU User :::::::::: #{@user_app_.inspect}"
  #           puts "#{@get_current_balance.inspect}"
  #           logger.info "#{@get_current_balance.inspect}"
  #         else
  #           @get_current_balance = "GHs0.00"
  #         end
  #       else
  #         @get_current_balance = "GHs0.00"
  #       end
  #       #format.html {redirect_to @transaction, notice: 'Bank transaction was successfully created.'}
  #       format.js {render :new}
  #       format.json {render :show, status: :created, location: @transaction}
  #
  #     else
  #       puts "#{@transaction.errors.messages.inspect}"
  #       @transaction = Transaction.new
  #
  #       @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
  #       @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
  #       #format.html {render :new}
  #       if @user_app.present? || !@user_app.nil?
  #         if @user_app.client_id.present? || !@user_app.client_id.nil?
  #           @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
  #           puts "Per Page = #{params[:per_page]}"
  #           puts "Current User :::::::::: #{@user_app.inspect}"
  #           puts "UUU User :::::::::: #{@user_app_.inspect}"
  #           puts "#{@get_current_balance.inspect}"
  #           logger.info "#{@get_current_balance.inspect}"
  #         else
  #           @get_current_balance = "GHs0.00"
  #         end
  #       else
  #         @get_current_balance = "GHs0.00"
  #       end
  #       format.js {render :new}
  #       format.json {render json: @transaction.errors, status: :unprocessable_entity}
  #     end
  #   end
  #
  # end


  def validate_index
    if params[:per_page].present?
      if params[:per_page] == "All"
        @per_page = 10000000000000000
      else
        @per_page = params[:per_page]
      end
    else
      @per_page = 100
    end


    if params[:page].present?
      @page = params[:page].gsub('?yes','')
    else
      @page = 1
    end


    if current_user.s_user? || current_user.ultra? || current_user.admin?
      @processor = User.where(id: current_user.id).order('created_at DESC')[0]
      logger.info " this is the user rightnow #{@processor.inspect}"
    end
    @number_validation = NumberValidation.new
    # @transactions = Transaction.where(processed: nil, callback_processing_id: nil, user_id: current_user.id)

    @number_validations = NumberValidation.where(status: true, changed_status: false, user_id: @processor).paginate(:page => params[:page], :per_page => @per_page).order('created_at desc')

  end


  def validate_all_numbers
     user_id = current_user.id
      @processor = User.where(id: user_id).order('created_at DESC')[0]

      @number_validation = NumberValidation.new
      @number_validations = NumberValidation.where(status: true, changed_status: false, user_id: @processor).paginate(:page => params[:page], :per_page => @per_page).order('created_at desc')

        resp_code = " "
        resp_desc = " "

        begin
          if @number_validations.present?
            @number_validations.each do |record|
              conn = CoreConnect.new
              res=conn.connection.post do |req|
                req.url '/accountInquiry'
                req.options.timeout = 180 # open/read timeout in seconds
                req.options.open_timeout = 180 # connection open timeout in seconds
                #req.headers['Content-Type'] = 'application/json'
                req.body = JSON.generate(
                    {
                        mobile_number: record.mobile_number,
                        nw_trans_id: record.network,
                        user_id: user_id
                    }
                )
              end

              logger.info "Result from ALert response of the request: #{res.status} #{res.body}"
              logger.info "Result from ALert response of the request (Content of request only):  #{res.body}"

              #my_res=JSON.parse(res.body)
              #logger.info "THIS IS THE RESPONSE CODE:  #{my_res["resp_code"]}"
              my_res = JSON.parse(res.body)
              logger.info "THIS IS THE RESPONSE CODE:  #{my_res["resp_code"]}"

              resp_code = my_res['resp_code']
              resp_desc = my_res['resp_desc']


              # is_json = json_validate(res.body)
              # if is_json
              #   puts res.body
              #   if !res.body.nil?
              #     my_res = JSON.parse(res.body)
              #     resp_code = my_res['resp_code']
              #     resp_desc = my_res['resp_desc']
              #     message = ""
              #   else
              #     puts "RESPONSE FROM API IS VERY EMPTY"
              #   end
              # else
              #   resp_code = 998
              #   message = { "resp_code": resp_code,"resp_desc": "The response is not a json response" }
              #   return message.to_json
              # end

            end

            respond_to do |format|
              if resp_code == '027'
                format.html { redirect_to request.referer, notice: 'All Transaction requests were successfully reprocessed.' }
                format.js { }
              elsif resp_code == '013'
                format.html { redirect_to request.referer, alert: "#{resp_desc}." }
                format.js { }
              elsif resp_code == '067'
                format.html { redirect_to request.referer, alert: "#{resp_desc}." }
                format.js { }
              end
            end
          end

        rescue Faraday::SSLError
          resp_code = "100"
          resp_desc = "There was a problem sending the https request......CONNECTION FAILED."
        rescue Faraday::TimeoutError
          resp_code = "100"
          resp_desc = "Connection timeout error"
        end
        return resp_code,resp_desc

  end


  def sample_csv_validation
    send_file("#{Rails.root}/public/verification_sample.csv", filename: "verification_sample.csv", type: "application/csv")
  end


  def validate_recipient_import
    @error_code = 0
    respond_to do |format|
      if params[:file].nil?
        @error_code = 2
        format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", :locals => {error_code: @error_code}}
      else
        the_feed_back = NumberValidation.validate_import(params[:file], current_user.client_code, current_user.id)
        if the_feed_back.to_i == 0
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", notice: 'Numbers were successfully Imported.'}
        elsif the_feed_back.to_i == 2
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", alert: 'Wrong file headers. Please download the sample csv file for the right headers'}
        elsif the_feed_back.to_i == 1
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", alert: 'Unknown network.'}
        elsif the_feed_back.to_i == 6
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", alert: 'Invalid row, missing parameters.'}
        elsif the_feed_back.to_i == 4
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", alert: 'Wrong mobile number.'}
        elsif the_feed_back.to_i == 5
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", alert: 'Wrong mobile number format.'}
        elsif the_feed_back.to_i == 7
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", alert: 'Invalid file.'}
        elsif the_feed_back.to_i == 9
          format.html {redirect_to "/validate_index?after_upload=#{params[:after_upload]}", alert: 'File already exists. Kindly rename the file and upload.'}
        else

        end
      end
    end
  end


  def delete_all
    if current_user.s_user? || current_user.ultra? || current_user.admin? || current_user.is_client?
      @processor = User.where(id: current_user.id).order('created_at DESC')[0]
      logger.info " this is the user rightnow #{@processor.inspect}"
    end

    @upload_id = CsvUpload.where(user_id: @processor).order('created_at desc')[0]
    @uploaded = @upload_id.id

    #if selected_items_arr.any?
    @number_validations = NumberValidation.where(status: true, csv_upload_id: @uploaded, changed_status: false, user_id: @processor)

    logger.info "*************Transactions Record:::::#{@number_validations.inspect}"
    @number_validations.each do |mob_num|
      @deleted_transactions = NumberValidation.where(id: mob_num.id, csv_upload_id: @uploaded).update_all(changed_status: true, status: false)
    end


    respond_to do |format|
      flash.now[:notice] = "Uploaded Numbers were successfully deleted."
      format.html {redirect_to request.referer, notice: 'Uploaded Numbers were successfully deleted.'}
      format.json {head :no_content}
      format.js {render :layout => false, notice: 'Uploaded Numbers were successfully deleted.'}
      # format.json {head :no_content}
    end
  end

  # POST /number_validations
  # POST /number_validations.json
  # def create
  #   @number_validation = NumberValidation.new(number_validation_params)
  #
  #   respond_to do |format|
  #     if @number_validation.save
  #       format.html { redirect_to @number_validation, notice: 'Number validation was successfully created.' }
  #       format.json { render :show, status: :created, location: @number_validation }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @number_validation.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PATCH/PUT /number_validations/1
  # PATCH/PUT /number_validations/1.json
  # def update
  #   respond_to do |format|
  #     if @number_validation.update(number_validation_params)
  #       format.html { redirect_to @number_validation, notice: 'Number validation was successfully updated.' }
  #       format.json { render :show, status: :ok, location: @number_validation }
  #     else
  #       format.html { render :edit }
  #       format.json { render json: @number_validation.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /number_validations/1
  # DELETE /number_validations/1.json
  def destroy
    @number_validation.destroy
    respond_to do |format|
      format.html { redirect_to number_validations_url, notice: 'Number validation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_number_validation
      @number_validation = NumberValidation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def number_validation_params
      params.require(:number_validation).permit(:mobile_number, :network, :group_id, :status, :changed_status, :user_id, :recipient_name, :client_code, :csv_upload_id)
    end
end
