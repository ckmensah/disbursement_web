class TransactionReprocessesController < ApplicationController
  before_action :set_transaction_reprocess, only: [:show, :edit, :update, :destroy]

  # GET /transaction_reprocesses
  # GET /transaction_reprocesses.json
  def index
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @transaction_reprocesses = TransactionReprocess.all
  end

  # GET /transaction_reprocesses/1
  # GET /transaction_reprocesses/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  # GET /transaction_reprocesses/new
  def new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @transaction_reprocess = TransactionReprocess.new
  end

  # GET /transaction_reprocesses/1/edit
  def edit
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  # POST /transaction_reprocesses
  # POST /transaction_reprocesses.json
  def create
    @transaction_reprocess = TransactionReprocess.new(transaction_reprocess_params)
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @transaction_reprocess.save
        format.html { redirect_to @transaction_reprocess, notice: 'Transaction reprocess was successfully created.' }
        format.json { render :show, status: :created, location: @transaction_reprocess }
      else
        format.html { render :new }
        format.json { render json: @transaction_reprocess.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transaction_reprocesses/1
  # PATCH/PUT /transaction_reprocesses/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @transaction_reprocess.update(transaction_reprocess_params)
        format.html { redirect_to @transaction_reprocess, notice: 'Transaction reprocess was successfully updated.' }
        format.json { render :show, status: :ok, location: @transaction_reprocess }
      else
        format.html { render :edit }
        format.json { render json: @transaction_reprocess.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transaction_reprocesses/1
  # DELETE /transaction_reprocesses/1.json
  def destroy
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @transaction_reprocess.destroy
    respond_to do |format|
      format.html { redirect_to transaction_reprocesses_url, notice: 'Transaction reprocess was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction_reprocess
      @transaction_reprocess = TransactionReprocess.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_reprocess_params
      params.require(:transaction_reprocess).permit(:old_trnx_id, :new_trnx_id, :amount, :status, :auto, :err_code, :user_id, :nw_resp)
    end
end
