class TransMastersController < ApplicationController
  before_action :set_trans_master, only: [:show, :edit, :update, :destroy]

  # GET /trans_masters
  # GET /trans_masters.json
  def index
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @trans_masters = TransMaster.all
  end

  # GET /trans_masters/1
  # GET /trans_masters/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  # GET /trans_masters/new
  def new
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @trans_master = TransMaster.new
  end

  # GET /trans_masters/1/edit
  def edit
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
  end

  # POST /trans_masters
  # POST /trans_masters.json
  def create
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @trans_master = TransMaster.new(trans_master_params)

    respond_to do |format|
      if @trans_master.save
        format.html { redirect_to @trans_master, notice: 'Trans master was successfully created.' }
        format.json { render :show, status: :created, location: @trans_master }
      else
        format.html { render :new }
        format.json { render json: @trans_master.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trans_masters/1
  # PATCH/PUT /trans_masters/1.json
  def update
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @trans_master.update(trans_master_params)
        format.html { redirect_to @trans_master, notice: 'Trans master was successfully updated.' }
        format.json { render :show, status: :ok, location: @trans_master }
      else
        format.html { render :edit }
        format.json { render json: @trans_master.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trans_masters/1
  # DELETE /trans_masters/1.json
  def destroy
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @trans_master.destroy
    respond_to do |format|
      format.html { redirect_to trans_masters_url, notice: 'Trans master was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trans_master
      @trans_master = TransMaster.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trans_master_params
      params.require(:trans_master).permit(:main_trans_id, :final_status, :is_reversal)
    end
end
