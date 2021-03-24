class ApproversCategoriesController < ApplicationController
  before_action :set_approvers_category, only: [:show, :edit, :update, :destroy]

  # GET /approvers_categories
  # GET /approvers_categories.json
  def index
    # @approvers_categories = ApproversCategory.all

    if current_user.ultra? || current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
      @approvers_categories = ApproversCategory.active.order('approvers_categories.created_at desc')
    elsif current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
      # users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
      @approvers_categories = ApproversCategory.active.where(client_code: current_user.client_code).order('approvers_categories.created_at desc')
    else
      @approvers_categories = []
    end



    if current_user.ultra? || current_user.s_user?
      @approvers = Approver.active.order('approvers.created_at desc')
    elsif current_user.is_client
      users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
      @approvers = Approver.active.where(user_approver_id: users_ids).order('approvers.created_at desc')
    else
      @approvers = []
    end
    respond_to do |format|
      if @user_app.needs_approval
        format.html
        format.csv {send_data @approvers.to_csv(current_user.client_code, @page, @per_page)}
        format.xls {send_data @approvers.to_csv(current_user.client_code, @page, @per_page, the_search, options = {col_sep: "\t"})}
      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # GET /approvers_categories/1
  # GET /approvers_categories/1.json
  def show
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    respond_to do |format|
      if @user_app.needs_approval
        format.html
        format.csv {send_data @approvers.to_csv(current_user.client_code, @page, @per_page)}
        format.xls {send_data @approvers.to_csv(current_user.client_code, @page, @per_page, the_search, options = {col_sep: "\t"})}
      elsif !@user_app.needs_approval
        format.html {redirect_to :controller => 'transactions', :action => 'index'}
        format.json {render json: {status: true}}
      end
    end
  end

  # GET /approvers_categories/new
  def new
    @approvers_category = ApproversCategory.new

    if current_user.s_user?
      @clients = PremiumClient.active
    else
      if current_user.is_client
        @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
      else
        @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      end
      @clients = PremiumClient.active.where(client_code: current_user.client_code).active
    end

    logger.info "########################################################"
    logger.info "The client collection::::: #{@clients.inspect}"
    logger.info "########################################################"
    respond_to do |format|


      if params[:source]
        format.js {render :new}
      else
        format.js {render :tab_new}
      end
    end
    # respond_to do |format|
    #   if @user_app.needs_approval
    #     format.html
    #     # format.csv {send_data @approvers.to_csv(current_user.client_code, @page, @per_page)}
    #     # format.xls {send_data @approvers.to_csv(current_user.client_code, @page, @per_page, the_search, options = {col_sep: "\t"})}
    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end

  end

  # GET /approvers_categories/1/edit
  def edit
    if current_user.ultra? || current_user.s_user?
      @clients = PremiumClient.active
    else
      if current_user.is_client
        @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
      else
        @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
      end
      @clients = PremiumClient.active.where(client_code: current_user.client_code).active
    end
    # respond_to do |format|
    #   if @user_app.needs_approval

    #   elsif !@user_app.needs_approval
    #     format.html {redirect_to :controller => 'transactions', :action => 'index'}
    #     format.json {render json: {status: true}}
    #   end
    # end
  end

  # POST /approvers_categories
  # POST /approvers_categories.json
  def create

    # @approvers_categories = ApproversCategory.all
    if current_user.s_user?
      @approvers_categories = ApproversCategory.active
    elsif current_user.is_client
      # users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
      @approvers_categories = ApproversCategory.active.where(client_code: current_user.client_code)
    else
      @approvers_categories = []
    end

    if current_user.ultra? || current_user.s_user?
      @approvers = Approver.active
    elsif current_user.is_client
      users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
      @approvers = Approver.active.where(user_approver_id: users_ids)
    else
      @approvers = []
    end

    @approvers_category = ApproversCategory.new(approvers_category_params)

    respond_to do |format|
      if @approvers_category.save
        format.html { redirect_to request.referer, notice: 'Approvers category was successfully created.' }
        format.json { render :show, status: :created, location: @approvers_category }
        format.js { render :index, notice: 'Approvers category was successfully created.'}
      else
        if current_user.ultra? || current_user.s_user?
          @clients = PremiumClient.active
        else
          @clients = PremiumClient.where(client_code: current_user.client_code).active
        end

        format.html { render :new }
        format.json { render json: @approvers_category.errors, status: :unprocessable_entity }
        format.js {render :new}
      end
    end
  end

  # PATCH/PUT /approvers_categories/1
  # PATCH/PUT /approvers_categories/1.json
  def update

    if current_user.ultra? || current_user.s_user?
      @approvers_categories = ApproversCategory.active.order('created_at desc')
    elsif current_user.is_client
      # users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
      @approvers_categories = ApproversCategory.where(client_code: current_user.client_code).order('created_at desc')
    else
      @approvers_categories = []
    end


    if current_user.ultra? || current_user.s_user?
      @approvers = Approver.active.order('created_at desc')
    elsif current_user.is_client
      users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
      @approvers = Approver.active.where(user_approver_id: users_ids).order('created_at desc')
    else
      @approvers = []
    end

    respond_to do |format|
      if @approvers_category.update(approvers_category_params)
        format.html { redirect_to @approvers_category, notice: 'Approvers category was successfully updated.' }
        format.json { render :show, status: :ok, location: @approvers_category }
        format.js {render :index}
      else
        if current_user.ultra?
          @clients = PremiumClient.active
        else
          @clients = PremiumClient.where(client_code: current_user.client_code).active
        end

        format.html { render :edit }
        format.json { render json: @approvers_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /approvers_categories/1
  # DELETE /approvers_categories/1.json
  def destroy
    if current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
    else
      @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
    end
    @approvers_category.destroy
    respond_to do |format|
      format.html { redirect_to approvers_categories_url, notice: 'Approvers category was successfully destroyed.' }
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
  def set_approvers_category
    @approvers_category = ApproversCategory.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def approvers_category_params
    params.require(:approvers_category).permit(:category_name, :client_code, :leveled, :user_id, :status, :changed_status)
  end
end









# class ApproversCategoriesController < ApplicationController
#   before_action :set_approvers_category, only: [:show, :edit, :update, :destroy]
#
#   # GET /approvers_categories
#   # GET /approvers_categories.json
#   def index
#     # @approvers_categories = ApproversCategory.all
#
#     if current_user.ultra? || current_user.s_user?
#       @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
#       @approvers_categories = ApproversCategory.active.order('approvers_categories.created_at desc')
#     elsif current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first
#       # users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
#       @approvers_categories = ApproversCategory.active.where(client_code: current_user.client_code).order('approvers_categories.created_at desc')
#     else
#       @approvers_categories = []
#     end
#
#
#
#     if current_user.ultra? || current_user.s_user?
#       @approvers = Approver.active.order('approvers.created_at desc')
#     elsif current_user.is_client
#       users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
#       @approvers = Approver.active.where(user_approver_id: users_ids).order('approvers.created_at desc')
#     else
#       @approvers = []
#     end
#     logger.info " this is the need_approval_status #{@user_app.inspect}"
#
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#         format.js { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#   # GET /approvers_categories/1
#   # GET /approvers_categories/1.json
#   def show
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     respond_to do |format|
#       if @user_app.needs_approval
#         format.html { }
#         format.json { }
#         format.js { }
#       elsif !@user_app.needs_approval
#         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#         format.json {render json: {status: true}}
#       end
#     end
#   end
#
#
#   def new
#     @approvers_category = ApproversCategory.new
#
#     if current_user.s_user? || current_user.ultra?
#       @clients = PremiumClient.active
#     else
#       if current_user.is_client
#         @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#       else
#         @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#       end
#       @clients = PremiumClient.active.where(client_code: current_user.client_code)
#     end
#
#     logger.info "########################################################"
#     logger.info "The client collection::::: #{@clients.inspect}"
#     logger.info "########################################################"
#     # respond_to do |format|
#     #   if params[:source]
#     #     format.js {render :new}
#     #   else
#     #     format.js {render :tab_new}
#     #   end
#     # end
#     respond_to do |format|
#       logger.info "I entered RESPOND TO block ============================================"
#       if @user_app != nil
#         logger.info " this is the need_approval_status #{@user_app.inspect} ########!@#$%^&*!@#$%^&*()!@#$%^&*()########"
#         if @user_app.needs_approval
#           format.html { }
#           format.json { }
#           if params[:source]
#             format.js {render :new}
#             else
#             format.js {render :tab_new}
#           end
#         elsif !@user_app.needs_approval
#           format.html {redirect_to :controller => 'transactions', :action => 'index'}
#           format.json {render json: {status: true}}
#         end
#       else
#         if params[:source]
#           format.js {render :new}
#         else
#           format.js {render :tab_new}
#         end
#       end
#     end
#
#   end
#
#   # GET /approvers_categories/1/edit
#   def edit
#     if current_user.ultra? || current_user.s_user?
#       @clients = PremiumClient.active
#     else
#       if current_user.is_client
#         @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#       else
#         @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#       end
#       @clients = PremiumClient.active.where(client_code: current_user.client_code)
#     end
#     respond_to do |format|
#       if @user_app
#         if @user_app.needs_approval
#           format.html { }
#           format.json { }
#           format.js { }
#         elsif !@user_app.needs_approval
#           format.html {redirect_to :controller => 'transactions', :action => 'index'}
#           format.json {render json: {status: true}}
#         end
#       else
#         format.html { }
#         format.json { }
#         format.js { }
#       end
#     end
#   end
#
#   # def new
#   #   @approvers_category = ApproversCategory.new
#   #
#   #   if current_user.s_user?
#   #     @clients = PremiumClient.active
#   #   else
#   #     if current_user.is_client
#   #       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#   #     else
#   #       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#   #     end
#   #     @clients = PremiumClient.active.where(client_code: current_user.client_code).active
#   #   end
#   #
#   #   logger.info "########################################################"
#   #   logger.info "The client collection::::: #{@clients.inspect}"
#   #   logger.info "########################################################"
#   #   respond_to do |format|
#   #
#   #
#   #     if params[:source]
#   #       format.js {render :new}
#   #     else
#   #       format.js {render :tab_new}
#   #     end
#   #   end
#   #   respond_to do |format|
#   #     if @user_app
#   #       if @user_app.needs_approval
#   #         format.html { } #redirect_to :controller => '/', :notice => '' }
#   #         format.json { }#render json: {status: true}}
#   #         format.js { }
#   #
#   #       elsif !@user_app.needs_approval
#   #         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#   #         format.json {render json: {status: true}}
#   #       end
#   #     else
#   #       format.html {redirect_to :controller => 'transactions', :action => 'index'}
#   #       format.json {render json: {status: true}}
#   #     end
#   #   end
#   #
#   # end
#   #
#   # # GET /approvers_categories/1/edit
#   # def edit
#   #   if current_user.ultra? || current_user.s_user?
#   #     @clients = PremiumClient.active
#   #   else
#   #     if current_user.is_client
#   #       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#   #     else
#   #       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#   #     end
#   #     @clients = PremiumClient.active.where(client_code: current_user.client_code).active
#   #   end
#   #   respond_to do |format|
#   #     if @user_app
#   #       if @user_app.needs_approval
#   #         format.html { }
#   #         format.json { }
#   #         format.js { }
#   #       elsif !@user_app.needs_approval
#   #         format.html {redirect_to :controller => 'transactions', :action => 'index'}
#   #         format.json {render json: {status: true}}
#   #       end
#   #     else
#   #       format.html {redirect_to :controller => 'transactions', :action => 'index'}
#   #       format.json {render json: {status: true}}
#   #     end
#   #   end
#   # end
#
#   # GET /approvers_categories/new
#   # def new
#   #   @approvers_category = ApproversCategory.new
#   #
#   #   if current_user.s_user?
#   #     @clients = PremiumClient.active
#   #   else
#   #     if current_user.is_client
#   #       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#   #     else
#   #       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#   #     end
#   #     @clients = PremiumClient.active.where(client_code: current_user.client_code).active
#   #   end
#   #
#   #   logger.info "########################################################"
#   #   logger.info "The client collection::::: #{@clients.inspect}"
#   #   logger.info "########################################################"
#   #   respond_to do |format|
#   #
#   #
#   #     if params[:source]
#   #       format.js {render :new}
#   #     else
#   #       format.js {render :tab_new}
#   #     end
#   #   end
#   #   respond_to do |format|
#   #     if @user_app.needs_approval
#   #       format.html { } #redirect_to :controller => '/', :notice => '' }
#   #       format.json { }#render json: {status: true}}
#   #       format.js { }
#   #
#   #     elsif !@user_app.needs_approval
#   #       format.html {redirect_to :controller => 'transactions', :action => 'index'}
#   #       format.json {render json: {status: true}}
#   #     end
#   #   end
#   #
#   # end
#   #
#   # # GET /approvers_categories/1/edit
#   # def edit
#   #   if current_user.ultra? || current_user.s_user?
#   #     @clients = PremiumClient.active
#   #   else
#   #     if current_user.is_client
#   #       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#   #     else
#   #       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#   #     end
#   #     @clients = PremiumClient.active.where(client_code: current_user.client_code).active
#   #   end
#   #   respond_to do |format|
#   #     if @user_app.needs_approval
#   #       format.html { }
#   #       format.json { }
#   #       format.js { }
#   #     elsif !@user_app.needs_approval
#   #       format.html {redirect_to :controller => 'transactions', :action => 'index'}
#   #       format.json {render json: {status: true}}
#   #     end
#   #   end
#   # end
#
#   # POST /approvers_categories
#   # POST /approvers_categories.json
#   def create
#
#     # @approvers_categories = ApproversCategory.all
#     if current_user.s_user? || current_user.ultra?
#       @approvers_categories = ApproversCategory.active
#     elsif current_user.is_client
#       # users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
#       @approvers_categories = ApproversCategory.active.where(client_code: current_user.client_code)
#     else
#       @approvers_categories = []
#     end
#
#     if current_user.ultra? || current_user.s_user?
#       @approvers = Approver.active
#     elsif current_user.is_client
#       users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
#       @approvers = Approver.active.where(user_approver_id: users_ids)
#     else
#       @approvers = []
#     end
#
#     @approvers_category = ApproversCategory.new(approvers_category_params)
#
#     respond_to do |format|
#       if @approvers_category.save
#         format.html { redirect_to request.referer, notice: 'Approvers category was successfully created.' }
#         format.json { render :show, status: :created, location: @approvers_category }
#         format.js { render :index, notice: 'Approvers category was successfully created.'}
#       else
#         if current_user.ultra? || current_user.s_user?
#           @clients = PremiumClient.active
#         else
#           @clients = PremiumClient.where(client_code: current_user.client_code).active
#         end
#
#         format.html { render :new }
#         format.json { render json: @approvers_category.errors, status: :unprocessable_entity }
#         format.js {render :new}
#       end
#     end
#   end
#
#   # PATCH/PUT /approvers_categories/1
#   # PATCH/PUT /approvers_categories/1.json
#   def update
#
#     if current_user.ultra? || current_user.s_user?
#       @approvers_categories = ApproversCategory.active.order('created_at desc')
#     elsif current_user.is_client
#       # users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
#       @approvers_categories = ApproversCategory.where(client_code: current_user.client_code).order('created_at desc')
#     else
#       @approvers_categories = []
#     end
#
#
#     if current_user.ultra? || current_user.s_user?
#       @approvers = Approver.active.order('created_at desc')
#     elsif current_user.is_client
#       users_ids = User.where(client_code: current_user.client_code).map{|user| user.id}
#       @approvers = Approver.active.where(user_approver_id: users_ids).order('created_at desc')
#     else
#       @approvers = []
#     end
#
#     respond_to do |format|
#       if @approvers_category.update(approvers_category_params)
#         format.html { redirect_to @approvers_category, notice: 'Approvers category was successfully updated.' }
#         format.json { render :show, status: :ok, location: @approvers_category }
#         format.js {render :index}
#       else
#         if current_user.ultra? || current_user.s_user?
#           @clients = PremiumClient.active
#         else
#           @clients = PremiumClient.where(client_code: current_user.client_code).active
#         end
#
#         format.html { render :edit }
#         format.json { render json: @approvers_category.errors, status: :unprocessable_entity }
#       end
#     end
#   end
#
#   # DELETE /approvers_categories/1
#   # DELETE /approvers_categories/1.json
#   def destroy
#     if current_user.is_client
#       @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC')[0]
#     else
#       @user_app = PremiumClient.active.where(user_id: current_user.id).order('updated_at DESC')[0]
#     end
#     @approvers_category.destroy
#     respond_to do |format|
#       format.html { redirect_to approvers_categories_url, notice: 'Approvers category was successfully destroyed.' }
#       format.json { head :no_content }
#     end
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
#     # Use callbacks to share common setup or constraints between actions.
#     def set_approvers_category
#       @approvers_category = ApproversCategory.find(params[:id])
#     end
#
#     # Never trust parameters from the scary internet, only allow the white list through.
#     def approvers_category_params
#       params.require(:approvers_category).permit(:category_name, :client_code, :leveled, :user_id, :status, :changed_status)
#     end
# end
