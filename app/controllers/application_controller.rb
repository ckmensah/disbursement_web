class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_action :authenticate_user!
  require 'csv'
  protect_from_forgery with: :null_session
  #protect_from_forgery with: :exception



  rescue_from CanCan::AccessDenied do |exception|
    redirect_to '/'#request.referer
    flash[:alert] = "Sorry, you're not authorized to perform this function!"
  end

end
