class Api::Panacea::DeviceSessionsController < Devise::SessionsController

 skip_before_filter :verify_authenticity_token,
                      :if => Proc.new { |c| c.request.format == 'application/json' }
 before_filter :check_login

  respond_to :json

   def create
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    render :status => 200,
           :json => { :success => true,
                      :info => "Logged in",
                      :data => { :auth_token => current_user.authentication_token } }
  end

  def destroy
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    current_user.update_column(:authentication_token, nil)
    render :status => 200,
           :json => { :success => true,
                      :info => "Logged out",
                      :data => {} }
  end

  def failure
    render :status => 401,
           :json => { :success => false,
                      :info => "Login Failed",
                      :data => {} }
  end

  def view_user
    request.headers["authorization"]
     @data = params["data"]
     logger.info "===#{@data}"
  	 render :status => 200,
           :json => { :success => true,
                      :info => current_user.edutorid,
                      :data => {} }
  end	

def check_login
    unless user_signed_in?
  	 render :status => 401,
           :json => { :success => false,
                      :info => "Login Failed"}
  	return
  end	
end	


end
