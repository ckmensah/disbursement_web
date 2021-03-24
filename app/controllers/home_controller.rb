class HomeController < ApplicationController
  def index
    if current_user.ultra? || current_user.s_user?
      @user_app = PremiumClient.active.where(user_id: current_user.id)[0]
    elsif current_user.is_client
      @user_app = PremiumClient.active.where(client_code: current_user.client_code).order('updated_at DESC').first


        if @user_app.needs_approval

        elsif !@user_app.needs_approval
          respond_to do |format|
          format.html {redirect_to :controller => 'transactions', :action => 'index'}
          format.json {render json: {status: true}}
        end
      end
    end
  end
end
