class ApproversController < ApplicationController
  before_action :set_approver, only: [:show, :edit, :update, :destroy]

  # GET /approvers
  # GET /approvers.json
  def index
    if current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
      @approvers = Approver.active
    elsif current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
      users_ids = User.where(client_code: current_user.client_code).map {|user| user.id}
      @approvers = Approver.active.where(user_approver_id: users_ids)
    else
      @approvers = []
    end
    # respond_to do |format|
    #   if @user_app.needs_approval

    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end
  end

  # GET /approvers/1
  # GET /approvers/1.json
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

  # GET /approvers/new
  def new
    logger.info "THIS IS THE REFERER: #{request.referer}"
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @approver = Approver.new
    if current_user.s_user?
      @approvers = User.where("client_code IS NOT NULL")
      @categories = ApproversCategory.all
    else
      @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
      @categories = ApproversCategory.where(client_code: current_user.client_code)
    end
    # respond_to do |format|
    #   if @user_app.needs_approval

    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end
  end

  # GET /approvers/1/edit
  def edit
    if current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      @approvers = User.where("client_code IS NOT NULL")
      @categories = ApproversCategory.all
    else
      if current_user.is_client
        @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
      else
        @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      end
      @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
      @categories = ApproversCategory.where(client_code: current_user.client_code)
    end

    # respond_to do |format|
    #   if @user_app.needs_approval

    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end
  end

  # POST /approvers
  # POST /approvers.json
  def create
    @approver = Approver.new(approver_params)
    @approver.approver_code = Approver.generate_approver_code

    ##########################################################

    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    if current_user.ultra? || current_user.s_user?
      @approvers = Approver.active
    elsif current_user.is_client
      users_ids = User.where(client_code: current_user.client_code).map {|user| user.id}
      @approvers = Approver.active.where(user_approver_id: users_ids)
    else
      @approvers = []
    end

    respond_to do |format|
      if @approver.save
        format.html {redirect_to approvers_path, notice: 'Approver was successfully created.'}
        format.js {render :index, notice: 'Approver was successfully created.'}
        format.json {render :show, status: :created, location: @approver}
      else
        if current_user.ultra?
          @approvers = User.where("client_code IS NOT NULL")
          @categories = ApproversCategory.all
        else

          @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
          @categories = ApproversCategory.where(client_code: current_user.client_code)
        end

        format.html {render :new}
        format.js {render :new}
        format.json {render json: @approver.errors, status: :unprocessable_entity}
      end
    end

    # respond_to do |format|
    #   if @user_app.needs_approval

    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end
  end

  # PATCH/PUT /approvers/1
  # PATCH/PUT /approvers/1.json
  def update


    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end

    if current_user.ultra?
      @approvers = Approver.active
    elsif current_user.is_client
      users_ids = User.where(client_code: current_user.client_code).map {|user| user.id}
      @approvers = Approver.active.where(user_approver_id: users_ids)
    else
      @approvers = []
    end

    respond_to do |format|
      @approver_fail = Approver.new(approver_params)

      @new_approver = Approver.new(@approver.attributes)
      @new_approver.category_id = approver_params[:category_id] unless approver_params[:category_id].blank?
      @new_approver.level = approver_params[:level] unless approver_params[:level].blank?
      #user_approver_id
      @new_approver.user_approver_id = approver_params[:user_approver_id] unless approver_params[:user_approver_id].blank?
      @new_approver.user_id = current_user.id
      @new_approver.updated_at = Time.now


      if @new_approver.save
        update_last_but_one('approvers', 'approver_code', @new_approver.approver_code)

        format.html {redirect_to approvers_path, notice: 'Approver was successfully updated.'}
        format.json {render :show, status: :ok, location: @approver}
        format.js {render :index}
      else
        @approver_fail.save

        if current_user.ultra?
          @approvers = User.where("client_code IS NOT NULL")
          @categories = ApproversCategory.all
        else

          @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
          @categories = ApproversCategory.where(client_code: current_user.client_code)
        end

        format.html {render :edit}
        format.json {render json: @approver.errors, status: :unprocessable_entity}
      end
    end

    # respond_to do |format|
    #   if @user_app.needs_approval

    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end
  end

  # DELETE /approvers/1
  # DELETE /approvers/1.json
  def destroy
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @approver.destroy
    respond_to do |format|
      format.html {redirect_to approvers_url, notice: 'Approver was successfully destroyed.'}
      format.json {head :no_content}
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
  def set_approver
    @approver = Approver.where(approver_code: params[:id], status: true, changed_status: false).order('id desc')[0]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def approver_params
    params.require(:approver).permit(:user_approver_id, :user_id, :category_id, :status, :changed_status, :approver_code)
  end

  def update_last_but_one(table, id_field, id)
    sql = "UPDATE #{table} SET changed_status = true WHERE id = (SELECT id FROM #{table} WHERE #{id_field} = '#{id}' AND status = true AND changed_status = false ORDER BY id ASC LIMIT 1)"
    val = ActiveRecord::Base.connection.execute(sql)
    #logger "VALUE: #{val.inspect}"
  end
end

















