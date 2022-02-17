class TransactionsController < ApplicationController

  # load_and_authorize_resource
  before_action :set_transaction, only: [:show, :edit, :update, :destroy, :manually_close, :edit_trans_recep]
  protect_from_forgery except: [:trans_recipients_import]

  # GET /transactions
  # GET /transactions.json
  def index

    logger.info "showing Transactions now index"


    # if @user_app.present? || !@user_app.nil?
    #   if @user_app.client_id.present? || !@user_app.client_id.nil?
    #     @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
    #     puts "Per Page = #{params[:per_page]}"
    #     puts "Current User :::::::::: #{@user_app.inspect}"
    #     puts "UUU User :::::::::: #{@user_app_.inspect}"
    #     puts "#{@get_current_balance.inspect}"
    #   else
    #     @get_current_balance = "GHs0.00"
    #   end
    # else
    #   @get_current_balance = "GHs0.00"
    # end

    if params[:per_page].present?
      if params[:per_page] == "All"
        @per_page = 10000000000000000
      else
        @per_page = params[:per_page].to_i
      end
    else
      @per_page = Transaction.per_page
    end

    logger.info "Normal Pages #{@per_page.inspect}"


    if params[:page] && params[:page].size > 0
      #if params[:page].present?
      @page = params[:page].gsub('?yes', '')
    else
      @page = 1
    end

    if params[:filter_main].present?
      filter_params = params[:filter_main]

      @name = filter_params[:name]
      @trans_id = filter_params[:trans_id]
      @phone_number = filter_params[:phone_number]
      @client_code = filter_params[:client_code]
      @trans_type = filter_params[:trans_type]
      @network = filter_params[:network]
      @status = filter_params[:status]
      @start_date = filter_params[:start_date]
      @end_date = filter_params[:end_date]
      # @per_page = filter_params[:perpage]

      # if params[:per_page].present?
      #   if params[:per_page] == "All"
      #     @per_page = 10000000000000000
      #   else
      #     @per_page = params[:per_page].to_i
      #   end
      # else
      #   @per_page = Transaction.per_page
      # end

      list_of_search_str = []
      the_search = ""


      logger.info "Status status ############################# #{@status.inspect}"
      if @name.present?
        logger.info "#############################################NAME #{Transaction.name_search(@name).inspect}"
        list_of_search_str << Transaction.name_search(@name)
        the_search = the_search + "recipients.recipient_name iLIKE '%#{@name}%' and "
      end

      if @trans_id.present?
        logger.info "#############################################trans id #{Transaction.trans_id_search(@trans_id).inspect}"
        list_of_search_str << Transaction.trans_id_search(@trans_id)
        the_search = the_search + "transaction_ref_id = '#{@trans_id}' and "
        # add_reprocess_joiner = true
      end

      if @phone_number.present?
        logger.info "#############################################phone number #{Transaction.phone_search(@phone_number).inspect}"
        list_of_search_str << Transaction.phone_search(@phone_number)
        the_search = the_search + "transactions.mobile_number iLIKE '%#{@phone_number}%' and "
      end

      if @client_code.present?
        logger.info "#############################################client code #{Transaction.client_code_search(@client_code).inspect}"
        list_of_search_str << Transaction.client_code_search(@client_code)
        the_search = the_search + "recipients.client_code = '#{@client_code}' and "
      end

      if @trans_type.present?
        logger.info "#############################################trans type #{Transaction.trans_type_search(@trans_type).inspect}"
        list_of_search_str << Transaction.trans_type_search(@trans_type)
        the_search = the_search + "trans_type = '#{@trans_type}' and "
      end

      if @network.present?
        logger.info "#############################################Network #{Transaction.network_search(@network)}"
        list_of_search_str << Transaction.network_search(@network)
        the_search = the_search + "recipients.network = '#{@network}' and "
      end

      if @status != "nil"
        logger.info "#############################################Status #{Transaction.status_search(@status).inspect}"

        list_of_search_str << Transaction.status_search(@status)

        if @status == "pending"
          the_search = the_search + "transactions.err_code IS NULL and "
          # "transactions.err_code IS NULL"
        elsif @status == "000" || @status == "001"
          the_search = the_search + "transactions.err_code = '#{@status}' and "
          # "transactions.err_code = '#{@status}'"
        else

        end
      end


      if @start_date.present?
        if @end_date.present?
          logger.info "#############################################Date #{Transaction.search_date(@start_date, @end_date).inspect}"
          list_of_search_str << Transaction.search_date(@start_date, @end_date) if Transaction.search_date(@start_date, @end_date).present?

          @start_date = @start_date + " 00:00:00 UTC"
          @end_date = @end_date + " 23:59:59 UTC"
          the_search = the_search + "transactions.created_at between '" + @start_date + "' and '" + @end_date + "' and "

        end
      end
      logger.info "list of search string is #{list_of_search_str.inspect}"
      search_str = list_of_search_str.join(" AND ")

      logger.info "Search String #{search_str}"

      if !the_search.present?
        if current_user.is_client
          @client = PremiumClient.where(client_code: current_user.client_code, changed_status: false, status: true).order(updated_at: :desc).first
          client_acronym = @client ? @client.acronym : ''
          @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{client_acronym}'").paginate(:page => @page, :per_page => @per_page).order("created_at desc")
          @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
          @transaction_rep = Transaction.joiner(current_user.client_code).order("created_at desc")
        else
          @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
          @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last

          # if add_reprocess_joiner
          #   @transactions = Transaction.joiner_not.where(search_str).paginate(:page => page, :per_page => @per_page).order("created_at desc")
          #   @transaction_rep = Transaction.joiner_not.where(search_str).limit(@per_page).order("created_at desc")
          # else
          @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
          @transaction_rep = Transaction.joiner_not.order("created_at desc")

          #end
        end
      else
        the_search = the_search + "transactions.created_at is not null"
        if current_user.is_client
          @client = PremiumClient.where(client_code: current_user.client_code, changed_status: false, status: true).order(updated_at: :desc).first
          client_acronym = @client ? @client.acronym : ''
          @transactions = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{client_acronym}'").where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
          @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
          @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{current_user.client.acronym}'").where(the_search).order("created_at desc")
        else
          @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
          @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last

          @transactions = Transaction.joiner_not.where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
          @transaction_rep = Transaction.joiner_not.where(the_search).order("created_at desc")

          #end
        end
      end


      logger.info "@user_app = #{@user_app}"


      #  @clients = PremiumClient.active.order('company_name ASC')

      #@transactions = @transactions.where("acronym = '#{current_user.client.acronym}'") if current_user.is_client

    else
      if current_user.is_client
        @client = PremiumClient.where(client_code: current_user.client_code, changed_status: false, status: true).order(updated_at: :desc).first
        client_acronym = @client ? @client.acronym : ''
        @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{client_acronym}'").paginate(:page => @page, :per_page => @per_page).order("created_at desc")
        @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
        @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{client_acronym}'").order("created_at desc")
      else
        @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
        @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last

        # if add_reprocess_joiner
        #   @transactions = Transaction.joiner_not.where(the_search).paginate(:page => page, :per_page => @per_page).order("created_at desc")
        #   @transaction_rep = Transaction.joiner_not.where(the_search).limit(@per_page).order("created_at desc")
        # else
        @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
        @transaction_rep = Transaction.joiner_not.order("created_at desc")

        # end
      end
      puts "@user_app = #{@user_app}"


    end

    @clients = PremiumClient.active.order('company_name ASC')
    @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
    @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)

    if @user_app.present? || !@user_app.nil?
      if @user_app.client_id.present? || !@user_app.client_id.nil?
        @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
        puts "Per Page = #{params[:per_page]}"
        puts "Current User :::::::::: #{@user_app.inspect}"
        puts "UUU User :::::::::: #{@user_app_.inspect}"
        puts "#{@get_current_balance.inspect}"
        logger.info "#{@get_current_balance.inspect}"
      else
        @get_current_balance = "GHs0.00"
      end
    else
      @get_current_balance = "GHs0.00"
    end

    logger.info "Transactions here: #{@transactions.inspect}, current_user = #{current_user.inspect}, current_user.is_client = #{current_user.is_client}, @user_app.needs_approval = #{@user_app.needs_approval}"

    if current_user.is_client
      respond_to do |format|
        format.html
        format.csv {send_data @transactions.to_csv(current_user.client_code, @page, @per_page)}
        format.xls {send_data @transactions.to_csv(current_user.client_code, @page, @per_page, the_search, options = {col_sep: "\t"})}
      end
    else
      respond_to do |format|
        format.html
        format.csv {send_data @transactions.to_admin_csv(@page, @per_page, the_search)}
        format.xls {send_data @transactions.to_admin_csv(@page, @per_page, the_search, options = {col_sep: "\t"})}
      end
    end

    #######################################################
    puts "#{@transactions.inspect}"
    puts "##############################################################################################"
    puts "##############################################################################################"
    puts "##############################################################################################"
    puts "##############################################################################################"
    puts "#{@clients.inspect}"
  end


  def transaction_index

    puts "showing Transactions now "

    if params[:per_page].present?
      if params[:per_page] == "All"
        @per_page = 10000000000000000
      else
        @per_page = params[:per_page].to_i
      end
    else
      @per_page = Transaction.per_page
    end

    logger.info "Normal Pages #{@per_page.inspect}"


    if params[:page] && params[:page].size > 0
      #if params[:page].present?
      @page = params[:page].gsub('?yes', '')
    else
      @page = 1
    end

    if params[:filter_main].present?
      filter_params = params[:filter_main]

      @name = filter_params[:name]
      @trans_id = filter_params[:trans_id]
      @phone_number = filter_params[:phone_number]
      @client_code = filter_params[:client_code]
      @trans_type = filter_params[:trans_type]
      @network = filter_params[:network]
      @status = filter_params[:status]
      @start_date = filter_params[:start_date]
      @end_date = filter_params[:end_date]
      # @per_page = filter_params[:per_page]


      list_of_search_str = []
      the_search = ""


      logger.info "Status status ############################# #{@status.inspect}"
      if @name.present?
        logger.info "#############################################NAME #{Transaction.name_search(@name).inspect}"
        list_of_search_str << Transaction.name_search(@name)
        the_search = the_search + "recipients.recipient_name iLIKE '%#{@name}%' and "
      end

      if @trans_id.present?
        logger.info "#############################################trans id #{Transaction.trans_id_search(@trans_id).inspect}"
        list_of_search_str << Transaction.trans_id_search(@trans_id)
        the_search = the_search + "transaction_ref_id = '#{@trans_id}' and "
        # add_reprocess_joiner = true
      end

      if @phone_number.present?
        logger.info "#############################################phone number #{Transaction.phone_search(@phone_number).inspect}"
        list_of_search_str << Transaction.phone_search(@phone_number)
        the_search = the_search + "transactions.mobile_number iLIKE '%#{@phone_number}%' and "
      end

      if @client_code.present?
        logger.info "#############################################client code #{Transaction.client_code_search(@client_code).inspect}"
        list_of_search_str << Transaction.client_code_search(@client_code)
        the_search = the_search + "recipients.client_code = '#{@client_code}' and "
      end

      if @trans_type.present?
        logger.info "#############################################trans type #{Transaction.trans_type_search(@trans_type).inspect}"
        list_of_search_str << Transaction.trans_type_search(@trans_type)
        the_search = the_search + "trans_type = '#{@trans_type}' and "
      end

      if @network.present?
        logger.info "#############################################Network #{Transaction.network_search(@network)}"
        list_of_search_str << Transaction.network_search(@network)
        the_search = the_search + "recipients.network = '#{@network}' and "
      end

      if @status != "nil"
        logger.info "#############################################Status #{Transaction.status_search(@status).inspect}"

        list_of_search_str << Transaction.status_search(@status)

        if @status == "pending"
          the_search = the_search + "transactions.err_code IS NULL and "
          # "transactions.err_code IS NULL"
        elsif @status == "000" || @status == "001"
          the_search = the_search + "transactions.err_code = '#{@status}' and "
          # "transactions.err_code = '#{@status}'"
        else

        end
      end


      if @start_date.present?
        if @end_date.present?
          logger.info "#############################################Date #{Transaction.search_date(@start_date, @end_date).inspect}"
          list_of_search_str << Transaction.search_date(@start_date, @end_date) if Transaction.search_date(@start_date, @end_date).present?

          @start_date = @start_date + " 00:00:00 UTC"
          @end_date = @end_date + " 23:59:59 UTC"
          the_search = the_search + "transactions.created_at between '" + @start_date + "' and '" + @end_date + "' and "

        end
      end
      logger.info "list of search string is #{list_of_search_str.inspect}"
      search_str = list_of_search_str.join(" AND ")

      logger.info "Search String #{search_str}"

      if !the_search.present?
        if current_user.is_client
          @client = PremiumClient.where(client_code: current_user.client_code, changed_status: false, status: true).order(updated_at: :desc).first
          client_acronym = @client ? @client.acronym : ''
          @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{client_acronym}'").paginate(:page => @page, :per_page => @per_page).order("created_at desc")
          @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
          @transaction_rep = Transaction.joiner(current_user.client_code).order("created_at desc")
        else
          @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
          @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last

          # if add_reprocess_joiner
          #   @transactions = Transaction.joiner_not.where(search_str).paginate(:page => page, :per_page => @per_page).order("created_at desc")
          #   @transaction_rep = Transaction.joiner_not.where(search_str).limit(@per_page).order("created_at desc")
          # else
          @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
          @transaction_rep = Transaction.joiner_not.order("created_at desc")

          #end
        end
      else
        the_search = the_search + "transactions.created_at is not null"
        if current_user.is_client
          @client = PremiumClient.where(client_code: current_user.client_code, changed_status: false, status: true).order(updated_at: :desc).first
          client_acronym = @client ? @client.acronym : ''
          @transactions = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{client_acronym}'").where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
          @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
          @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{client_acronym}'").where(the_search).order("created_at desc")
        else
          @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
          @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last

          @transactions = Transaction.joiner_not.where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
          @transaction_rep = Transaction.joiner_not.where(the_search).order("created_at desc")

          #end
        end
      end


      puts "@user_app = #{@user_app}"


      #  @clients = PremiumClient.active.order('company_name ASC')

      #@transactions = @transactions.where("acronym = '#{current_user.client.acronym}'") if current_user.is_client

    else
      if current_user.is_client
        @client = PremiumClient.where(client_code: current_user.client_code, changed_status: false, status: true).order(updated_at: :desc).first
        client_acronym = @client ? @client.acronym : ''
        @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{client_acronym}'").paginate(:page => @page, :per_page => @per_page.to_i).order("created_at desc")
        @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
        @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{client_acronym}'").order("created_at desc")
      else
        @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
        @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last

        # if add_reprocess_joiner
        #   @transactions = Transaction.joiner_not.where(the_search).paginate(:page => page, :per_page => @per_page).order("created_at desc")
        #   @transaction_rep = Transaction.joiner_not.where(the_search).limit(@per_page).order("created_at desc")
        # else
        @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
        @transaction_rep = Transaction.joiner_not.order("created_at desc")

        # end
      end
      puts "@user_app = #{@user_app}"


    end
    @clients = PremiumClient.active.order('company_name ASC')

    if @user_app.present? || !@user_app.nil?
      if @user_app.client_id.present? || !@user_app.client_id.nil?
        @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
        puts "Per Page = #{params[:per_page]}"
        puts "Current User :::::::::: #{@user_app.inspect}"
        puts "UUU User :::::::::: #{@user_app_.inspect}"
        puts "#{@get_current_balance.inspect}"
      else
        @get_current_balance = "GHs0.00"
      end
    else
      @get_current_balance = "GHs0.00"
    end


    @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
    @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)

    if current_user.is_client
      respond_to do |format|
        format.html
        format.csv {send_data @transactions.to_csv(current_user.client_code, @page, @per_page)}
        format.xls {send_data @transactions.to_csv(current_user.client_code, @page, @per_page, the_search, options = {col_sep: "\t"})}
      end
    else
      respond_to do |format|
        format.html
        format.csv {send_data @transactions.to_admin_csv(@page, @per_page, the_search)}
        format.xls {send_data @transactions.to_admin_csv(@page, @per_page, the_search, options = {col_sep: "\t"})}
      end
    end

    #######################################################
    puts "##############################################################################################"

    puts "#{@transactions.inspect}"
    puts "##############################################################################################"
    puts "##############################################################################################"
    puts "##############################################################################################"
    puts "##############################################################################################"
    puts "#{@clients.inspect}"
  end

  def all_trans_excel
    # if current_user.is_client
    #   @user_app = PremiumClient.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    # else
    #   @user_app = PremiumClient.where(user_id: current_user.id).order('updated_at DESC')[0]
    # end
    # if params[:type] == 'topup'
    #   @transactions = Transaction.subscribed.top_up.order("created_at desc")
    #   filename = "all_topups"
    # elsif params[:type] == 'pending_transactions'
    #   @transactions = Transaction.subscribed.pending.order("created_at desc")
    #   filename = "all_pending_transactions"
    # elsif params[:type] == 'reversals'
    #   @transactions = Transaction.subscribed.reversed.order("created_at desc")
    #   filename = "all_reversals"
    # else
    #   @transactions = Transaction.subscribed.fund_transfer.order("created_at desc")
    #   filename = "all_fund_transfers"
    # end
    #
    # respond_to do |format|
    #   format.html
    #   format.csv {send_data @transactions.to_csv, filename: "#{filename}.csv"}
    #   format.xls {send_data @transactions.to_csv(options = {col_sep: "\t"}), filename: "#{filename}.xls"}
    # end
  end

  def reversals
  end

  def process_reversal

  end

  def manually_close
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      @transaction.user_id = current_user.id
      @transaction.manually_closed = true
      @transaction.save
      flash[:notice] = 'Transaction has been closed'
      format.html {redirect_to request.referer}
    end
  end

  def trans_recipients_import

    @error_code = 0
    respond_to do |format|
      if params[:file].nil?
        @error_code = 2
        format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", :locals => {error_code: @error_code}}
      else
        logger.info params[:recipient]
        logger.info params[:recipient]["reference"]

        the_feed_back = Transaction.import_contacts(params[:file], current_user.client_code, current_user.id, params[:recipient]["reference"])
        if the_feed_back.to_i == 0
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", notice: 'Recipients were successfully Imported.'}
        elsif the_feed_back.to_i == 2
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Wrong file headers. Please download the sample csv file for the right headers'}
        elsif the_feed_back.to_i == 1
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Unknown network.'}
        elsif the_feed_back.to_i == 6
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid row, missing parameters.'}
        elsif the_feed_back.to_i == 4
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Wrong mobile number.'}
        elsif the_feed_back.to_i == 5
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Wrong mobile number format.'}
        elsif the_feed_back.to_i == 3
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid recipient name.'}
        elsif the_feed_back.to_i == 7
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid file.'}
        elsif the_feed_back.to_i == 9
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'File already exists. Kindly rename the file and upload.'}
        elsif the_feed_back.to_i == 8
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid amount.'}
        elsif the_feed_back.to_i == 10
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Please provide a reference between 10 and 25 characters only.'}
        elsif the_feed_back.to_i == 11
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Bank code cannot be blank for bank transactions.'}
        elsif the_feed_back.to_i == 12
          format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid alert number for bank transaction.'}
        else

        end
      end
    end
    # end
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    #@reprocessed = @transaction.transaction_reprocesses
    session[:return_to] ||= request.referer
  end

  # GET /transactions/new
  def new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @transaction = Transaction.new
    @recipient = Recipient.new
    @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id)

    #@recipients = Recipient.active.where(status: true, changed_status: false, user_id: current_user.id).order('created_at desc')
    @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
    @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)

    if @user_app.present? || !@user_app.nil?
      if @user_app.client_id.present? || !@user_app.client_id.nil?
        @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
        puts "Per Page = #{params[:per_page]}"
        puts "Current User :::::::::: #{@user_app.inspect}"
        puts "UUU User :::::::::: #{@user_app_.inspect}"
        puts "#{@get_current_balance.inspect}"
        logger.info "#{@get_current_balance.inspect}"
      else
        @get_current_balance = "GHs0.00"
      end
    else
      @get_current_balance = "GHs0.00"
    end

    logger.info "Total ||||| #{@recipients_total_amount.inspect}"
    puts "######################################################################"
    puts "######################################################################"
    puts @recipients.inspect
    puts "######################################################################"
    puts "######################################################################"
  end

  def disburse_money
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    client_code = params[:client_code]
    disburse_type = params[:disburse_type]


    puts "INCOMING PARAMS:, client_code: #{client_code}" +
             "disburse_type: #{disburse_type},}\n"
    puts "-------------------------------------------------------------------"
    recipients = Recipient.where(disburse_status: false, client_code: client_code, status: true, changed_status: false,user_id: current_user.id)

    puts "RECIPIENTS: #{recipients.inspect}"
    response = Transaction.doPayout(recipients, client_code, disburse_type)

    puts "RESPONSE: #{response.inspect}"

    respond_to do |format|

      format.html {redirect_to transactions_path, notice: response['message']}
      format.json {render :show, status: :created, location: @payout}
    end

  end

  # GET /transactions/1/edit
  def edit
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    @transaction = Transaction.new(transaction_params)
    @recipient = Recipient.new
  end

  def edit_trans_recep
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    recep_id = params[:id]

    # @transaction = Transaction.new(transaction_params)
    @recipients = Recipient.where(id: recep_id, status: true, changed_status: false).order('recipients.created_at desc')
    @recipient = Recipient.new

    puts "#{@recipients.inspect}"
    puts "#{@recipients.inspect}"
  end

  # POST /transactions
  # POST /transactions.json
  def create
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @transaction = Transaction.new(transaction_params)
    @recipient = Recipient.new

    puts "=====================#{@transaction.inspect}"


    respond_to do |format|

      @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, user_id: current_user.id,client_code: current_user.client_code)
      puts "#{@transaction.errors.messages.inspect}"

      if @transaction.valid?
        @recipient = Recipient.new

        @recipient.mobile_number = Transaction.phone_formatter(transaction_params[:mobile_num])
        @recipient.network = transaction_params[:netwk]
        @recipient.recipient_name = transaction_params[:rec_name]
        @recipient.amount = transaction_params[:amt]
        @recipient.client_code = transaction_params[:client_code]
        @recipient.user_id = current_user.id
        @recipient.status = true
        @recipient.changed_status = false
        @recipient.disburse_status = transaction_params[:disburse_status]
        @recipient.save

        puts format.inspect
        flash.now[:notice] = "Recipient was successfully added."
        @transaction = Transaction.new


        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)

        if @user_app.present? || !@user_app.nil?
          if @user_app.client_id.present? || !@user_app.client_id.nil?
            @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
            puts "Per Page = #{params[:per_page]}"
            puts "Current User :::::::::: #{@user_app.inspect}"
            puts "UUU User :::::::::: #{@user_app_.inspect}"
            puts "#{@get_current_balance.inspect}"
            logger.info "#{@get_current_balance.inspect}"
          else
            @get_current_balance = "GHs0.00"
          end
        else
          @get_current_balance = "GHs0.00"
        end
        #format.html {redirect_to @transaction, notice: 'Bank transaction was successfully created.'}
        format.js {render :new}
        format.json {render :show, status: :created, location: @transaction}

      else
        puts "#{@transaction.errors.messages.inspect}"
        @transaction = Transaction.new

        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
        #format.html {render :new}
        if @user_app.present? || !@user_app.nil?
          if @user_app.client_id.present? || !@user_app.client_id.nil?
            @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
            puts "Per Page = #{params[:per_page]}"
            puts "Current User :::::::::: #{@user_app.inspect}"
            puts "UUU User :::::::::: #{@user_app_.inspect}"
            puts "#{@get_current_balance.inspect}"
            logger.info "#{@get_current_balance.inspect}"
          else
            @get_current_balance = "GHs0.00"
          end
        else
          @get_current_balance = "GHs0.00"
        end
        format.js {render :new}
        format.json {render json: @transaction.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /transactions/1
  # PATCH/PUT /transactions/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    # @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
    # @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)

    respond_to do |format|
      if @transaction.update(transaction_params)

        if @user_app.present? || !@user_app.nil?
          if @user_app.client_id.present? || !@user_app.client_id.nil?
            @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
            puts "Per Page = #{params[:per_page]}"
            puts "Current User :::::::::: #{@user_app.inspect}"
            puts "UUU User :::::::::: #{@user_app_.inspect}"
            puts "#{@get_current_balance.inspect}"
            logger.info "#{@get_current_balance.inspect}"
          else
            @get_current_balance = "GHs0.00"
          end
        else
          @get_current_balance = "GHs0.00"
        end

        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
        format.html {redirect_to @transaction, notice: 'Bank transaction was successfully updated.'}
        format.json {render :show, status: :ok, location: @transaction}
      else

        if @user_app.present? || !@user_app.nil?
          if @user_app.client_id.present? || !@user_app.client_id.nil?
            @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
            puts "Per Page = #{params[:per_page]}"
            puts "Current User :::::::::: #{@user_app.inspect}"
            puts "UUU User :::::::::: #{@user_app_.inspect}"
            puts "#{@get_current_balance.inspect}"
            logger.info "#{@get_current_balance.inspect}"
          else
            @get_current_balance = "GHs0.00"
          end
        else
          @get_current_balance = "GHs0.00"
        end

        @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
        @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
        format.html {render :edit}
        format.json {render json: @transaction.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy

    if @user_app.present? || !@user_app.nil?
      if @user_app.client_id.present? || !@user_app.client_id.nil?
        @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
        puts "Per Page = #{params[:per_page]}"
        puts "Current User :::::::::: #{@user_app.inspect}"
        puts "UUU User :::::::::: #{@user_app_.inspect}"
        puts "#{@get_current_balance.inspect}"
        logger.info "#{@get_current_balance.inspect}"
      else
        @get_current_balance = "GHs0.00"
      end
    else
      @get_current_balance = "GHs0.00"
    end

    @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
    @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)

    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @transaction.destroy
    respond_to do |format|
      format.html {redirect_to transactions_url, notice: 'Bank transaction was successfully destroyed.'}
      format.json {head :no_content}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def transaction_params
    params.require(:transaction).permit(:transaction_ref_id, :balance, :mobile_number, :amount, :trans_type, :status,
                                        :network, :err_code, :acronym, :nw_resp, :voucher_code, :payout_id, :csv_uploads_id,:recipient_id,
                                        :mobile_num, :netwk, :amt, :rec_name, :client_code, :disburse_status, :user_id,:bank_code,:sort_code,:swift_code)


  end
end




# class TransactionsController < ApplicationController
#   before_action :set_transaction, only: [:show, :edit, :update, :destroy, :manually_close, :edit_trans_recep]
#   protect_from_forgery except: [:trans_recipients_import]
#   before_action :authenticate_user!
#   # load_and_authorize_resource
#
# # GET /transactions
# # GET /transactions.json
#   def index
#
#
#     # if @user_app.present? || !@user_app.nil?
#     #   if @user_app.client_id.present? || !@user_app.client_id.nil?
#     #     @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#     #     puts "Per Page = #{params[:per_page]}"
#     #     puts "Current User :::::::::: #{@user_app.inspect}"
#     #     puts "UUU User :::::::::: #{@user_app_.inspect}"
#     #     puts "#{@get_current_balance.inspect}"
#     #   else
#     #     @get_current_balance = "GHs0.00"
#     #   end
#     # else
#     #   @get_current_balance = "GHs0.00"
#     # end
#
#     if params[:per_page].present?
#       if params[:per_page] == "All"
#         @per_page = 10000000000000000
#       else
#         @per_page = params[:per_page].to_i
#       end
#     else
#       @per_page = Transaction.per_page
#     end
#
#     logger.info "Normal Pages #{@per_page.inspect}"
#
#
#     if params[:page] && params[:page].size > 0
#     #if params[:page].present?
#       @page = params[:page].gsub('?yes', '')
#     else
#       @page = 1
#     end
#
#     if params[:filter_main].present?
#       filter_params = params[:filter_main]
#
#       @name = filter_params[:name]
#       @trans_id = filter_params[:trans_id]
#       @phone_number = filter_params[:phone_number]
#       @client_code = filter_params[:client_code]
#       @trans_type = filter_params[:trans_type]
#       @network = filter_params[:network]
#       @status = filter_params[:status]
#       @start_date = filter_params[:start_date]
#       @end_date = filter_params[:end_date]
#       # @per_page = filter_params[:perpage]
#
#       # if params[:per_page].present?
#       #   if params[:per_page] == "All"
#       #     @per_page = 10000000000000000
#       #   else
#       #     @per_page = params[:per_page].to_i
#       #   end
#       # else
#       #   @per_page = Transaction.per_page
#       # end
#
#       list_of_search_str = []
#       the_search = ""
#
#
#       logger.info "Status status ############################# #{@status.inspect}"
#       if @name.present?
#         logger.info "#############################################NAME #{Transaction.name_search(@name).inspect}"
#         list_of_search_str << Transaction.name_search(@name)
#         the_search = the_search + "recipients.recipient_name iLIKE '%#{@name}%' and "
#       end
#
#       if @trans_id.present?
#         logger.info "#############################################trans id #{Transaction.trans_id_search(@trans_id).inspect}"
#         list_of_search_str << Transaction.trans_id_search(@trans_id)
#         the_search = the_search + "transaction_ref_id = '#{@trans_id}' and "
#         # add_reprocess_joiner = true
#       end
#
#       if @phone_number.present?
#         logger.info "#############################################phone number #{Transaction.phone_search(@phone_number).inspect}"
#         list_of_search_str << Transaction.phone_search(@phone_number)
#         the_search = the_search + "transactions.mobile_number iLIKE '%#{@phone_number}%' and "
#       end
#
#       if @client_code.present?
#         logger.info "#############################################client code #{Transaction.client_code_search(@client_code).inspect}"
#         list_of_search_str << Transaction.client_code_search(@client_code)
#         the_search = the_search + "recipients.client_code = '#{@client_code}' and "
#       end
#
#       if @trans_type.present?
#         logger.info "#############################################trans type #{Transaction.trans_type_search(@trans_type).inspect}"
#         list_of_search_str << Transaction.trans_type_search(@trans_type)
#         the_search = the_search + "trans_type = '#{@trans_type}' and "
#       end
#
#       if @network.present?
#         logger.info "#############################################Network #{Transaction.network_search(@network)}"
#         list_of_search_str << Transaction.network_search(@network)
#         the_search = the_search + "recipients.network = '#{@network}' and "
#       end
#
#       if @status != "nil"
#         logger.info "#############################################Status #{Transaction.status_search(@status).inspect}"
#
#         list_of_search_str << Transaction.status_search(@status)
#
#         if @status == "pending"
#           the_search = the_search + "transactions.err_code IS NULL and "
#           # "transactions.err_code IS NULL"
#         elsif @status == "000" || @status == "001"
#           the_search = the_search + "transactions.err_code = '#{@status}' and "
#           # "transactions.err_code = '#{@status}'"
#         else
#
#         end
#       end
#
#
#       if @start_date.present?
#         if @end_date.present?
#           logger.info "#############################################Date #{Transaction.search_date(@start_date, @end_date).inspect}"
#           list_of_search_str << Transaction.search_date(@start_date, @end_date) if Transaction.search_date(@start_date, @end_date).present?
#
#           @start_date = @start_date + " 00:00:00 UTC"
#           @end_date = @end_date + " 23:59:59 UTC"
#           the_search = the_search + "transactions.created_at between '" + @start_date + "' and '" + @end_date + "' and "
#
#         end
#       end
#       logger.info "list of search string is #{list_of_search_str.inspect}"
#       search_str = list_of_search_str.join(" AND ")
#
#       logger.info "Search String #{search_str}"
#
#       if !the_search.present?
#         if current_user.is_client
#           @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{current_user.client.acronym}'").paginate(:page => @page, :per_page => @per_page).order("created_at desc")
#           @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
#           @transaction_rep = Transaction.joiner(current_user.client_code).order("created_at desc")
#         else
#           @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
#           @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last
#
#           # if add_reprocess_joiner
#           #   @transactions = Transaction.joiner_not.where(search_str).paginate(:page => page, :per_page => @per_page).order("created_at desc")
#           #   @transaction_rep = Transaction.joiner_not.where(search_str).limit(@per_page).order("created_at desc")
#           # else
#           @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
#           @transaction_rep = Transaction.joiner_not.order("created_at desc")
#
#           #end
#         end
#       else
#         the_search = the_search + "transactions.created_at is not null"
#         if current_user.is_client
#           @transactions = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{current_user.client.acronym}'").where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
#           @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
#           @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{current_user.client.acronym}'").where(the_search).order("created_at desc")
#         else
#           @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
#           @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last
#
#           @transactions = Transaction.joiner_not.where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
#           @transaction_rep = Transaction.joiner_not.where(the_search).order("created_at desc")
#
#           #end
#         end
#       end
#
#
#       puts "@user_app = #{@user_app}"
#
#
#       #  @clients = PremiumClient.active.order('company_name ASC')
#
#       #@transactions = @transactions.where("acronym = '#{current_user.client.acronym}'") if current_user.is_client
#
#     else
#       if current_user.is_client
#         @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{current_user.client.acronym}'").paginate(:page => @page, :per_page => @per_page).order("created_at desc")
#         @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
#         @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{current_user.client.acronym}'").order("created_at desc")
#       else
#         @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
#         @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last
#
#         # if add_reprocess_joiner
#         #   @transactions = Transaction.joiner_not.where(the_search).paginate(:page => page, :per_page => @per_page).order("created_at desc")
#         #   @transaction_rep = Transaction.joiner_not.where(the_search).limit(@per_page).order("created_at desc")
#         # else
#         @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
#         @transaction_rep = Transaction.joiner_not.order("created_at desc")
#
#         # end
#       end
#       puts "@user_app = #{@user_app}"
#
#
#     end
#
#     @clients = PremiumClient.active.order('company_name ASC')
#     @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
#     @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
#
#     if @user_app.present? || !@user_app.nil?
#       if @user_app.client_id.present? || !@user_app.client_id.nil?
#         # @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#         puts "Per Page = #{params[:per_page]}"
#         puts "Current User :::::::::: #{@user_app.inspect}"
#         puts "UUU User :::::::::: #{@user_app_.inspect}"
#         # puts "#{@get_current_balance.inspect}"
#         # logger.info "#{@get_current_balance.inspect}"
#       else
#         @get_current_balance = "GHs0.00"
#       end
#     else
#       @get_current_balance = "GHs0.00"
#     end
#     if current_user.is_client
#       respond_to do |format|
#         format.html
#         format.csv {send_data @transactions.to_csv(current_user.client_code, @page, @per_page)}
#         format.xls {send_data @transactions.to_csv(current_user.client_code, @page, @per_page, the_search, options = {col_sep: "\t"})}
#       end
#     else
#       respond_to do |format|
#         format.html
#         format.csv {send_data @transactions.to_admin_csv(@page, @per_page, the_search)}
#         format.xls {send_data @transactions.to_admin_csv(@page, @per_page, the_search, options = {col_sep: "\t"})}
#       end
#     end
#
#     #######################################################
#     puts "#{@transactions.inspect}"
#     puts "##############################################################################################"
#     puts "##############################################################################################"
#     puts "##############################################################################################"
#     puts "##############################################################################################"
#     puts "#{@clients.inspect}"
#   end
#
#   def transaction_index
#
#     if params[:per_page].present?
#       if params[:per_page] == "All"
#         @per_page = 10000000000000000
#       else
#         @per_page = params[:per_page].to_i
#       end
#     else
#       @per_page = Transaction.per_page
#     end
#
#     logger.info "Normal Pages #{@per_page.inspect}"
#
#
#     if params[:page] && params[:page].size > 0
#     #if params[:page].present?
#       @page = params[:page].gsub('?yes', '')
#     else
#       @page = 1
#     end
#
#     if params[:filter_main].present?
#       filter_params = params[:filter_main]
#
#       @name = filter_params[:name]
#       @trans_id = filter_params[:trans_id]
#       @phone_number = filter_params[:phone_number]
#       @client_code = filter_params[:client_code]
#       @trans_type = filter_params[:trans_type]
#       @network = filter_params[:network]
#       @status = filter_params[:status]
#       @start_date = filter_params[:start_date]
#       @end_date = filter_params[:end_date]
#       # @per_page = filter_params[:per_page]
#
#
#       list_of_search_str = []
#       the_search = ""
#
#
#       logger.info "Status status ############################# #{@status.inspect}"
#       if @name.present?
#         logger.info "#############################################NAME #{Transaction.name_search(@name).inspect}"
#         list_of_search_str << Transaction.name_search(@name)
#         the_search = the_search + "recipients.recipient_name iLIKE '%#{@name}%' and "
#       end
#
#       if @trans_id.present?
#         logger.info "#############################################trans id #{Transaction.trans_id_search(@trans_id).inspect}"
#         list_of_search_str << Transaction.trans_id_search(@trans_id)
#         the_search = the_search + "transaction_ref_id = '#{@trans_id}' and "
#         # add_reprocess_joiner = true
#       end
#
#       if @phone_number.present?
#         logger.info "#############################################phone number #{Transaction.phone_search(@phone_number).inspect}"
#         list_of_search_str << Transaction.phone_search(@phone_number)
#         the_search = the_search + "transactions.mobile_number iLIKE '%#{@phone_number}%' and "
#       end
#
#       if @client_code.present?
#         logger.info "#############################################client code #{Transaction.client_code_search(@client_code).inspect}"
#         list_of_search_str << Transaction.client_code_search(@client_code)
#         the_search = the_search + "recipients.client_code = '#{@client_code}' and "
#       end
#
#       if @trans_type.present?
#         logger.info "#############################################trans type #{Transaction.trans_type_search(@trans_type).inspect}"
#         list_of_search_str << Transaction.trans_type_search(@trans_type)
#         the_search = the_search + "trans_type = '#{@trans_type}' and "
#       end
#
#       if @network.present?
#         logger.info "#############################################Network #{Transaction.network_search(@network)}"
#         list_of_search_str << Transaction.network_search(@network)
#         the_search = the_search + "recipients.network = '#{@network}' and "
#       end
#
#       if @status != "nil"
#         logger.info "#############################################Status #{Transaction.status_search(@status).inspect}"
#
#         list_of_search_str << Transaction.status_search(@status)
#
#         if @status == "pending"
#           the_search = the_search + "transactions.err_code IS NULL and "
#           # "transactions.err_code IS NULL"
#         elsif @status == "000" || @status == "001"
#           the_search = the_search + "transactions.err_code = '#{@status}' and "
#           # "transactions.err_code = '#{@status}'"
#         else
#
#         end
#       end
#
#
#       if @start_date.present?
#         if @end_date.present?
#           logger.info "#############################################Date #{Transaction.search_date(@start_date, @end_date).inspect}"
#           list_of_search_str << Transaction.search_date(@start_date, @end_date) if Transaction.search_date(@start_date, @end_date).present?
#
#           @start_date = @start_date + " 00:00:00 UTC"
#           @end_date = @end_date + " 23:59:59 UTC"
#           the_search = the_search + "transactions.created_at between '" + @start_date + "' and '" + @end_date + "' and "
#
#         end
#       end
#       logger.info "list of search string is #{list_of_search_str.inspect}"
#       search_str = list_of_search_str.join(" AND ")
#
#       logger.info "Search String #{search_str}"
#
#       if !the_search.present?
#         if current_user.is_client
#           @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{current_user.client.acronym}'").paginate(:page => @page, :per_page => @per_page).order("created_at desc")
#           @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
#           @transaction_rep = Transaction.joiner(current_user.client_code).order("created_at desc")
#         else
#           @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
#           @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last
#
#           # if add_reprocess_joiner
#           #   @transactions = Transaction.joiner_not.where(search_str).paginate(:page => page, :per_page => @per_page).order("created_at desc")
#           #   @transaction_rep = Transaction.joiner_not.where(search_str).limit(@per_page).order("created_at desc")
#           # else
#           @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
#           @transaction_rep = Transaction.joiner_not.order("created_at desc")
#
#           #end
#         end
#       else
#         the_search = the_search + "transactions.created_at is not null"
#         if current_user.is_client
#           @transactions = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{current_user.client.acronym}'").where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
#           @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
#           @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{current_user.client.acronym}'").where(the_search).order("created_at desc")
#         else
#           @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
#           @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last
#
#           @transactions = Transaction.joiner_not.where(the_search).paginate(page: @page, per_page: @per_page).order("created_at desc")
#           @transaction_rep = Transaction.joiner_not.where(the_search).order("created_at desc")
#
#           #end
#         end
#       end
#
#
#       puts "@user_app = #{@user_app}"
#
#
#       #  @clients = PremiumClient.active.order('company_name ASC')
#
#       #@transactions = @transactions.where("acronym = '#{current_user.client.acronym}'") if current_user.is_client
#
#     else
#       if current_user.is_client
#         @transactions = Transaction.joiner(current_user.client_code).where(the_search).where("premium_clients.acronym = '#{current_user.client.acronym}'").paginate(:page => @page, :per_page => @per_page.to_i).order("created_at desc")
#         @user_app = PremiumClient.where(client_code: current_user.client_code).active.order('updated_at DESC')[0]
#         @transaction_rep = Transaction.joiner(current_user.client_code).where("premium_clients.acronym = '#{current_user.client.acronym}'").order("created_at desc")
#       else
#         @user_app = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC')[0]
#         @user_app_ = PremiumClient.where(user_id: current_user.id).active.order('updated_at DESC').last
#
#         # if add_reprocess_joiner
#         #   @transactions = Transaction.joiner_not.where(the_search).paginate(:page => page, :per_page => @per_page).order("created_at desc")
#         #   @transaction_rep = Transaction.joiner_not.where(the_search).limit(@per_page).order("created_at desc")
#         # else
#         @transactions = Transaction.joiner_not.where(the_search).paginate(:page => @page, :per_page => @per_page).order("created_at desc")
#         @transaction_rep = Transaction.joiner_not.order("created_at desc")
#
#         # end
#       end
#       puts "@user_app = #{@user_app}"
#
#
#     end
#     @clients = PremiumClient.active.order('company_name ASC')
#
#     if @user_app.present? || !@user_app.nil?
#       if @user_app.client_id.present? || !@user_app.client_id.nil?
#         @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#         puts "Per Page = #{params[:per_page]}"
#         puts "Current User :::::::::: #{@user_app.inspect}"
#         puts "UUU User :::::::::: #{@user_app_.inspect}"
#         puts "#{@get_current_balance.inspect}"
#       else
#         @get_current_balance = "GH₵0.00"
#       end
#     else
#       @get_current_balance = "GH₵0.00"
#     end
#
#
#     @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
#     @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
#
#     if current_user.is_client
#       respond_to do |format|
#         format.html
#         format.csv {send_data @transactions.to_csv(current_user.client_code, @page, @per_page)}
#         format.xls {send_data @transactions.to_csv(current_user.client_code, @page, @per_page, the_search, options = {col_sep: "\t"})}
#       end
#     else
#       respond_to do |format|
#         format.html
#         format.csv {send_data @transactions.to_admin_csv(@page, @per_page, the_search)}
#         format.xls {send_data @transactions.to_admin_csv(@page, @per_page, the_search, options = {col_sep: "\t"})}
#       end
#     end
#
#     #######################################################
#     puts "#{@transactions.inspect}"
#     puts "##############################################################################################"
#     puts "##############################################################################################"
#     puts "##############################################################################################"
#     puts "##############################################################################################"
#     puts "#{@clients.inspect}"
#   end
#
#   def all_trans_excel
#     # if current_user.is_client
#     #   @user_app = PremiumClient.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     # else
#     #   @user_app = PremiumClient.where(user_id: current_user.id).order('updated_at DESC')[0]
#     # end
#     # if params[:type] == 'topup'
#     #   @transactions = Transaction.subscribed.top_up.order("created_at desc")
#     #   filename = "all_topups"
#     # elsif params[:type] == 'pending_transactions'
#     #   @transactions = Transaction.subscribed.pending.order("created_at desc")
#     #   filename = "all_pending_transactions"
#     # elsif params[:type] == 'reversals'
#     #   @transactions = Transaction.subscribed.reversed.order("created_at desc")
#     #   filename = "all_reversals"
#     # else
#     #   @transactions = Transaction.subscribed.fund_transfer.order("created_at desc")
#     #   filename = "all_fund_transfers"
#     # end
#     #
#     # respond_to do |format|
#     #   format.html
#     #   format.csv {send_data @transactions.to_csv, filename: "#{filename}.csv"}
#     #   format.xls {send_data @transactions.to_csv(options = {col_sep: "\t"}), filename: "#{filename}.xls"}
#     # end
#   end
#
#   def reversals
#   end
#
#   def process_reversal
#
#   end
#
#   def manually_close
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     respond_to do |format|
#       @transaction.user_id = current_user.id
#       @transaction.manually_closed = true
#       @transaction.save
#       flash[:notice] = 'Transaction has been closed'
#       format.html {redirect_to request.referer}
#     end
#   end
#
#   def trans_recipients_import
#
#     @error_code = 0
#     respond_to do |format|
#       if params[:file].nil?
#         @error_code = 2
#         format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", :locals => {error_code: @error_code}}
#       else
#         the_feed_back = Transaction.import_contacts(params[:file], current_user.client_code,current_user.id)
#         if the_feed_back.to_i == 0
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", notice: 'Recipients were successfully Imported.'}
#         elsif the_feed_back.to_i == 2
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Wrong file headers. Please download the sample csv file for the right headers'}
#         elsif the_feed_back.to_i == 1
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Unknown network.'}
#         elsif the_feed_back.to_i == 6
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid row, missing parameters.'}
#         elsif the_feed_back.to_i == 4
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Wrong mobile number.'}
#         elsif the_feed_back.to_i == 5
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Wrong mobile number format.'}
#         elsif the_feed_back.to_i == 3
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid recipient name.'}
#         elsif the_feed_back.to_i == 7
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid file.'}
#         elsif the_feed_back.to_i == 9
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'File already exists. Kindly rename the file and upload.'}
#         elsif the_feed_back.to_i == 8
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Invalid amount.'}
#         elsif the_feed_back.to_i == 10
#           format.html {redirect_to "/transactions/new?after_upload=#{params[:after_upload]}", alert: 'Please reference to Identify certain transactions.'}
#         else
#
#         end
#       end
#     end
#     # end
#   end
#
# # GET /transactions/1
# # GET /transactions/1.json
#   def show
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     #@reprocessed = @transaction.transaction_reprocesses
#     session[:return_to] ||= request.referer
#   end
#
# # GET /transactions/new
#   def new
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @transaction = Transaction.new
#     @recipient = Recipient.new
#     @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id)
#
#     #@recipients = Recipient.active.where(status: true, changed_status: false, user_id: current_user.id).order('created_at desc')
#     @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
#     @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
#
#     if @user_app.present? || !@user_app.nil?
#       if @user_app.client_id.present? || !@user_app.client_id.nil?
#         @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#         puts "Per Page = #{params[:per_page]}"
#         puts "Current User :::::::::: #{@user_app.inspect}"
#         puts "UUU User :::::::::: #{@user_app_.inspect}"
#         puts "#{@get_current_balance.inspect}"
#         logger.info "#{@get_current_balance.inspect}"
#       else
#         @get_current_balance = "GH₵0.00"
#       end
#     else
#       @get_current_balance = "GH₵0.00"
#     end
#
#     logger.info "Total ||||| #{@recipients_total_amount.inspect}"
#     puts "######################################################################"
#     puts "######################################################################"
#     puts @recipients.inspect
#     puts "######################################################################"
#     puts "######################################################################"
#   end
#
#   def disburse_money
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     client_code = params[:client_code]
#     disburse_type = params[:disburse_type]
#
#
#     puts "INCOMING PARAMS:, client_code: #{client_code}" +
#              "disburse_type: #{disburse_type},}\n"
#     puts "-------------------------------------------------------------------"
#     recipients = Recipient.where(disburse_status: false, client_code: client_code, status: true, changed_status: false,user_id: current_user.id)
#
#     puts "RECIPIENTS: #{recipients.inspect}"
#     response = Transaction.doPayout(recipients, client_code, disburse_type)
#
#     puts "RESPONSE: #{response.inspect}"
#
#     respond_to do |format|
#
#       format.html {redirect_to transactions_path, notice: response['message']}
#       format.json {render :show, status: :created, location: @payout}
#     end
#
#   end
#
# # GET /transactions/1/edit
#   def edit
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     @transaction = Transaction.new(transaction_params)
#     @recipient = Recipient.new
#   end
#
#
#   def edit_trans_recep
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     recep_id = params[:id]
#
#     # @transaction = Transaction.new(transaction_params)
#     @recipients = Recipient.where(id: recep_id, status: true, changed_status: false).order('recipients.created_at desc')
#     @recipient = Recipient.new
#
#     puts "#{@recipients.inspect}"
#     puts "#{@recipients.inspect}"
#   end
#
# # POST /transactions
# # POST /transactions.json
#   def create
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @transaction = Transaction.new(transaction_params)
#     @recipient = Recipient.new
#
#     puts "=====================#{@transaction.inspect}"
#
#
#     respond_to do |format|
#
#       @recipients = Recipient.where(status: true, disburse_status: false, changed_status: false, user_id: current_user.id,client_code: current_user.client_code)
#       puts "#{@transaction.errors.messages.inspect}"
#
#       if @transaction.valid?
#         @recipient = Recipient.new
#
#         @recipient.mobile_number = Transaction.phone_formatter(transaction_params[:mobile_num])
#         @recipient.network = transaction_params[:netwk]
#         @recipient.recipient_name = transaction_params[:rec_name]
#         @recipient.amount = transaction_params[:amt]
#         @recipient.client_code = transaction_params[:client_code]
#         @recipient.user_id = current_user.id
#         @recipient.status = true
#         @recipient.changed_status = false
#         @recipient.disburse_status = transaction_params[:disburse_status]
#         @recipient.save
#
#         puts format.inspect
#         flash.now[:notice] = "Recipient was successfully added."
#         @transaction = Transaction.new
#
#
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
#
#         if @user_app.present? || !@user_app.nil?
#           if @user_app.client_id.present? || !@user_app.client_id.nil?
#             @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#             puts "Per Page = #{params[:per_page]}"
#             puts "Current User :::::::::: #{@user_app.inspect}"
#             puts "UUU User :::::::::: #{@user_app_.inspect}"
#             puts "#{@get_current_balance.inspect}"
#             logger.info "#{@get_current_balance.inspect}"
#           else
#             @get_current_balance = "GHs0.00"
#           end
#         else
#           @get_current_balance = "GHs0.00"
#         end
#         #format.html {redirect_to @transaction, notice: 'Bank transaction was successfully created.'}
#         format.js {render :new}
#         format.json {render :show, status: :created, location: @transaction}
#
#       else
#         puts "#{@transaction.errors.messages.inspect}"
#         @transaction = Transaction.new
#
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
#         #format.html {render :new}
#         if @user_app.present? || !@user_app.nil?
#           if @user_app.client_id.present? || !@user_app.client_id.nil?
#             @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#             puts "Per Page = #{params[:per_page]}"
#             puts "Current User :::::::::: #{@user_app.inspect}"
#             puts "UUU User :::::::::: #{@user_app_.inspect}"
#             puts "#{@get_current_balance.inspect}"
#             logger.info "#{@get_current_balance.inspect}"
#           else
#             @get_current_balance = "GHs0.00"
#           end
#         else
#           @get_current_balance = "GHs0.00"
#         end
#         format.js {render :new}
#         format.json {render json: @transaction.errors, status: :unprocessable_entity}
#       end
#     end
#   end
#
# # PATCH/PUT /transactions/1
# # PATCH/PUT /transactions/1.json
#   def update
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     # @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
#     # @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
#
#     respond_to do |format|
#       if @transaction.update(transaction_params)
#
#         if @user_app.present? || !@user_app.nil?
#           if @user_app.client_id.present? || !@user_app.client_id.nil?
#             @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#             puts "Per Page = #{params[:per_page]}"
#             puts "Current User :::::::::: #{@user_app.inspect}"
#             puts "UUU User :::::::::: #{@user_app_.inspect}"
#             puts "#{@get_current_balance.inspect}"
#             logger.info "#{@get_current_balance.inspect}"
#           else
#             @get_current_balance = "GHs0.00"
#           end
#         else
#           @get_current_balance = "GHs0.00"
#         end
#
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
#         format.html {redirect_to @transaction, notice: 'Bank transaction was successfully updated.'}
#         format.json {render :show, status: :ok, location: @transaction}
#       else
#
#         if @user_app.present? || !@user_app.nil?
#           if @user_app.client_id.present? || !@user_app.client_id.nil?
#             @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#             puts "Per Page = #{params[:per_page]}"
#             puts "Current User :::::::::: #{@user_app.inspect}"
#             puts "UUU User :::::::::: #{@user_app_.inspect}"
#             puts "#{@get_current_balance.inspect}"
#             logger.info "#{@get_current_balance.inspect}"
#           else
#             @get_current_balance = "GHs0.00"
#           end
#         else
#           @get_current_balance = "GHs0.00"
#         end
#
#         @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).count
#         @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code).sum(:amount)
#         format.html {render :edit}
#         format.json {render json: @transaction.errors, status: :unprocessable_entity}
#       end
#     end
#   end
#
# # DELETE /transactions/1
# # DELETE /transactions/1.json
#   def destroy
#
#     if @user_app.present? || !@user_app.nil?
#       if @user_app.client_id.present? || !@user_app.client_id.nil?
#         @get_current_balance = Transaction.get_current_balance(@user_app.client_id, @user_app.secret_key, @user_app.client_key)
#         puts "Per Page = #{params[:per_page]}"
#         puts "Current User :::::::::: #{@user_app.inspect}"
#         puts "UUU User :::::::::: #{@user_app_.inspect}"
#         puts "#{@get_current_balance.inspect}"
#         logger.info "#{@get_current_balance.inspect}"
#       else
#         @get_current_balance = "GHs0.00"
#       end
#     else
#       @get_current_balance = "GHs0.00"
#     end
#
#     @recipients_count = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).count
#     @recipients_total_amount = Recipient.where(status: true, disburse_status: false, changed_status: false, client_code: current_user.client_code,user_id: current_user.id).sum(:amount)
#
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @transaction.destroy
#     respond_to do |format|
#       format.html {redirect_to transactions_url, notice: 'Bank transaction was successfully destroyed.'}
#       format.json {head :no_content}
#     end
#   end
#
#   private
#
# # Use callbacks to share common setup or constraints between actions.
#   def set_transaction
#     @transaction = Transaction.find(params[:id])
#   end
#
# # Never trust parameters from the scary internet, only allow the white list through.
#   def transaction_params
#     params.require(:transaction).permit(:transaction_ref_id, :balance, :mobile_number, :amount, :trans_type, :status,
#                                         :network, :err_code, :acronym, :nw_resp, :voucher_code, :payout_id, :csv_uploads_id,:recipient_id,
#                                         :mobile_num, :netwk, :amt, :rec_name, :client_code, :disburse_status, :user_id)
#
#
#   end
# end
