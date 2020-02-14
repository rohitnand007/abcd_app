class Api::Nslate::BaseController < ActionController::Base
  respond_to :json
  before_filter :authenticate_user_from_token!

  def authenticate_user_from_token!
    if !params['key']
      render nothing: true, status: :unauthorized
    else
      @api_user = nil
      @api_user = User.where(:authentication_token => params[:key]).first
      if @api_user.nil?
        render nothing: true, status: :unauthorized
      end
    end
  end

end