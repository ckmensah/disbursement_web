class PayoutApprovalsController < ApplicationController
  load_and_authorize_resource
  before_action :set_payout_approval, only: [:show, :edit, :update, :destroy]

  # GET /payout_approvals
  # GET /payout_approvals.json
  def index
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @payout_approvals = PayoutApproval.all
    respond_to do |format|
      if @user_app.needs_approval

      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # GET /payout_approvals/1
  # GET /payout_approvals/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @user_app.needs_approval

      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # GET /payout_approvals/new
  def new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @payout_approval = PayoutApproval.new
    respond_to do |format|
      if @user_app.needs_approval

      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # GET /payout_approvals/1/edit
  def edit
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @user_app.needs_approval

      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # POST /payout_approvals
  # POST /payout_approvals.json
  def create
    @payout_approval = PayoutApproval.new(payout_approval_params)
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @payout_approval.save
        format.html { redirect_to @payout_approval, notice: 'Payout approval was successfully created.' }
        format.json { render :show, status: :created, location: @payout_approval }
      else
        format.html { render :new }
        format.json { render json: @payout_approval.errors, status: :unprocessable_entity }
      end
    end

    respond_to do |format|
      if @user_app.needs_approval

      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # PATCH/PUT /payout_approvals/1
  # PATCH/PUT /payout_approvals/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @payout_approval.update(payout_approval_params)
        format.html { redirect_to @payout_approval, notice: 'Payout approval was successfully updated.' }
        format.json { render :show, status: :ok, location: @payout_approval }
      else
        format.html { render :edit }
        format.json { render json: @payout_approval.errors, status: :unprocessable_entity }
      end
    end

    respond_to do |format|
      if @user_app.needs_approval

      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # DELETE /payout_approvals/1
  # DELETE /payout_approvals/1.json
  def destroy
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @payout_approval.destroy
    respond_to do |format|
      format.html { redirect_to payout_approvals_url, notice: 'Payout approval was successfully destroyed.' }
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
    def set_payout_approval
      @payout_approval = PayoutApproval.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def payout_approval_params
      params.require(:payout_approval).permit(:payout_id, :approver_code, :approved, :status, :notified, :level)
    end
end
