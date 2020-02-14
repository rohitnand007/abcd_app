class SingleSignOnController < ApplicationController

  skip_before_filter :authenticate_user!

  def sso_callback
  sso_provider = SsoProvider.first
  @response = sso_provider.authenticate(sso_callback_url,params[:code], "260960f2e96438e9a4df6b3d44cd092e")
  session_state = params[:session_state]
  logger.info "======#{@response}"
  if @response[:status]
    profile = JWT.decode(@response[:id_token], nil, false)
    username = profile['unique_name']
    if User.find_by_email(username).nil?
      @teacher = Teacher.new
      @teacher.password="edutor"
      @teacher.email= profile['unique_name']
      @teacher.is_activated = true
      @teacher.institution_id = 130120
      @teacher.center_id = 130122
      @teacher.academic_class_id = 130124
      @teacher.section_id = 130125
      @teacher.is_group = false
      @teacher.is_class_teacher = true
      @teacher.role_id = 5
      @teacher.save
      first_name = profile['given_name']
      last_name = profile['family_name']
      @teacher.create_profile(:firstname=>first_name,:surname=>last_name)
    end
    cookies['_auth_name'] = Base64.encode64 username
    cookies['_auth_ses']= ApplicationController::CLIENT_ID+ 'XXX' + session_state
    #flash[:error] = code
    respond_to do |format|
      format.html { redirect_to root_path}
    end
   else
     redirect_to root_url
  end

  end


end
