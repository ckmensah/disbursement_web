class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  # load_and_authorize_resource

  # GET /users
  # GET /users.json
  def index

    if params[:per_page] && params[:per_page].size > 0
      per_page = params[:per_page]
    else
      per_page = Recipient.per_page
    end

    if params[:page] && params[:page].size > 0
      page = params[:page].to_i
    else
      page = 1
    end

    list_of_search_str = []
    list_of_search_str << User.name_search(params[:name]) unless params[:name].blank?
    list_of_search_str << User.search_username(params[:username]) unless params[:username].blank? # nil, [], '', '  '
    # logger.info "PARAMS FOR START DATE: #{params[:start_date]}, of class #{params[:start_date].class}"
    # logger.info "PARAMS FOR END DATE: #{params[:end_date]}, of class #{params[:end_date].class}"
    list_of_search_str << User.search_role(params[:role]) unless params[:role].blank?
    search_str = list_of_search_str.join(" AND ")

    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
      @users = User.joiner.where(search_str).active.client_results(current_user.client_code).paginate(:page => page, :per_page => per_page).order('created_at desc')
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
      @users = User.joiner.where(search_str).active.paginate(:page => page, :per_page => per_page).order('created_at desc')
    end

    logger.info "USERS LIST: #{@users.inspect}"
  end

  # GET /users/1
  # GET /users/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  # GET /users/new
  def new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @user = User.new
    if current_user.ultra? || current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
      @clients = PremiumClient.active
    else
      @clients = PremiumClient.where(client_code: current_user.client_code).active
    end

  end

  # GET /users/1/edit
  def edit
    if current_user.ultra? || current_user.s_user?
      @clients = PremiumClient.active
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
    else
      if current_user.is_client
        @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
      else
        @user_app = PremiumClient.active.where(client_code: current_user.id).order('updated_at DESC').first
      end
      @clients = PremiumClient.where(client_code: current_user.client_code).active
    end
  end
# POST /users
# POST /users.json
def create
  if current_user.is_client
    @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
  else
    @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
  end

  @user = User.new(user_params)

  respond_to do |format|
    if @user.save
      format.html { redirect_to @user, notice: 'user was successfully created.' }
      format.json { render :show, status: :created, location: @user }
    else
      if current_user.ultra? || current_user.s_user?
        @clients = PremiumClient.active
      else
        @clients = PremiumClient.where(client_code: current_user.client_code).active
      end

      format.html { render :new }
      format.json { render json: @user.errors, status: :unprocessable_entity }
    end
  end
end

# PATCH/PUT /users/1
# PATCH/PUT /users/1.json
def update
  if current_user.is_client
    @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
  else
    @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
  end
  respond_to do |format|
    #log it
    log = UsersLog.create(
        idd: @user.id,
        email: @user.email,
        encrypted_password: @user.encrypted_password,
        reset_password_token: @user.reset_password_token,
        # reset_password_sent_at: @user.reset_password_sent_at,
        remember_created_at: @user.remember_created_at,
        sign_in_count: @user.sign_in_count,
        current_user_sign_in_at: @user.current_sign_in_at,
        last_sign_in_at: @user.last_sign_in_at,
        current_sign_in_ip: @user.current_sign_in_ip,
        last_sign_in_ip: @user.last_sign_in_ip,
        username: @user.username,
        other_names: @user.other_names,
        mobile_number: @user.mobile_number,
        role_id: @user.role_id,
        lastname: @user.lastname,
        creator_id: @user.creator_id,
        active_status: @user.active_status,
        user_idd: current_user.id,
        old_created_at: @user.created_at,


    )

    if @user.update(user_params)
      format.html { redirect_to @user, notice: 'User was successfully updated.' }
      format.json { render :show, status: :ok, location: @user }
      log.save_status = true
      log.save
    else
      format.html { render :edit }
      format.json { render json: @user.errors, status: :unprocessable_entity }
    end
  end
end

# DELETE /users/1
# DELETE /users/1.json
def destroy
  if current_user.is_client
    @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
  else
    @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
  end
  log = UsersLog.create(
      idd: @user.id,
      email: @user.email,
      encrypted_password: @user.encrypted_password,
      reset_password_token: @user.reset_password_token,
      # reset_password_sent_at: @user.reset_password_sent_at,
      remember_created_at: @user.remember_created_at,
      sign_in_count: @user.sign_in_count,
      current_user_sign_in_at: @user.current_sign_in_at,
      last_sign_in_at: @user.last_sign_in_at,
      current_sign_in_ip: @user.current_sign_in_ip,
      last_sign_in_ip: @user.last_sign_in_ip,
      username: @user.username,
      other_names: @user.other_names,
      mobile_number: @user.mobile_number,
      role_id: @user.role_id,
      lastname: @user.lastname,
      creator_id: @user.creator_id,
      active_status: @user.active_status,
      user_idd: current_user.id,
      old_created_at: @user.created_at,

  )

  logger.info "USER DETAILS: #{@user.attributes.inspect}"
  # @deleted_user = DeletedUser.new(@user.attributes)
  # @deleted_user.save

  @user.update(username: @user.username + "_deleted", password: nil, active_status: false)
  log.save_status = true
  log.deleted = true
  log.save
  respond_to do |format|
    format.html { redirect_to users_url, notice: 'user was successfully deleted.' }
    format.json { head :no_content }
  end
end

private
# Use callbacks to share common setup or constraints between actions.
def set_user
  @user = User.find(params[:id])
end


# Never trust parameters from the scary internet, only allow the white list through.
def user_params
  params.require(:user).permit(:active_status, :client_code, :reversal_msg, :username, :email, :password, :password_confirmation, :role_id, :lastname, :other_names,
                               :mobile_number, :creator_id, :status)
end

end
