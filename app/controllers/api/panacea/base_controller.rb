class Api::Panacea::BaseController <  ActionController::Base
before_filter :check_login

 def check_login
 	 unless user_signed_in?
  	 render :status => 401,
           :json => { :success => false,
                      :info => "Login Failed"}
  	 return
  end		
 end	

end
