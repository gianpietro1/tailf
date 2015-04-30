class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from RestClient::BadRequest do 
    flash[:error] = "Bad Request, please check that parameters are valid for your device / network."
    render :show
  end

end
