class RecipientGroupsController < ApplicationController
  before_action :set_recipient_group, only: [:show, :edit, :update, :destroy]

  # GET /recipient_groups
  # GET /recipient_groups.json
  def index

    if params[:page] && params[:page].size > 0
      page = params[:page].to_i
    else
      page = 1
    end


    if current_user.ultra? || current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
      @recipient_groups = RecipientGroup.all.paginate(:page => page, :per_page => 10).order('recipient_groups.created_at desc')
    else
      if current_user.is_client
        @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
      else
        @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      end
      @recipient_groups = RecipientGroup.where(client_code: current_user.client_code).paginate(:page => page, :per_page => 10).order('recipient_groups.created_at desc')
    end
    if current_user.is_client && @user_app.needs_approval
      render 'recipient_groups/index'
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render 'recipient_groups/index'
    end
  end

  # GET /recipient_groups/1
  # GET /recipient_groups/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    if current_user.is_client && @user_app.needs_approval
      render :show
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render :show
    end
  end

  # GET /recipient_groups/new
  def new

    @recipient_group = RecipientGroup.new
    if current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      @clients = PremiumClient.active
      @approver_cats = ApproversCategory.all
    else
      if current_user.is_client
        @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
      else
        @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      end
      @clients = PremiumClient.where(client_code: current_user.client_code).active
      @approver_cats = ApproversCategory.where(client_code: current_user.client_code)
    end


    if current_user.is_client && @user_app.needs_approval
      render :new
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render :new
    end
  end

  # GET /recipient_groups/1/edit
  def edit

    if current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      @clients = PremiumClient.active
      @approver_cats = ApproversCategory.all
    else
      if current_user.is_client
        @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
      else
        @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      end
      @approver_cats = ApproversCategory.where(client_code: current_user.client_code)
      @clients = PremiumClient.where(client_code: current_user.client_code).active
    end

    if current_user.is_client && @user_app.needs_approval
      render :edit
    elsif current_user.is_client && !@user_app.needs_approval
      render 'transactions/index'
      # format.html {redirect_to :controller => 'transactions', :action => 'index'}
      #format.json {render json: {status: true}}
    else
      render :edit
    end
  end

  # POST /recipient_groups
  # POST /recipient_groups.json
  def create
    @recipient_group = RecipientGroup.new(recipient_group_params)
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @recipient_group.save
        format.html { redirect_to recipient_groups_path, notice: 'Recipient group was successfully created.' }
        format.json { render :show, status: :created, location: @recipient_group }
      else
        format.html { render :new }
        format.json { render json: @recipient_group.errors, status: :unprocessable_entity }
      end
    end

  end

  # PATCH/PUT /recipient_groups/1
  # PATCH/PUT /recipient_groups/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @recipient_group.update(recipient_group_params)
        format.html { redirect_to recipient_groups_path, notice: 'Recipient group was successfully updated.' }
        format.json { render :show, status: :ok, location: @recipient_group }
      else
        format.html { render :edit }
        format.json { render json: @recipient_group.errors, status: :unprocessable_entity }
      end
    end

  end

  # DELETE /recipient_groups/1
  # DELETE /recipient_groups/1.json
  def destroy
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @recipient_group.destroy
    respond_to do |format|
      format.html { redirect_to recipient_groups_url, notice: 'Recipient group was successfully destroyed.' }
      format.json { head :no_content }
    end

    respond_to do |format|
      if @user_app.needs_approval

      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_recipient_group
    @recipient_group = RecipientGroup.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def recipient_group_params
    params.require(:recipient_group).permit(:group_desc, :client_code, :approver_cat_id, :approver_code, :status)
  end
end
