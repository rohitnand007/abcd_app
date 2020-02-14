class ApplicationController < ActionController::Base

  include ExceptionLogger::ExceptionLoggable # loades the module
  #rescue_from Exception, :with => :log_exception_handler

  require 'zip/zip'
  require 'find'
  require "nokogiri"
  require 'fileutils'
  require 'devise'
  require 'archive/zip'
  #protect_from_forgery :false
  # tells rails to forward the 'Exception' (you can change the type) to the handler of the module

  #before_filter :log_request
  #after_filter :log_response
  skip_before_filter :verify_authenticity_token , :if => Proc.new { |c| c.request.content_type == 'application/json' }
  skip_before_filter :authenticate_user!, :only=>:get_control_messages
  #skip_before_filter :authenticate_user! , :if => Proc.new { |c| c.request.content_type == 'application/json' }
  before_filter :authenticate_device_user, :if => Proc.new { |c| c.request.content_type == 'application/json' and c.request.headers['device_id'] != nil }
  before_filter :authenticate_user! , :if => Proc.new { |c| c.request.content_type != 'application/json' }

  before_filter :new_authenticate_user!, :if => :check_cookie
  skip_before_filter :authenticate_user!, :if => :check_cookie


  #authorize_resource
  #check_authorization
  #before_filter :set_layout
  helper_method :current_ea, :current_ia, :current_cr,:current_es,:current_est,:current_ep,:current_ecp,:current_et

  @device_response_request_id
  @device_request_success = 1
  ################## --- OAuth2 Constants our AD################
  CLIENT_ID = '6c3b94f7-143e-4f76-8f28-8ab23ac8b9df'
  CLIENT_SECRET = 'xQZrxosn2nBPoFFumfuT4jcFHY/Oh9qvBSK1y7BUmis='
  AUTH_URL = 'https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/authorize?api-version=1.0'
  TOKEN_URL = 'https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/token?api-version=1.0'
  REDIRECT_URI = 'http://portal.myedutor.com/oauth/callback' #'http://localhost:3000/oauth/callback' #
  REDIRECT_URI1 = 'ms-app://s-1-15-2-2791738866-3922307851-1264757808-434632867-696511962-600388262-4054474961/'
  RESOURCE = 'https://api.office.com/discovery/' #'https://ignitorlearning1.onmicrosoft.com/Portal-Local1'
  ##LOGIN_URI = "https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/authorize?api-version=1.0&client_id=6c3b94f7-143e-4f76-8f28-8ab23ac8b9df&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Foauth%2Fcallback&response_type=code"
  #LOGIN_URI = "https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/authorize?api-version=1.0&client_id=6c3b94f7-143e-4f76-8f28-8ab23ac8b9df&redirect_uri=http%3A%2F%2Fportal.myedutor.com%2Foauth%2Fcallback&response_type=code"
  LOGIN_URI = " https://login.microsoftonline.com/common/oauth2/authorize?prompt=consent&client_id=6c3b94f7-143e-4f76-8f28-8ab23ac8b9df&nonce=260960f2e96438e9a4df6b3d44cd092e&redirect_uri=http%3A%2F%2Fportal.myedutor.com%2Fsso%2Fcallback&response_type=code&scope=openid&state=260960f2e96438e9a4df6b3d44cd092e"
  CHECK_SESSION_IFRAME = "https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/checksession"
  END_SESSION_ENDPOINT = "https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/logout"
  TARGET_ORIGIN  = "https://login.microsoftonline.com"
  ########################################################

  ################# --- OAuth2 Constants ################
  #CLIENT_ID = '3b34ad11-dadc-4b54-9b5c-443a274a8e7c'
  #CLIENT_SECRET = 'PTZYnnHrNak5I5kCiOtuwFB80EBjeD3M4wtp9FbdLZ0='
  #AUTH_URL = 'https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/authorize?api-version=1.0'
  #TOKEN_URL = 'https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/token?api-version=1.0'
  #REDIRECT_URI = 'http://portal.myedutor.com/oauth/callback'
  #RESOURCE = 'http://chirec.ac.in/IgnitorLearning1'
  #LOGIN_URI = "https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/authorize?api-version=1.0&client_id=3b34ad11-dadc-4b54-9b5c-443a274a8e7c&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Foauth%2Fcallback&response_type=code"
  #LOGIN_URI = "https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/authorize?api-version=1.0&client_id=3b34ad11-dadc-4b54-9b5c-443a274a8e7c&redirect_uri=http%3A%2F%2Fportal.myedutor.com%2Foauth%2Fcallback&response_type=code"
  #CHECK_SESSION_IFRAME = "https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/checksession"
  #END_SESSION_ENDPOINT = "https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/logout"
  #TARGET_ORIGIN  = "https://login.microsoftonline.com"
  #######################################################

  #layout 'global'
  layout :set_layout

  #Logging queue start time
  #before_filter :queue_start
  def queue_start
    $HTTP_X_QUEUE_START = nil
    begin
      $HTTP_X_QUEUE_START =  request.headers["HTTP_X_REQUEST_START"] if request.headers["HTTP_X_REQUEST_START"]
    end rescue nil
  end
  #Logging exceptions
=begin
  if Log4r::Logger['rails'].exception?
    rescue_from Exception do |ex|
      ActiveSupport::Notifications.instrument "exception.action_controller", message: ex.message, inspect: ex.inspect, backtrace: ex.backtrace
      raise ex
    end
  end
