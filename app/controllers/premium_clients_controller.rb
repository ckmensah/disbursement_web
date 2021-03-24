class PremiumClientsController < ApplicationController
  before_action :set_premium_client, only: [:show, :edit, :update, :destroy]

  # GET /premium_clients
  # GET /premium_clients.json
  def index
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @premium_clients = PremiumClient.active.order('created_at desc')
  end

  # GET /premium_clients/1
  # GET /premium_clients/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  # GET /premium_clients/new
  def new
    @premium_client = PremiumClient.new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  # GET /premium_clients/1/edit
  def edit
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    #@account_object = ClientAcctNumber.find_by(client_code: @premium_client.id, status: true, changed_status: false)
  end

  # POST /premium_clients
  # POST /premium_clients.json
  def create
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @premium_client = PremiumClient.new(premium_client_params)
    # @premium_client.client_code = PremiumClient.generate_client_code
    #logger.info "@premium_client object: #{@premium_client.inspect}"
    #@premium_client.subscriber_code = Subscription.generate_subscriber_code
    respond_to do |format|
      if @premium_client.save

        format.html {redirect_to @premium_client, notice: 'Premium client was successfully created.'}
        format.json {render :show, status: :created, location: @premium_client}
      else
        format.html {render :new}
        format.json {render json: @premium_client.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /premium_clients/1
  # PATCH/PUT /premium_clients/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      # @client_fail = PremiumClient.new(premium_client_params)

      @new_client = PremiumClient.new(@premium_client.attributes)
      @new_client.company_name = premium_client_params[:company_name] unless premium_client_params[:company_name].blank?
      @new_client.email = premium_client_params[:email] unless premium_client_params[:email].blank?
      @new_client.client_id = premium_client_params[:client_id] unless premium_client_params[:client_id].blank?
      @new_client.contact_number = premium_client_params[:contact_number] unless premium_client_params[:contact_number].blank?
      @new_client.client_key = premium_client_params[:client_key] unless premium_client_params[:client_key].blank?
      @new_client.secret_key = premium_client_params[:secret_key] unless premium_client_params[:secret_key].blank?
      @new_client.sms_key = premium_client_params[:sms_key] unless premium_client_params[:sms_key].blank?
      @new_client.success_msg = premium_client_params[:success_msg] unless premium_client_params[:success_msg].blank?
      @new_client.needs_approval = premium_client_params[:needs_approval] unless premium_client_params[:needs_approval].blank?
      @new_client.sender_id = premium_client_params[:sender_id] unless premium_client_params[:sender_id].blank?
      @new_client.user_id = current_user.id
      @new_client.updated_at = Time.now

      if @new_client.save
       update_last_but_one('premium_clients', 'client_code', @new_client.client_code)
        format.html {redirect_to premium_clients_path, notice: 'Premium client was successfully updated.'}
        format.json {render :show, status: :ok, location: @premium_client}
      else
        # @client_fail.save
        # @premium_client = PremiumClient.new(premium_client_params)
        # @premium_client.save
        format.html {render :edit}
        format.json {render json: @premium_client.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /premium_clients/1
  # DELETE /premium_clients/1.json
  def destroy
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @new_client = PremiumClient.new(@premium_client.attributes)
    @new_client.user_id = current_user.id
    @new_client.save

    @premium_client.update(status: false)
    update_last_but_one('premium_clients', 'client_code', @new_client.client_code)
    respond_to do |format|
      format.html {redirect_to premium_clients_url, notice: 'Premium client was successfully destroyed.'}
      format.json {head :no_content}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_premium_client
    #@premium_client = PremiumClient.find(params[:id])
    @premium_client = PremiumClient.where(client_code: params[:id], status: true, changed_status: false).order('id desc')[0]

  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def premium_client_params
    params.require(:premium_client).permit(:success_msg, :company_name, :email, :client_code, :contact_number, :client_id, :client_key, :secret_key, :changed_status, :status, :user_id, :acronym, :sms_key, :needs_approval, :sender_id)
  end

  def update_last_but_one(table, id_field, id)
    sql = "UPDATE #{table} SET changed_status = true WHERE id = (SELECT id FROM #{table} WHERE #{id_field} = '#{id}' AND status = true AND changed_status = false ORDER BY id ASC LIMIT 1)"
    val = ActiveRecord::Base.connection.execute(sql)
    #logger "VALUE: #{val.inspect}"
  end
end