# class ApproversController < ApplicationController
#   before_action :set_approver, only: [:show, :edit, :update, :destroy]
#
#   # GET /approvers
#   # GET /approvers.json
#   def index
#     if current_user.s_user?
#       @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
#       @approvers = Approver.active
#     elsif current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
#       users_ids = User.where(client_code: current_user.client_code).map {|user| user.id}
#       @approvers = Approver.active.where(user_approver_id: users_ids)
#     else
#       @approvers = []
#     end
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   # GET /approvers/1
#   # GET /approvers/1.json
#   def show
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   # GET /approvers/new
#   def new
#     logger.info "THIS IS THE REFERER: #{request.referer}"
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @approver = Approver.new
#     if current_user.s_user?
#       @approvers = User.where("client_code IS NOT NULL")
#       @categories = ApproversCategory.all
#     else
#       @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
#       @categories = ApproversCategory.where(client_code: current_user.client_code)
#     end
#
#     respond_to do |format|
#       format.js {render :new}
#     end
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   # GET /approvers/1/edit
#   def edit
#     if current_user.s_user?
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#       @approvers = User.where("client_code IS NOT NULL")
#       @categories = ApproversCategory.all
#     else
#       if current_user.is_client
#         @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#       else
#         @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#       end
#       @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
#       @categories = ApproversCategory.where(client_code: current_user.client_code)
#     end
#
#     respond_to do |format|
#       format.js {render :edit}
#     end
#
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   # POST /approvers
#   # POST /approvers.json
#   def create
#     @approver = Approver.new(approver_params)
#     @approver.approver_code = Approver.generate_approver_code
#
#     ##########################################################
#
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     if current_user.ultra? || current_user.s_user?
#       @approvers = Approver.active
#     elsif current_user.is_client
#       users_ids = User.where(client_code: current_user.client_code).map {|user| user.id}
#       @approvers = Approver.active.where(user_approver_id: users_ids)
#     else
#       @approvers = []
#     end
#
#     respond_to do |format|
#       if @approver.save
#         format.html {redirect_to approvers_path, notice: 'Approver was successfully created.'}
#         format.js {render :index, notice: 'Approver was successfully created.'}
#         format.json {render :show, status: :created, location: @approver}
#       else
#         if current_user.ultra?
#           @approvers = User.where("client_code IS NOT NULL")
#           @categories = ApproversCategory.all
#         else
#
#           @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
#           @categories = ApproversCategory.where(client_code: current_user.client_code)
#         end
#
#         format.html {render :new}
#         format.js {render :new}
#         format.json {render json: @approver.errors, status: :unprocessable_entity}
#       end
#     end
#
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   # PATCH/PUT /approvers/1
#   # PATCH/PUT /approvers/1.json
#   def update
#
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#
#     if current_user.ultra?
#       @approvers = Approver.active
#     elsif current_user.is_client
#       users_ids = User.where(client_code: current_user.client_code).map {|user| user.id}
#       @approvers = Approver.active.where(user_approver_id: users_ids)
#     else
#       @approvers = []
#     end
#
#     respond_to do |format|
#       @approver_fail = Approver.new(approver_params)
#
#       @new_approver = Approver.new(@approver.attributes)
#       @new_approver.category_id = approver_params[:category_id] unless approver_params[:category_id].blank?
#       @new_approver.level = approver_params[:level] unless approver_params[:level].blank?
#       #user_approver_id
#       @new_approver.user_approver_id = approver_params[:user_approver_id] unless approver_params[:user_approver_id].blank?
#       @new_approver.user_id = current_user.id
#       @new_approver.updated_at = Time.now
#
#
#       if @new_approver.save
#         update_last_but_one('approvers', 'approver_code', @new_approver.approver_code)
#
#         format.html {redirect_to approvers_path, notice: 'Approver was successfully updated.'}
#         format.json {render :show, status: :ok, location: @approver}
#         format.js {render :index}
#       else
#         @approver_fail.save
#
#         if current_user.ultra?
#           @approvers = User.where("client_code IS NOT NULL")
#           @categories = ApproversCategory.all
#         else
#
#           @approvers = User.where(client_code: current_user.client_code, role_id: 6) #approvers clients
#           @categories = ApproversCategory.where(client_code: current_user.client_code)
#         end
#
#         format.html {render :edit}
#         format.json {render json: @approver.errors, status: :unprocessable_entity}
#       end
#     end
#
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   # DELETE /approvers/1
#   # DELETE /approvers/1.json
#   def destroy
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @approver.destroy
#     respond_to do |format|
#       format.html {redirect_to approvers_url, notice: 'Approver was successfully destroyed.'}
#       format.json {head :no_content}
#     end
#
#     respond_to do |format|
#       if @user_app.needs_approval
#
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   private
#
#   # Use callbacks to share common setup or constraints between actions.
#   def set_approver
#     @approver = Approver.where(approver_code: params[:id], status: true, changed_status: false).order('id desc')[0]
#   end
#
#   # Never trust parameters from the scary internet, only allow the white list through.
#   def approver_params
#     params.require(:approver).permit(:user_approver_id, :user_id, :category_id, :status, :changed_status, :approver_code)
#   end
#
#   def update_last_but_one(table, id_field, id)
#     sql = "UPDATE #{table} SET changed_status = true WHERE id = (SELECT id FROM #{table} WHERE #{id_field} = '#{id}' AND status = true AND changed_status = false ORDER BY id ASC LIMIT 1)"
#     val = ActiveRecord::Base.connection.execute(sql)
#     #logger "VALUE: #{val.inspect}"
#   end
# end