=end
  # The code for handling the cancan permission denied error
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to :back, :alert => "Page your are accessing doesn't exist"
  end

  #To do
  #Defin the layout by user agent type. seperate layout for Teacher tab login
  def set_layout
    #agent = request.env['HTTP_USER_AGENT']#request.user_agent #request.env['HTTP_USER_AGENT']
    #if agent.match("Android")
    #if agent.match("Android")
    #  false
    #TOdo change the institution_id to 25607
    unless  params[:format].eql?'json'
      if !current_user.institution_id.nil? and [25607, 51324].include? current_user.institution_id
        'pearson_new'
      elsif !current_user.institution_id.nil? and [26717, 57296].include? current_user.institution_id
        'schand'
      # elsif !current_user.institution_id.nil? and [44566].include? current_user.institution_id
      #   'abcd_top_menu'
      else
        'new'#'abcd_top_menu'
      end
    else
      false
    end
    # unless  params[:format].eql?'json'
    #   if !current_user.institution_id.nil? and [25607, 51324].include? current_user.institution_id
    #     'pearson_new'
    #   elsif !current_user.institution_id.nil? and [26717, 57296].include? current_user.institution_id
    #     'schand'
    #   elsif !current_user.institution_id.nil? and [1020].include? current_user.institution_id
    #     'abcd_top_menu'
    #   else
    #     'new'
    #   end
    # else
    #   false
    # end
  end


  #TODO  2.0 login considering only the Edutorid
  def authenticate_device_user
    logger.info "=====#{request.headers["authorization"]}==="
    #logger.info "=====#{request.headers['content-type']}==="
    logger.info "=deviceid====#{request.headers['device_id']}==="
    begin
      users = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    rescue
      users = []
    end
    logger.info"=====================user_login_info===#{users}"
    unless users.empty? and user_signed_in?
      resource = User.find_by_edutorid(users[0])
      #resource = warden.authenticate!(users)
      unless resource.nil?
        sign_in('user',resource)
      end
      #current_user = resource
    end
  end

  def new_authenticate_user!
    puts cookies['_auth_name']
    email = Base64.decode64 cookies['_auth_name']
    current_u = User.where(:email => email).first
    if current_u
      @cur = true
      sign_in('user', current_u)
    else
      cookies.delete '_auth_name'
      cookies.delete '_auth_ses'
      respond_to do |format|
        format.html {render text: 'your account is not configured, please logout at http://account.activedirectory.windowsazure.com'}
      end
    end
  end

  def check_cookie
    if !cookies['_auth_name'].nil?
      true
    else
      false
    end
  end
  # rescue_from Exception do |exception|
  #  logger.info "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXCEPTION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  # flash[:error] = "Something went wrong! Please try later or contact support team."
  #logger.info "Exception Caught=========== #{exception.backtrace.join('\n')}"
  #redirect_to root_url
  #end

  ['EA','IA','CR','ES','ET','EP','ECP','EST'].each do |k|
    define_method "current_#{k.underscore}" do
      current_user if current_user.is? k.to_sym
    end
  end

  #before_filter :students_in_center
  # Eduotor Admin can do
  def must_be_admin
    if current_user.is? "EA"
      return true
    else
      redirect_to root_path,:notice =>"Access Denied..."
    end
  end

  def students_in_center
    if !current_user.nil?
      if current_user.is?('CR') or current_user.is?('CA')
        @students_count = User.where('center_id =? and edutorid like ?',current_user.center_id,"ES-%").count
      end
    end
  end

  def convert_milli_to_datetime(milliseconds)
    Time.at(milliseconds.to_i).to_datetime
  end

  # used for center and academic_class to get related tied courses of institution=>center=>academic_class
  def get_boards
    @courses = []
    if request.xhr? and params[:q].present?
      @boards = if  params[:institution_id].present?
                  #@boards = Institution.find(params[:institution_id]).publishers.map{|pub| pub.boards.where('name like ?',"%#{params[:q]}%").select('id,name')}.flatten.uniq
                  Institution.find(params[:institution_id]).try(:boards).select('id,name').where('name like ?',"%#{params[:q]}%")
                elsif  params[:center_id].present?
                  Center.find(params[:center_id]).try(:boards).select('id,name').where('name like ?',"%#{params[:q]}%")
                elsif params[:academic_class_id].present?
                  AcademicClass.find(params[:academic_class_id]).try(:boards).select('id,name').where('name like ?',"%#{params[:q]}%")
                end
      respond_to do |format|
        format.json { render json: @boards }
      end
    elsif request.xhr? and !params[:q].present? #used in teacher_class_rooms fields partial
      @boards = Center.find(params[:center_id]).try(:boards).select('id,name')
      respond_to do |format|
        format.json { render json: @boards.map{|b| Hash[value: b.id ,name: b.name]} }
      end
    end


  end

  def get_publishers
    if request.xhr?
      like= "%".concat(params[:q].concat("%"))
      publishers = Profile.includes(:user).where('users.id'=>Publisher.all).where("surname like ? or firstname like ?",like,like)
    end
    list = publishers.empty? ? [] : publishers.map {|u| Hash[id: u.user_id, label: u.firstname, name: u.firstname]}
    render json: list
  end

  def get_subjects
    @subjects = []
    if request.xhr?
      @subjects = Subject.select('id,name').where('name like ?',"%#{params[:q]}%")
    end
    respond_to do |format|
      format.json { render json: @subjects }
    end
  end


  def get_control_messages

    #params[:edutor_id] = 'ET-00017'
    #params[:device_id] = 'testdevice'
    #params[:password] = 'ffdd'
    #--------------
    # @ctrl_messages = {}
    # #@ctrl_messages['success'] = false
    # @ctrl_messages['error'] = ''
    # if params[:format] !='json'
    #   respond_to do |format|
    #     format.json { render json: @ctrl_messages,:layout=>false }
    #   end
    #   return
    # end

    #if(params[:edutor_id].nil? && (params[:device_id].nil?))
    #  @ctrl_messages['error'] = 'Invalid request'
    #  respond_to do |format|
    #    format.json { render json: @ctrl_messages,:layout=>false }
    #  end
    #  return
    #end
    #
    #if(params[:password].nil?)
    #  @ctrl_messages['error'] = 'Invalid request'
    #  respond_to do |format|
    #    format.json { render json: @ctrl_messages,:layout=>false }
    #  end
    #  return
    #end

    # time = 0
    # if params[:time]
    #   time  = params[:time].to_i
    #   #time = 1341583589
    # end
    #if(!params[:edutor_id].nil? && !params[:edutor_id].empty?)
    #  hash = Digest::MD5.hexdigest(params[:edutor_id]+Edutor::Application.config.device_id_hash_salt)
    #  if(hash !=params[:password])
    #    @ctrl_messages['error'] = 'Authorization failed'
    #    respond_to do |format|
    #      format.json { render json: @ctrl_messages,:layout=>false }
    #    end
    #    return
    #  end
    #  @user = User.where(:edutorid=>params[:edutor_id]).first
    #  if @user
    #    @ctrl_messages['success'] = true
    #    if !@user.groups.empty?
    #      group_ids = @user.groups.map(&:id)
    #      @messages = Message.includes(:assets).where("updated_at > ? AND message_type = ? AND (recipient_id =? OR group_id IN (?))",time,'Control Message',@user.id,group_ids).group("message_id").order("id DESC")
    #      #logger.debug(@messages.to_sql)
    #    else
    #      @messages = Message.includes(:assets).where("recipient_id=? AND updated_at > ? AND message_type = ?",@user,time,'Control Message').group("message_id").order("id DESC")
    #    end
    #    @ctrl_messages['messages'] = @messages.as_json(:include=>:assets)
    #  else
    #    @ctrl_messages['error'] = 'User does not exist'
    #  end
    #else
    #  hash = Digest::MD5.hexdigest(params[:device_id]+Edutor::Application.config.device_id_hash_salt)
    #  if(hash !=params[:password])
    #    @ctrl_messages['error'] = 'Authorization failed'
    #    respond_to do |format|
    #      format.json { render json: @ctrl_messages,:layout=>false }
    #    end
    #    return
    #  end
    #  device = Device.where(:deviceid=>params[:device_id]).first
    #  if device
    #    @ctrl_messages['success'] = true
    #    user_device = UserDevice.where(:device_id=>device.id)
    #    user_ids = user_device.map(&:user_id)
    #    group_ids = []
    #    user_device.each do |u|
    #      @user = User.find(u.user_id)
    #      if !@user.groups.empty?
    #        group_ids = group_ids+@user.groups.map(&:id)
    #      end
    #    end
    #    if group_ids && user_ids
    #      @messages = Message.includes(:assets).where("(recipient_id IN (?) OR group_id IN (?))and updated_at > ? and message_type = ?",user_ids,group_ids,time,'Control Message').group("message_id").order("id DESC")
    #    elsif group_ids && !user_ids
    #      @messages = Message.includes(:assets).where("group_id IN (?) and updated_at > ? and message_type = ?",group_ids,time,'Control Message').group("message_id").order("id DESC")
    #    elsif !group_ids && user_ids
    #      @messages = Message.includes(:assets).where("recipient_id IN (?) and updated_at > ? and message_type = ?",user_ids,time,'Control Message').group("message_id").order("id DESC")
    #    end
    #    @messages.flatten!
    #    @ctrl_messages['messages'] = @messages.as_json(:include=>:assets)
    #  else
    #    @ctrl_messages['error'] = 'Device does not exist'
    #  end

    #Taking the only deviceid  parameter
    # if params[:device_id].nil? or params[:device_id] == ''
    #   @ctrl_messages['error'] = 'Device id is empty'
    #   respond_to do |format|
    #     format.json { render json: @ctrl_messages,:layout=>false }
    #   end
    #   return
    # end
    # device = Device.where(:deviceid=>params[:device_id]).first
    # if device
    #   @users = device.users
    #   user_ids = @users.map(&:id)
    #   group_ids = []
    #   @users.each do |u|
    #     # @user = User.find(u)
    #     if !u.groups.empty?
    #       group_ids = group_ids+u.groups.map(&:id)
    #     end
    #   end
    #   #  teacher_group_ids = User.joins(:profile).where(:is_group=>true).where("firstname like ?","%teacher%").map(&:id)
    #   #  teacher_group_exist = group_ids & teacher_group_ids
    #   #if teacher_group_exist.empty?
    #   if group_ids && user_ids
    #     @messages = DeviceMessage.includes(:assets).where("(recipient_id IN (?) OR group_id IN (?) OR deviceid =?)and updated_at > ? and message_type = ?",user_ids,group_ids,device.deviceid,time,'Control Message').order("id DESC")
    #   elsif group_ids && !user_ids
    #     @messages = DeviceMessage.includes(:assets).where("(group_id IN (?) OR deviceid =? ) and updated_at > ? and message_type = ?",group_ids,device.deviceid,time,'Control Message').order("id DESC")
    #   elsif !group_ids && user_ids
    #     @messages = DeviceMessage.includes(:assets).where("(recipient_id IN (?) OR deviceid =? )and updated_at > ? and message_type = ?",user_ids,device.deviceid,time,'Control Message').order("id DESC")
    #   else
    #     @messages = DeviceMessage.includes(:assets).where("deviceid =? and updated_at > ? and message_type = ?",device.deviceid,time,'Control Message').order("id DESC")
    #   end
    #   @messages.flatten!
    #   @ctrl_messages['messages'] = @messages.as_json(:include=>:assets)
    #   #end
    # else
    #   @ctrl_messages['error'] = 'Device does not exist'
    # end
    @ctrl_messages = {}

    respond_to do |format|
      format.json { render json: @ctrl_messages,:layout=>false }
    end
  end

  #Generic method for generating the zip for a given url and the name
  def create_zip(name,url)
    @outputFile = (Rails.root.to_s+"/tmp/cache/downloads/"+name+".zip")
    if File.exist?(@outputFile)
      FileUtils.rm_rf (@outputFile)
    end
    @inputDir = url
    entries = Dir.entries(@inputDir)
    entries.delete(".")
    entries.delete("..")
    io = Zip::ZipFile.open(@outputFile, Zip::ZipFile::CREATE)
    writeEntries(entries, "", io) #calling recursive write entries method
    io.close();
    return @outputFile
  end
  #recursive write entries method for creating folder structure for zip
  def writeEntries(entries, path, io)
    entries.each { |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(@inputDir, zipFilePath)
      puts "==Deflating==" + diskFilePath
      if File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir = Dir.entries(diskFilePath)
        subdir.delete(".")
        subdir.delete("..")
        writeEntries(subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
      end
    }
  end

  def get_server_time
    @messages = {}
    @messages['success'] = true
    if params[:format] =='json'
      @messages['time'] = Time.now.to_i*1000
      respond_to do |format|
        format.json { render json: @messages,:layout=>false }
      end
      return
    end
  end

  def get_time
    time = Time.now.strftime("%Y%m%d.%H%M%S")
    time = 'date -s '+time.to_s
    respond_to do |format|
      format.html { render text:time ,:layout=>false }
    end
    return
  end


  def log_request
    begin
      if params[:format] =='json'
        device_request = DeviceRequest.new
        if !params[:user][:edutor_id].nil?
          device_request.edutor_id = params[:user][:edutor_id]
        end
        if !params[:user][:edutorid].nil?
          device_request.edutor_id = params[:user][:edutorid]
        end
        if !params[:user][:device_id].nil?
          device_request.device_id = params[:user][:device_id]
        end
        if !params[:user][:deviceid].nil?
          device_request.device_id = params[:user][:deviceid]
        end
        if !request.session_options[:id].nil?
          device_request.session_id = request.session_options[:id]
        end
        if logged_in?
          device_request.edutor_id = User.find(current_user.id).edutorid
        end
        #if (@device_request_success == 1)
        device_request.success = @device_request_success
        #end
        device_request.url = request.url
        device_request.request_type = request.method
        device_request.ip = request.remote_ip
        device_request.data = YAML::dump(params)
        device_request.save
        @device_response_request_id =  device_request.id
      end
    rescue
    ensure
    end
  end

  def log_response
    begin
      if params[:format] =='json'
        device_response = DeviceResponse.new
        if !params[:user][:edutor_id].nil?
          device_response.edutor_id = params[:user][:edutor_id]
        end
        if !params[:user][:edutorid].nil?
          device_response.edutor_id = params[:user][:edutorid]
        end
        if !params[:user][:device_id].nil?
          device_response.device_id = params[:user][:device_id]
        end
        if !params[:user][:deviceid].nil?
          device_response.device_id = params[:user][:deviceid]
        end
        if !request.session_options[:id].nil?
          device_response.session_id = request.session_options[:id]
        end
        if logged_in?
          device_response.edutor_id = User.find(current_user.id).edutorid
        end
        device_response.request_type = response.content_type
        device_response.data = YAML::dump(response.body)
        device_response.request_id = @device_response_request_id
        device_response.save
      end
    rescue
    ensure
    end
  end
  #generic method for generating ncx for home work and assessments
  def generate_ncx(content,path)
    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum", :class=>"curriculum"){
          xml.content(:src=>"curriculum")

          # TODO: Currently if Publishing the Assessment as Home Work then storing "Home Work" in the extras
          # The code for generating the NCX for the Assessments of type Practice Test, Insti Test or Quiz
          if  content.type.eql?"Assessment" and (content.extras.nil? or !content.extras.index("homework")) and (content.assessment_type.eql?"practice-tests" or content.assessment_type.eql?"insti-tests" or content.assessment_type.eql?"quiz" or content.assessment_type.eql?"olympiad" or content.assessment_type.eql?"iit" or content.assessment_type.eql?"inclass")
            xml.navPoint(:id=>"Assessment",:class=>"assessment"){
              xml.content(:src=>"assessments")
              xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
                xml.content(:src=>content.subject.board.code+"_"+content.asset.publisher_id.to_s)
                xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                  xml.content(:src=>content.subject.content_year.code)
                  xml.navPoint(:id=>content.assessment_type,:class=>"assessment-category"){
                    xml.content(:src=>"practice")

                    # The code for handling the data if the subject has a subject as a parent
                    if !content.subject.subject_id.nil?
                      xml.navPoint(:id=>content.subject.parent_subject.name,:class=>"subject")
                      xml.content(:src=>content.subject.parent_subject.code)
                    end
                    # End of code for handling the data if the subject has a subject as a parent

                    xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                      xml.content(:src=>content.subject.code)
                      if !content.subject_id.nil? and content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                        xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name,  :class=>"assessment-"+content.assessment_type, :passwd=>content.passwd ){
                          xml.content(:src=>content_url(content))
                        }
                      end
                      if !content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                        xml.navPoint(:id=>content.chapter.name, :class=>"chapter"){
                          xml.content(:src=>content.chapter.assets.first.src)
                          xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type ,:passwd=>content.passwd){
                            xml.content(:src=>content_url(content))
                          }
                        }
                      end
                      if !content.topic_id.nil?  and !content.chapter_id.nil? and content.sub_topic_id.nil?
                        xml.navPoint(:id=>content.topic.chapter.name, :class=>"chapter"){
                          xml.content(:src=>content.topic.chapter.assets.first.src)
                          xml.navPoint(:id=>content.topic.name, :class=>"topic"){
                            xml.content(:src=>content.topic.assets.first.src)
                            xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type,:passwd=>content.passwd){
                              xml.content(:src=>content_url(content))
                            }
                          }
                        }
                      end
                      if !content.sub_topic_id.nil? and !content.chapter_id.nil? and !content.topic_id.nil?
                        xml.navPoint(:id=>content.sub_topic.chapter.name, :class=>"chapter"){
                          xml.content(:src=>content.sub_topic.chapter.assets.first.src)
                          xml.navPoint(:id=>content.sub_topic.topic.name, :class=>"topic"){
                            xml.content(:src=>content.sub_topic.topic.assets.first.src)
                            xml.navPoint(:id=>content.sub_topic.name, :class=>"subtopic"){
                              xml.content(:src=>content.sub_topic.assets.first.src)
                              xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type,:passwd=>content.passwd){
                                xml.content(:src=>content_url(content))
                              }
                            }
                          }
                        }
                      end
                    }
                  }
                }
              }
            }

            # The code for generating the NCX for publishing Assessment Practice Test, Insti Test or Quiz as Home Work
          elsif content.type.eql?"Assessment" and (!content.extras.nil? and content.extras.index("homework")) and (content.assessment_type.eql?"practice-tests" or content.assessment_type.eql?"insti-tests" or content.assessment_type.eql?"Quiz")

            # Generating the Content Node
            xml.navPoint(:id=>"Content",:class=>"content"){
              xml.content(:src=>"content")
              xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
                xml.content(:src=>content.subject.board.code+"_"+content.asset.publisher_id.to_s, :params=>content.subject.board.params)
                xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                  xml.content(:src=>content.subject.content_year.code,:params=>content.subject.content_year.params)

                  # The code for handling the data if the subject has a subject as a parent
                  if !content.subject.subject_id.nil?
                    xml.navPoint(:id=>content.subject.parent_subject.name,:class=>"subject")
                    xml.content(:src=>content.subject.parent_subject.code)
                  end
                  # End of code for handling the data if the subject has a subject as a parent

                  xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                    xml.content(:src=>content.subject.code, :params=>content.subject.params)
                    time =  content.test_configurations.first.end_time.to_i*1000 rescue nil
                    # Handling the case if chapter, topic and sub topic are NULL
                    if !content.subject_id.nil? and content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                      xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type,:container_type => content.extras,:submitTime=>time,:passwd=>content.passwd){
                        if File.extname(content.asset.attachment_file_name) == ".zip"
                          Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                            if File.extname(d) =='.etx'
                              @name  = d
                              break
                            end
                          end
                          xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.subject.params)
                        else
                          xml.content(:src=>content_url(content), :params=>content.subject.params)
                        end
                      }
                    end

                    # Handling the case if topic and sub topic are NULL
                    if !content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                      xml.navPoint(:id=>content.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.chapter.assets.first.src, :params=>content.chapter.params)
                        xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type, :container_type => content.extras, :playOrder=>content.chapter.play_order,:submitTime=>time,:passwd=>content.passwd){
                          if File.extname(content.asset.attachment_file_name) == ".zip"
                            Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                              if File.extname(d) =='.etx'
                                @name  = d
                                break
                              end
                            end
                            xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.chapter.params)
                          else
                            xml.content(:src=>content_url(content), :params=>content.chapter.params)
                          end
                        }
                      }

                    end

                    # Handling the case if sub topic is NULL
                    if !content.topic_id.nil?  and !content.chapter_id.nil? and content.sub_topic_id.nil?
                      xml.navPoint(:id=>content.topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.topic.chapter.assets.first.src, :params=>content.chapter.params)
                        xml.navPoint(:id=>content.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type, :container_type => content.extras, :playOrder=>content.topic.play_order,:submitTime=>time,:passwd=>content.passwd){
                            if File.extname(content.asset.attachment_file_name) == ".zip"
                              Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                if File.extname(d) =='.etx'
                                  @name  = d
                                  break
                                end
                              end
                              xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.topic.params)
                            else
                              xml.content(:src=>content_url(content), :params=>content.topic.params)
                            end
                          }
                        }
                      }

                    end

                    # Handling the case if all are present
                    if !content.sub_topic_id.nil? and !content.chapter_id.nil? and !content.topic_id.nil?
                      xml.navPoint(:id=>content.sub_topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.sub_topic.chapter.assets.first.src, :params=>content.chapter.params)
                        xml.navPoint(:id=>content.sub_topic.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.sub_topic.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.sub_topic.name, :class=>"subtopic", :playOrder=>content.sub_topic.play_order){
                            xml.content(:src=>content.sub_topic.assets.first.src, :params=>content.sub_topic.params)
                            xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type, :container_type => content.extras, :playOrder=>content.sub_topic.play_order,:submitTime=>time,:passwd=>content.passwd){
                              if File.extname(content.asset.attachment_file_name) == ".zip"
                                Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                  if File.extname(d) =='.etx'
                                    @name  = d
                                    break
                                  end
                                end
                                xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.sub_topic.params)
                              else
                                xml.content(:src=>content_url(content), :params=>content.sub_topic.params)
                              end
                            }


                          }
                        }
                      }
                    end
                  }
                }
              }
            }

            # Generating the Homework Node
            xml.navPoint(:id=>"HomeWork",:class=>"home-work"){
              xml.content(:src=>"homework")
              xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
                xml.content(:src=>content.subject.board.code+"_"+content.asset.publisher_id.to_s, :params=>content.subject.board.params)
                xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                  xml.content(:src=>content.subject.content_year.code, :params=>content.subject.content_year.params)

                  # The code for handling the data if the subject has a subject as a parent
                  if !content.subject.subject_id.nil?
                    xml.navPoint(:id=>content.subject.parent_subject.name,:class=>"subject")
                    xml.content(:src=>content.subject.parent_subject.code, :params=>content.subject.parent_subject.params)
                  end
                  # End of code for handling the data if the subject has a subject as a parent

                  xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                    xml.content(:src=>content.subject.code,:params=>content.subject.params)
                    time =  content.test_configurations.first.end_time.to_i*1000 rescue nil

                    # Handling the case if chapter, topic and sub topic are NULL
                    if !content.subject_id.nil? and content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                      xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type, :prerequiste=>content.subject.uri,:submitTime=>time,:passwd=>content.passwd){
                        if File.extname(content.asset.attachment_file_name) == ".zip"
                          Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                            if File.extname(d) =='.etx'
                              @name  = d
                              break
                            end
                          end
                          xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.subject.params)
                        else
                          xml.content(:src=>content_url(content), :params=>content.subject.params)
                        end
                      }
                    end

                    # Handling the case if topic and sub topic are NULL
                    if !content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                      xml.navPoint(:id=>content.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.chapter.assets.first.src,:params=>content.chapter.params)
                        xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type, :prerequiste=>content.chapter.uri,:playOrder=>content.chapter.play_order,:submitTime=>time,:passwd=>content.passwd){
                          if File.extname(content.asset.attachment_file_name) == ".zip"
                            Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                              if File.extname(d) =='.etx'
                                @name  = d
                                break
                              end
                            end
                            xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.chapter.params)
                          else
                            xml.content(:src=>content_url(content), :params=>content.chapter.params)
                          end
                        }
                      }
                    end

                    # Handling the case if sub topic is NULL
                    if !content.topic_id.nil?  and !content.chapter_id.nil? and content.sub_topic_id.nil?
                      xml.navPoint(:id=>content.topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.topic.chapter.assets.first.src,:params=>content.chapter.params)
                        xml.navPoint(:id=>content.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type, :prerequiste=>content.topic.uri, :playOrder=>content.topic.play_order,:submitTime=>time,:passwd=>content.passwd){
                            if File.extname(content.asset.attachment_file_name) == ".zip"
                              Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                if File.extname(d) =='.etx'
                                  @name  = d
                                  break
                                end
                              end
                              xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.topic.params)
                            else
                              xml.content(:src=>content_url(content), :params=>content.topic.params)
                            end
                          }
                        }
                      }
                    end

                    # Handling the case if all are present
                    if !content.sub_topic_id.nil? and !content.chapter_id.nil? and !content.topic_id.nil?
                      xml.navPoint(:id=>content.sub_topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.sub_topic.chapter.assets.first.src,:params=>content.chapter.params)
                        xml.navPoint(:id=>content.sub_topic.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.sub_topic.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.sub_topic.name, :class=>"subtopic", :playOrder=>content.sub_topic.play_order){
                            xml.content(:src=>content.sub_topic.assets.first.src, :params=>content.sub_topic.params)
                            xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>"assessment-"+content.assessment_type, :prerequiste=>content.sub_topic.uri, :playOrder=>content.sub_topic.play_order,:submitTime=>time,:passwd=>content.passwd){
                              if File.extname(content.asset.attachment_file_name) == ".zip"
                                Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                  if File.extname(d) =='.etx'
                                    @name  = d
                                    break
                                  end
                                end
                                xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.sub_topic.params)
                              else
                                xml.content(:src=>content_url(content), :params=>content.sub_topic.params)
                              end
                            }
                          }
                        }
                      }
                    end


                  }
                }
              }
            }

            # End of code for generating the NCX for publishing Assessment Practice Test, Insti Test or Quiz as Home Work

          elsif content.type.eql?("AssessmentHomeWork") or (content.type.eql?"Assessment" and content.assessment_type.eql?"home-work")
            xml.navPoint(:id=>"HomeWork",:class=>"home-work"){
              xml.content(:src=>"homework")
              xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
                xml.content(:src=>content.subject.board.code+"_"+content.asset.publisher_id.to_s)
                xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                  xml.content(:src=>content.subject.content_year.code)

                  # The code for handling the data if the subject has a subject as a parent
                  if !content.subject.subject_id.nil?
                    xml.navPoint(:id=>content.subject.parent_subject.name,:class=>"subject")
                    xml.content(:src=>content.subject.parent_subject.code)
                  end
                  # End of code for handling the data if the subject has a subject as a parent

                  xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                    xml.content(:src=>content.subject.code)
                    #if !content.subject_id.nil? and content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                    time = (content.type.eql?("AssessmentHomeWork")? content.content_profile.expiry_date.to_i*1000 : content.test_configurations.first.end_time.to_i*1000) rescue nil
                    xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>((File.extname(content.asset.attachment_file_name) == ".zip"  or content.assessment_type == "home-work" ) ? "assessment-practice-tests" :"assessment-home-work") ,:submitTime=>time){
                      if File.extname(content.asset.attachment_file_name) == ".zip"
                        Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                          if File.extname(d) =='.etx'
                            @name  = d
                            break
                          end
                        end
                        xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name)
                      else
                        xml.content(:src=>content_url(content))
                      end
                    }
                    #end
                    #if !content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                    #  xml.navPoint(:id=>content.chapter.name, :class=>"chapter"){
                    #    xml.content(:src=>content.chapter.assets.first.src)
                    #    xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"assessment-home-work"){
                    #      if File.extname(content.asset.attachment_file_name) == ".zip"
                    #        Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                    #          if File.extname(d) =='.etx'
                    #            @name  = d
                    #            break
                    #          end
                    #        end
                    #        xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name)
                    #      else
                    #        xml.content(:src=>content.asset.src)
                    #      end
                    #    }
                    #  }
                    #end
                    #if !content.topic_id.nil?  and !content.chapter_id.nil? and content.sub_topic_id.nil?
                    #  xml.navPoint(:id=>content.topic.chapter.name, :class=>"chapter"){
                    #    xml.content(:src=>content.topic.chapter.assets.first.src)
                    #    xml.navPoint(:id=>content.topic.name, :class=>"topic"){
                    #      xml.content(:src=>content.topic.assets.first.src)
                    #      xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"assessment-home-work"){
                    #        if File.extname(content.asset.attachment_file_name) == ".zip"
                    #          Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                    #            if File.extname(d) =='.etx'
                    #              @name  = d
                    #              break
                    #            end
                    #          end
                    #          xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name)
                    #        else
                    #          xml.content(:src=>content.asset.src)
                    #        end
                    #      }
                    #    }
                    #  }
                    #end
                    #if !content.sub_topic_id.nil? and !content.chapter_id.nil? and !content.topic_id.nil?
                    #  xml.navPoint(:id=>content.sub_topic.chapter.name, :class=>"chapter"){
                    #    xml.content(:src=>content.sub_topic.chapter.assets.first.src)
                    #    xml.navPoint(:id=>content.sub_topic.topic.name, :class=>"topic"){
                    #      xml.content(:src=>content.sub_topic.topic.assets.first.src)
                    #      xml.navPoint(:id=>content.sub_topic.name, :class=>"subtopic"){
                    #        xml.content(:src=>content.sub_topic.assets.first.src)
                    #        xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"assessment-home-work"){
                    #          if File.extname(content.asset.attachment_file_name) == ".zip"
                    #            Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                    #              if File.extname(d) =='.etx'
                    #                @name  = d
                    #                break
                    #              end
                    #            end
                    #            xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name)
                    #          else
                    #            xml.content(:src=>content.asset.src)
                    #          end
                    #        }
                    #
                    #
                    #      }
                    #    }
                    #  }
                    #end
                  }
                }
              }
            }
          else
            xml.navPoint(:id=>"Content",:class=>"content"){
              xml.content(:src=>"content")
              xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
                xml.content(:src=>content.subject.board.code+"_"+content.assets.first.publisher_id.to_s)
                xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                  xml.content(:src=>content.subject.content_year.code)

                  # The code for handling the data if the subject has a subject as a parent
                  if !content.subject.subject_id.nil?
                    xml.navPoint(:id=>content.subject.parent_subject.name,:class=>"subject")
                    xml.content(:src=>content.subject.parent_subject.code)
                  end
                  # End of code for handling the data if the subject has a subject as a parent

                  xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                    xml.content(:src=>content.subject.code)
                    case content.type when "Chapter"
                                        xml.navPoint(:id=>content.name,:class=>"chapter",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                                          xml.content(:src=>content.assets.first.src)
                                        }
                      when "Topic"
                        xml.navPoint(:id=>content.chapter.name,:class=>"chapter",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                          xml.content(:src=>content.chapter.assets.first.src,:params=>content.chapter.params)
                          xml.navPoint(:id=>content.name, :class=>"topic",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                            xml.content(:src=>content.assets.first.src)
                          }
                        }
                      when "SubTopic"
                        xml.navPoint(:id=>content.chapter.name,:class=>"chapter",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                          xml.content(:src=>content.chapter.assets.first.src,:params=>content.chapter.params)
                          xml.navPoint(:id=>content.topic.name, :class=>"topic",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                            xml.content(:src=>content.topic.assets.first.src,:params=>content.chapter.params)
                            xml.navPoint(:id=>content.name, :class=>"subtopic",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                              xml.content(:src=>content.assets.first.src)
                            }
                          }
                        }
                    end
                  }
                }
              }
            }
          end
        }
      }
    end
    xml_string =  @builder.to_xml.to_s
    file = File.new(path+"/"+"index.ncx", "w+")
    File.open(file,'w') do |f|
      f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
    end
    create_zip("assessment_#{content.id}",path)
  end

  #Updating the last node src with the .etx for assessment contents
  def content_url(content)
    url =  content.asset.src
    etx_extensions = ['.doc','.docx','.txt','.xls','.xlsx']
    if etx_extensions.include?File.extname(content.asset.attachment_file_name)
      url =  url.gsub(File.extname(content.asset.attachment_file_name),".etx")
    end
    url
  end



  def initialize_forum_session
    require "js_connect"
    client_id = "117727935"
    secret = "b8c1014a1fda11f54d50339d481ec0cb"
    user = {}

    if current_user
      eduser = User.find(current_user.id)
      if eduser
        eduser_profile = Profile.where('user_id'=>eduser.id).first
        if eduser_profile
          user["uniqueid"] = eduser.id.to_s
          user["name"] = eduser.edutorid
          user["email"] = eduser.email
          user["firstname"] = eduser_profile.firstname
          user["lastname"] = eduser_profile.surname
          user["photourl"] = ""
        end
      end
    end
    secure = true
    json = JsConnect.getJsConnectString(user, params, client_id, secret, secure)

    respond_to do |format|
      format.json { render json: json,:layout=>false }
    end
  end

  #handing the exception,activerecord errors and controllers with rescue_form
  unless Rails.application.config.consider_all_requests_local
    rescue_from AbstractController::ActionNotFound, :with => :render_not_found
    rescue_from ActionController::RoutingError, :with => :render_not_found
    rescue_from ActionController::UnknownController, :with => :render_not_found
    rescue_from ActionController::UnknownAction, :with => :render_not_found
    rescue_from Exception, :with => :render_error
    rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
    rescue_from CanCan::AccessDenied do |exception|
      flash[:error] = "You are not authorized to access the page."
      redirect_to :back
    end
  end
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "You are not authorized to access the page."
    puts "Access denied on #{exception.action} #{exception.subject.inspect} "
    logger.info "Access denied on #{exception.action} #{exception.subject.inspect} "
    redirect_to root_path, notice: "You are not authorized to access the page."
  end

  #private

  #Hadling error for exception
  def render_error exception

    logger.info"==========error 500========="
    #Rails.logger.error(exception)
    #render :template => "/errors/500.html.erb", :status => 500
    logger.info "#{'-'*100} #{request.format} #{'-'*100}"
    @error = exception
    ActiveSupport::Notifications.instrument "exception.action_controller", message: @error.message, inspect: @error.inspect, backtrace: @error.backtrace
    respond_to do |format|
      format.html { render template: "errors/error_500", status: 500, layout:false }
      format.all { render nothing: true, status: 500}

    end
    log_exception_handler(exception)
  end
  # Handling error for not found and active record errors
  def render_not_found exception

    #logger.info"==========error 404========="
    #Rails.logger.error(exception)
    #render :template => "/errors/404.html.erb", :status => 404
    @not_found_path = exception.message
    respond_to do |format|
      format.html { render template: 'errors/error_404',  status: 404, layout:false }
      format.all { render nothing: true, status: 404 }
    end
    log_exception_handler(exception)
  end

  def log_error(error_message,request_type,sent_data,edutor_id='',device_id='')
    @log = ErrorLog.new
    @log.error_message = error_message
    @log.request_type = request_type
    @log.sent_data = sent_data
    @log.edutor_id = edutor_id
    @log.device_id = device_id
    @log.save
  end

  # This is the method for the generation of the content NCX using content paths table
  # TODO: Have to add params and other values if required
  def generate_content_ncx(content,path)
    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      class_types_map = {"Subject" => "course", "ContentYear" => "academic-class", "Subject" => "subject", "Chapter" => "chapter", "Topic" => "topic", "SubTopic" => "subtopic"}
      xml.navMap do
        xml.navPoint(:id=>"Curriculum", :class=>"curriculum") do
          xml.content(:src=>"curriculum")
          xml.navPoint(:id=>"Content",:class=>"content")do
            xml.content(:src=>"content")

            ## The code for generating the inside xml string
            content_xml_string = ''
            parents = content.parents.reverse
            ## Generating the content node
            parents.each do |parent|
              content_data = Content.find(parent["ancestor"])
              ## Getting the class for the current node
              node_class = class_types_map[content_data.type]
              ## Getting the src for the current node
              node_src = ''
              if content_data.type == 'Board'
                node_src = content_data.code+'_'+content.assets.first.publisher_id.to_s
              elsif content_data.type == 'ContentYear' or content_data.type == 'Subject'
                node_src = content_data.code
              else
                node_src = content.assets.first.src
              end
              # Reset the nav node and the content node
              nav_node = ''
              content_node = ''

              # Generating the nav node
              nav_node = nav_node+"<navPoint id='#{content_data.name}' class='#{node_class}' >"

              # Generating the content node
              content_node = content_node+"<content src='#{node_src}' />"

              ## Appending the nav node and the content node to the main xml
              content_xml_string = content_xml_string+nav_node+content_node
            end
            ## Appending the navpoint end tags to the string
            parents.length.times do
              content_xml_string = content_xml_string + "</navPoint>"
            end

            ## End  of code for generating the xml string
            xml.__send__ :insert, Nokogiri::XML::DocumentFragment.parse(content_xml_string)
          end
        end
      end
    end
    xml_string =  @builder.to_xml.to_s
    file = File.new(path+"/"+"index.ncx", "w+")
    File.open(file,'w') do |f|
      f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
    end
    create_zip("content_#{content.id}",path)
  end


  def record_errors(errors)
    file = File.new(Rails.root.to_s+"/public/record_error.txt", "a+")
    File.open(file,  "a", 0644) do |f|
      f.puts(errors.inspect.to_s)
      f.puts("===================#{Date.today}======================")
    end
  end



  def record_users(note)
    file = File.new(Rails.root.to_s+"/public/record_note.txt", "a+")
    File.open(file,  "a", 0644) do |f|
      f.puts(note)
      f.puts("===================#{Date.today}======================")
    end
  end
end
