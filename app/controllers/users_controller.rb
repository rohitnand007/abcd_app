class UsersController < ApplicationController
  authorize_resource :except => [:create_user_by_device_id, :tab_reset_password, :user_change_password, :user_forgot_password, :send_user_password, :user_login, :authenticate_password]
  before_filter :students_in_center,:except=>[:create_user_by_device_id,:update_activation_status,:tab_reset_password,:obs_user_registration]
  skip_before_filter :authenticate_user!, :only=>[:create_user_by_device_id,:tab_reset_password,:obs_user_registration,:user_tab_sessions,:user_forgot_password,:send_user_password,:user_login,:get_signup_status]
  # GET /users
  # GET /users.json
  def index
    @users = get_users

    respond_to do |format|
      format.js
      format.html # index.html.erb
      format.json { render json: @users }
    end

  end


  def get_users
    case current_user.rc
      when 'EA'
        #User.includes(:profile).where('is_group = ? and  type IS ? and id !=?',false,nil,current_user.id).page(params[:page])
        User.students.search_includes.search_select.page(params[:page])
      when 'IA','EO'
        current_user.students.search_includes.search_select.page(params[:page])
      when 'CR'
        #current_user.users.where('is_group = ? and type IS ? and id!= ?',false,nil,current_user.id).page(params[:page])
        current_user.students.search_includes.search_select.page(params[:page])
      when 'ET'
        #current_user.users.where('is_group = ? and type IS ? and id!= ?',false,nil,current_user.id).page(params[:page])
        current_user.students.search_includes.search_select.page(params[:page])
    end rescue []
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    authorize! :show, @user
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user.as_json(:include => :profile) }
      format.pdf do
        render :pdf => "#{@user.name}",

               :header => {:html => { :template => 'users/header.html.haml',
                                      :url      => 'www.edutor.com'
               }},
               :footer => {:html => { :template => 'users/footer.html.haml',
                                      :url      => 'www.edutor.com',
                                      :center => "Center",
                                      :left => "Left",
                                      :right => "Right"
               }}
      end
    end

  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = Student.new
    #@user.build_user_group
    @user.user_groups.build
    @user.build_profile
    @user.devices.build
    @center = current_user.center if current_user.center
    @institution = current_user.institution if current_user.institution
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = Student.includes(:institution,:center,:academic_class,:section,:user_groups).find(params[:id])
    @user.devices.build if @user.devices.empty?
    authorize! :edit, @user
  end

  # POST /users
  # POST /users.json
  def create
    params[:user] = params[:student]
    user_groups_token_ids
    @user = Student.new(params[:user])
    @user.plain_password = params[:user][:password]
    respond_to do |format|
      if @user.save
        @user.update_type
        @user.update_email
        format.html { redirect_to user_path(@user), notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    # User update form the tablet is disabled.
    params[:user] = params[:student]
    if params[:format] =='json'
      respond_to do |format|
        format.json { head :ok }
      end
      return
    end
    @user = Student.find(params[:id])
    user_groups_token_ids
    respond_to do |format|
      if params[:user][:role_id]
        edutor_id = User::SHORT_ROLES[params[:user][:role_id].to_i]+"-%05d"
        @user.edutorid = edutor_id % @user.id
      end
      if params[:format] =='json' #request.content_type == 'application/json'
        if params[:password].present?
          @user.password = params[:password]
        end
        # params[:user][:profile_attributes]= params[:profile_attributes] if params[:profile_attributes].present?
        unless @user.institution.user_configuration.is_retail
          logger.info"=============out retail"
          params[:user][:institution_id] = @user.institution.id if @user.institution
          params[:user][:center_id] = @user.center.id  if @user.center
          params[:user][:academic_class_id] = @user.academic_class.id   if @user.academic_class
          params[:user][:section_id] = @user.section.id  if @user.section
        end
        #remove devices links if institution or center changes
        #6-20-1995
        #"date_of_birth(3i)"=>"19", "date_of_birth(2i)"=>"10", "date_of_birth(1i)"=>"2012",
        #@user.date_of_birth = DateTime.strptime(params[:user][:date_of_birth],"%m-%d-%Y").to_time.to_i if params[:user][:date_of_birth]
        #        @user.date_of_birth = DateTime.strptime(params[:user][:date_of_birth],"%m-%d-%Y") if params[:user][:date_of_birth]
        if params[:user][:date_of_birth]
          date = params[:user][:date_of_birth].split("-")
          date[0],date[1] = date[1],date[0]
          params[:user][:date_of_birth] = date.join("-")
        end
        if params[:user][:role_id].to_i==4 and (@user.institution_id_changed? or @user.center_id_changed?)
          remove_device_links(params[:user][:devices_attributes])
        end
      else
        #@user.date_of_birth = DateTime.strptime(params[:user][:date_of_birth],"%m-%d-%Y").to_time.to_i if params[:user][:date_of_birth]
        @user.institution_id = params[:user][:institution_id]
        @user.center_id = params[:user][:center_id]
        @user.academic_class_id = params[:user][:academic_class_id]
        @user.section_id = params[:user][:section_id]
      end

      if params.has_key?(:is_retail)
        is_retail = params[:is_retail]
      else
        is_retail = true
      end

      @user.plain_password = params[:user][:password] if params[:user][:password].present?
      @user.rollno = @user.edutorid if @user.rollno.nil?

      if  is_retail
        if @user.update_attributes(params[:user])
          @user.profile.update_attributes(params[:profile_attributes]) if [:profile_attributes].present? and !@user.profile.nil?
          @user.update_type
          @user.update_email
          format.html { redirect_to user_path(@user), notice: 'User was successfully updated.' }
          format.json { head :ok }
        else
          puts @user.errors.full_messages
          format.html { render action: "edit" }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      else
        if @user.update_attributes(:plain_password=>params[:user][:plain_password])
          @user.profile.update_attribute(:device_screen_name,params[:profile_attributes][:device_screen_name]) if [:profile_attributes].present? and !@user.profile.nil?
          #@user.profile.update_attributes(params[:profile_attributes]) if [:profile_attributes].present? and !@user.profile.nil?
          @user.update_type
          @user.update_email
          format.html { redirect_to user_path(@user), notice: 'User was successfully updated.' }
          format.json { head :ok }
        else
          puts @user.errors.full_messages
          format.html { render action: "edit" }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = Student.find(params[:id])
    @user.is_activated? ? @user.update_attribute(:is_activated,false) : @user.update_attribute(:is_activated,true)
    flash[:notice]= 'User was successfully updated.'
    redirect_to :back
  end

  def update_activation_status
    if request.xhr?
      case params[:mode]
        when 'ACT'
          if params[:status].eql?"Activate"
            users = User.update_all({:is_activated=>true},{:id=>params[:user_ids].split(',')})
            # User.send_messages(params[:user_ids].split(','),current_user.id,"Activate")
          else
            users = User.update_all({:is_activated=>false},{:id=>params[:user_ids].split(',')})
            # User.send_messages(params[:user_ids].split(','),current_user.id,"In-Activate")
          end
        when 'EN'
          if params[:status].eql?"Enroll"
            #after creating the message the user enroll status will be updated  by callback in message model
            # User.send_messages(params[:user_ids].split(','),current_user.id,"Enroll")
          else
            #after creating the message the user enroll status will be updated  by callback in message model
            User.send_messages(params[:user_ids].split(','),current_user.id,"De-Enroll")
          end
      end
      #@users = get_users
      respond_to do |format|
        format.js{}
      end
    else
      case params[:mode]
        when 'EN'
          begin
            user = User.find(params[:user_ids])
            subject=(params[:status].eql?"Enroll") ? "Enroll" : "De-Enroll"
            User.send_messages([user.id],current_user.id,subject)
          rescue
            message = "Something went wrong! Try again"
          end
      end
      flash[:notice] =  message
      redirect_to :back
    end

  end

  def reset_password_instructions
    User.find(params[:user_id]).send_reset_password_instructions if params[:user_id]
    redirect_to :back,notice: 'Sent Instructions successfully.'
  end

  #getting the group on selecting the class and scetion

  def get_group
    @user = User.find_by_section_id_and_academic_class_id_and_is_group(params[:section_id],params[:class_id],true)
    respond_to do |format|
      format.json { render json: @user.id }
    end
  end

  def user_groups_token_ids
    unless params[:user][:group_ids].blank?
      params[:user][:group_ids]= params[:user][:group_ids].split(',')
    end
  end

  def remove_device_links(params)
    params.keys.each do |key|
      params[key][:_destroy]= "1"
    end
  end

  def usage_report
    @user = User.find(params[:user_id])
    per_page = 3
    @total_user_usages = @user.usages
    #TODO remove the redundancy code
    if current_user.is? 'ET' # for the teacher the usage uri search will be total uri and for othere its only subject name
      teacher_class_content_ids = current_user.class_contents.map(&:id)
      teacher_class_contents = Content.where(:id=>teacher_class_content_ids).page(params[:page]).per(per_page)
      subject_names = teacher_class_contents.map(&:name) rescue []
      subject_uris =  teacher_class_contents.map(&:uri) rescue []
      @subjects = subject_names.join(',') rescue []

      @user_usages = teacher_class_contents.page(params[:page]).per(per_page) # to set the pagination based upon the subject names

      @usages = subject_uris.map{|uri|
        #@user_usages.where('uri like ?', "%#{uri}%").select('SUM(count) as count, SUM(duration)/60 as duration')[0]  if @user_usages
        @total_user_usages.where('uri like ?', "%#{uri}%").select('SUM(count) as count, SUM(duration)/60 as duration')[0]  if @total_user_usages.any?
      }
    else
      user_class_content_ids = @user.user_class_contents.map(&:id)
      user_class_contents = Content.where(:id=>user_class_content_ids).page(params[:page]).per(per_page)
      subject_names = user_class_contents.map(&:name) rescue []
      @subjects = subject_names.join(',') rescue []

      @user_usages = user_class_contents.page(params[:page]).per(per_page) # to set the pagination based upon the subject names

      @usages = subject_names.map{|subject|
        #@user_usages.where('uri like ?', "%#{subject}%").select('SUM(count) as count, SUM(duration)/60 as duration')[0]  if @user_usages
        @total_user_usages.where('uri like ?', "%#{subject}%").select('SUM(count) as count, SUM(duration)/60 as duration')[0]  if @total_user_usages.any?
      }
    end
    @usages.compact!
    if @usages
      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.insert(0,"").join(',')

      duration_ary =@usages.map{|usage| usage.duration.to_s}
      @durations = duration_ary.insert(0,"").join(',')

      count_max = count_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      duration_max = duration_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      max_val = count_max > duration_max ? count_max : duration_max rescue 0

      max_YVal = 1.to_s.ljust(max_val.to_s.size+1, "0").to_i

      @max_Y = max_YVal
      @tick_Y =  (max_YVal/10)

    end
  end



  def create_user_by_device_id
    #TODO create user by device id comes from tablet
    @result = {status: :unprocessable_entity ,message: "Failed to create user"}
    begin
      device = Device.find_by_deviceid(params[:deviceid])
      if device
        institution = device.institution
        center = device.center

        user = Student.new
        user.email ="test@edutor.com"
        user.role_id=4
        user.password = '4123'
        user.institution_id = institution.id
        user.center_id = center.id
        user.is_activated = true
        if user.save
          user.update_attribute('email',user.edutorid+"@myedutor.com")
          user.device_ids = [device.id] #assign device to saved user
          device.update_attribute(:device_type,'Primary')
          profile = user.build_profile
          profile.surname = params[:surName]
          profile.firstname = params[:fullName]||"firstname"
          profile.parent_email = params[:parentEmail]
          profile.parent_mobile = params[:parentMobile]
          profile.save
          puts "In process request from tablet: Failed to create profile #{profile.errors.full_messages}"

          class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
          section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
          @result = Hash[user_edutorid: user.edutorid,institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info,status: :ok,message: "Successfully created user"]

        else
          @result = {status: :unprocessable_entity ,message: "Failed to create user #{user.errors.full_messages}" }
          puts "In process request from tablet: Failed to create user #{user.errors.full_messages}"
          logger.error "In process request from tablet: Failed to create user #{user.errors.full_messages}"
        end
      elsif !device
        @result = {status: :unprocessable_entity ,message: "Failed to create user.No Device found with device id."}
        logger.error "In process request from tablet: Failed to create user.No Device found with device id."
      else
      end
    rescue Exception=>e
      logger.error "Exception in creating user.Request from tablet EXCEPTION:#{e}"
    end
    respond_to do |format|
      format.json {render json: @result,:layout=>false}
    end
  end

  def tab_reset_password
    @result = {:status=>:failed,:message=>"No params recieved.Expecting edutorid and deviceid"}
    if params[:edutor_id].present? and params[:device_id].present?
      user = User.find_by_edutorid(params[:edutor_id]) rescue @result={:status=>:failed,:message=>"No user found"}
      if user and !user.devices.empty? and user.devices.map(&:deviceid).include?(params[:device_id])
        new_password = params[:device_id].last(5).split('').shuffle.join
        user.password =  new_password
        user.rollno = user.edutorid
        user.save && UserMailer.password_notification(user,new_password).deliver
        if user.institution.user_configuration.deliver_reset_password_message
          message = Message.new
          message.recipient_id = user.center.center_admins.first.id
          message.sender_id = 1
          message.message_type ="Alert"
          message.subject = "Reset password for #{user.edutorid},#{user.name}"
          message.body = "<p>
                           Student new credentials are<br/>
                           Student edutorid is: #{user.edutorid}.<br/>
                           Student password is: #{new_password}.<br/>
                          </p>"
          message.save
        end
        @result={:status=>:ok,:message=>"Password Changed",:password=>new_password}
        logger.info "RESET PASSWORD=======================: #{user.edutorid}-#{new_password}==========================="
      elsif user and !user.devices.empty? and !user.devices.map(&:device_id).include?(params[:device_id])
        @result={:status=>:failed,:message=>"Not a primary device"}
      elsif user and user.devices.empty?
        @result={:status=>:failed,:message=>"No devices assigned to this user"}
      elsif !user
        @result = {:status=>:failed,:message=>"No user found"}
      end
    end
    respond_to do |format|
      format.json {render json: @result,:layout=>false}
    end
  end


  # This method send the sync command to the tab
  def user_sync
    @user = User.find(params[:id])
    if params[:m]
      m = params[:m]
    else
      m = 1
    end
    command ="mosquitto_pub -p 3333 -t #{@user.edutorid} -m #{m.to_i}  -i Edeployer -q 2 -h 173.255.254.228"
    logger.info"==#{command}"
    system(command)
    flash[:notice] = 'Sync message sent to the tab successfully'
    redirect_to (:back)
  end

  def user_get_quote
    respond_to do |format|
      format.json {render :json => nil, :status => :unprocessable_entity}
    end
    # if current_user
    #   user_quote_ids =  current_user.quotes.map(&:id)
    #   unless user_quote_ids.empty?
    #     @quote = Quote.where('id NOT IN',user_quote_ids).first
    #   else
    #     @quote = Quote.last
    #   end
    #   respond_to do |format|
    #     format.json {render text: @quote.name }
    #   end
    # else
    #   respond_to do |format|
    #     format.json {render :json => nil, :status => :unprocessable_entity}
    #   end
    # end
  end

  def user_get_tip
    if current_user
      @tips =  Tip.where(:user_id=>current_user.id,:status=>1).collect{|i| {:m_id=>i.id,:message=>i.name}}
      respond_to do |format|
        format.json {render json: @tips}
      end
    else
      respond_to do |format|
        format.json {render json: nil}
      end
    end
  end

  def user_ack_tip
    status_ids =  request.body.read
    tip_ids = ActiveSupport::JSON.decode(status_ids)
    unless tip_ids.nil?
      @tip = Tip.where(:id=>tip_ids).update_all(:status=>0)
    end
    respond_to do |format|
      format.json { render status: :ok}
    end
  end


  def get_firewall_list
    @list = IpAddress.all.map(&:address)
    respond_to do |format|
      format.json {render json: @list}
    end
  end


  def get_workspace_apps
#begin
    unless current_user.nil?
      device_id = request.headers['device_id']
      is_primary = current_user.devices.where('deviceid=? and device_type=?',device_id,'Primary').exists? unless current_user.devices.empty?
      if is_primary
        @apps = WorkSpaceApp.where(:user_id=>current_user.id).collect{|i|{:pkgName=>i.package_name,:screen=>i.work_space}}
      else
        @apps = nil
      end
    else
      @apps = nil
    end
#end
    respond_to do |format|
      format.json {render json: @apps }
    end
  end


  def post_user_config
    device_id = request.headers['device_id']
    string = request.body.read
    #logger.info"===============#{string}"
    config =  ActiveSupport::JSON.decode(string)
    #logger.info "==================#{config}"
    @apps = UserDeviceConfiguration.find_last_by_deviceid(device_id)
    if @apps.nil?
      @config = UserDeviceConfiguration.new
      @config.config = config['config']
      @config.workspace_apps = config['workspace_apps']
      @config.firewall = config['firewall']
      @config.apps = config['apps']
      @config.deviceid = device_id
      @config.save
    else
      @apps.update_attributes(:config=>config['config'],:workspace_apps=>config['workspace_apps'],:firewall=>config['firewall'],:apps=>config['apps'])
    end
    respond_to do |format|
      format.json {render json: true}
    end
  end

  def user_details
    @result = {}
    if user_signed_in?
      @user = User.includes(:institution,:center,:academic_class,:section,:devices,:profile).find(current_user.id)
      @result = {:user=>@user.as_json(:include => :profile).merge({:encrypted_password=>@user.plain_password})}
    end
    respond_to do |format|
      format.json {render json: @result}
    end
  end

  def generate_user_monthly_report

  end



  def user_monthly_report
    #year = Date.today.year
    #month = Date.today.month
    #days = (Date.new(year,12,31) << (12-month)).day
    start_date = params[:report_start_date]
    end_date = params[:report_end_date]
    #last_month_days1 = (Date.new(params[:report_end_date].to_date.year,12,31) << (12-params[:report_end_date].to_date.month)).day
    last_month_days2 = Date.new(params[:report_end_date].to_date.year,params[:report_end_date].to_date.month-1,1)
    @start_date = start_date
    @user =  User.find(params[:user])
    @assessment_result = []
    @content_usage = []
    @total_time_spent = []
    @data = false
    @subject_names = {'eng'=>'english','hin'=>'hindi','mat'=>'mathematics','sci'=>'science','soc'=>'social','civ'=>'civics','geo'=>'geography','his'=>'history','eco'=>'economics','bio'=>'biology','phy'=>'physics','che'=>'chemistry','bot'=>'botany','zoo'=>'zoology','kan'=>'kannada','tel'=>'telugu'}
    @messages = UserMessage.where(:user_id=>@user.id,:created_at=>start_date.to_time.to_i..end_date.to_time.to_i)
    @attempts= QuizAttempt.joins(:quiz).includes(:quiz=>{:context=>:subject}).where('user_id=? AND attempt=? AND quizzes.format_type IN (?)',@user.id,1,[0,1])#.where(:user_id=>@user.id,:attempt=>1).where('publish_id NOT IN (?) AND quiz.format_type!=')
    @month_attempts = @attempts.where(:timefinish=>start_date.to_time.to_i..end_date.to_time.to_i)
    #@total_published = @month_attempts.map(&:publish_id).uniq.count
    #@total_test_time = @month_attempts.collect{|i| i.quiz_question_attempts.sum(:time_taken)}
    #@total_test_time = @total_test_time.sum/60
    @assessment_usage = {}
    if !@month_attempts.empty?
      subject_ids = @attempts.collect{|i| i.quiz.context.subject_id}.uniq
      @subjects = Subject.where(:id=>subject_ids).group(:name).select('id,name')
      @subjects.each do |i|
        q_attempts = @attempts.includes(:quiz=>:context).where("contexts.subject_id=#{i.id}")
        q_month_attempts = @month_attempts.includes(:quiz=>:context).where("contexts.subject_id=#{i.id}")
        #@subject_names.each do |x,y|
        if @subject_names.keys.include? i.name.downcase[0,3]
          subject_name =  @subject_names[i.name.downcase[0,3]]
          if @assessment_usage.keys.include? subject_name
            @assessment_usage[subject_name][1]  = @assessment_usage[subject_name][1]+q_month_attempts.count
            @assessment_usage[subject_name][2]  = @assessment_usage[subject_name][2]+q_attempts.count
            @assessment_usage[subject_name][3]  = @assessment_usage[subject_name][3]+((q_month_attempts.collect{|s|s.sumgrades}.sum/q_month_attempts.collect{|a|a.quiz.quiz_question_instances.sum(:grade)}.sum)*100 rescue 0)
          else
            @assessment_usage = @assessment_usage.merge({"#{subject_name}"=>[subject_name,q_month_attempts.count, q_attempts.count,((q_month_attempts.collect{|s|s.sumgrades}.sum/q_month_attempts.collect{|a|a.quiz.quiz_question_instances.sum(:grade)}.sum)*100 rescue 0)]})
          end
        else
          if @assessment_usage.keys.include? i.name
            @assessment_usage[i.name][1]  = @assessment_usage[i.name][1]+q_month_attempts.count
            @assessment_usage[i.name][2]  = @assessment_usage[i.name][2]+q_attempts.count
            @assessment_usage[i.name][3]  = @assessment_usage[i.name][3]+((q_month_attempts.collect{|s|s.sumgrades}.sum/q_month_attempts.collect{|a|a.quiz.quiz_question_instances.sum(:grade)}.sum)*100 rescue 0)
          else
            @assessment_usage = @assessment_usage.merge({"#{i.name}"=>[i.name,q_month_attempts.count, q_attempts.count,((q_month_attempts.collect{|s|s.sumgrades}.sum/q_month_attempts.collect{|a|a.quiz.quiz_question_instances.sum(:grade)}.sum)*100 rescue 0)]})
          end
        end
        #end
      end
    end
    boards = @user.section.board_ids
    @device = @user.devices.first
    sql = "select id,uri,user_id,device_id, (end_time - start_time) as usage_time from user_usages where (user_id = #{@user.id} ) and uri is not NULL and (start_time BETWEEN #{start_date.to_time.to_i} and #{end_date.to_time.to_i}) and (end_time BETWEEN #{start_date.to_time.to_i} and #{end_date.to_time.to_i})"
    #@usages = UserUsage.find_by_sql(sql)
    sql = NewUserUsage.select('id,uri,user_id,device_id, (end_time - start_time) as usage_time').where("user_id = #{@user.id} ) and uri is not NULL and (end_time BETWEEN #{start_date.to_time.to_i} and #{end_date.to_time.to_i}").to_sql
    #logger.info"=========#{sql}"
    @usages =  NewUserUsage.select('id,uri,user_id,device_id, (end_time - start_time) as usage_time').where("user_id = #{@user.id} ) and uri is not NULL and (end_time BETWEEN #{start_date.to_time.to_i} and #{end_date.to_time.to_i}")
    #logger.info"=========#{@usages.count}"
    #@time_spent = @usages.map(&:usage_time).sum/60
    #@subject_names = {'eng'=>'English','hin'=>'Hindi','mat'=>'Mathematics','sci'=>'Science','soc'=>'Social','civ'=>'Civics','geo'=>'Geography','his'=>'History','eco'=>'Economics','bio'=>'Biology','phy'=>'Physics','che'=>'Chemistry','bot'=>'Botany','zoo'=>'Zoology','comm'=>'Commerce','comp'=>'Computers','kan'=>'kannada','tel'=>'telugu'}
    @subject_usage = {}
    @subject_chart = {}
    if !@usages.empty?
      uris = @usages.map(&:uri)
      uris = uris.uniq
      content_year_names = []
      content_subject_names = []
      @chart_data = []
      uris.each do |u|
        uri_split = u.split('/')
        if !uri_split.empty? and u.downcase.match "curriculum"
          i =1
          while !uri_split[i].downcase.match "curriculum"  do
            i +=1
          end
          content_year_names << uri_split[i+3]
          if uri_split[i+4].strip().match 'practice-tests' or u.match 'olympiad' or u.match 'iit' or u.match 'inclass'
            content_subject_names << u.split('/')[i+5].strip
          else
            content_subject_names << u.split('/')[i+4].strip
          end
        end
      end
      logger.info"====content years===#{content_year_names}=="
      content_subject_names = content_subject_names - ['practice-tests','insti-tests','inclass','home-work','assignment']
      @subjects = []
      content_subject_names.each do |s|
        push_status = false
        temp = s.split(' ')
        if temp.length > 1 # for example "Social Science" will consider as a social in the bellow matching case
          s = temp[0];
        end
        @subject_names.each do |x,y|
          if x.match s.downcase
            @subjects << y
            push_status = true
          end
        end
        if push_status != true
          @subjects << s
        end
      end
      #logger.info"=============#{boards}"
      #logger.info"==========#{content_subject_names}"
      h = Hash.new(0)
      content_year_names.each { | v | h.store(v, h[v]+1) }
      content_year_name = h.first[0]
      #logger.info"=====#{content_subject_names}"
      content_year_ids = ContentYear.where(:name=>content_year_names.uniq,:board_id=>boards).map(&:id)
      content_subjects = Subject.where(:board_id=>boards,:content_year_id=>content_year_ids,:name=>content_subject_names.uniq).group(:name)

      content_subjects.each do |s|
        subject_usages =  @usages.where("uri like '%#{s.name}%'")
        subject_usage_duration = subject_usages.select('(end_time - start_time) as usage_duration').map(&:usage_duration).sum
        #sql2 = Content.where(:type=>'Subject',:content_year_id=>content_year_ids.first).where("name like '%#{s.name}%'").to_sql
        #logger.info"======sql2=========#{sql2}"
        all_subject_ids = Content.where(:type=>'Subject',:content_year_id=>content_year_ids.first).where("name like '%#{s.name}%'").map(&:id)
        # subject_total_file_count  = Content.where(:subject_id=>all_subject_ids).count
        #this_month_count =  subject_total_file_count - subject_usages.map(&:uri).uniq.count
        total_subject_usage = NewUserUsage.where("user_id=#{@user.id} and uri like '%#{s.name}%' ").map(&:uri).uniq.count
        #sql3 = NewUserUsage.where("user_id=#{@user.id} and uri like '%#{s.name}%' and (end_time BETWEEN #{start_date.to_time.to_i} and #{last_month_days2.to_time.to_i}) ").to_sql
        #logger.info"==sql3===#{sql3}"
        #till_last_month_count = NewUserUsage.where("user_id=#{@user.id} and uri like '%#{s.name}%' and (end_time BETWEEN #{last_month_days2.to_time.to_i} and #{ end_date.to_time.to_i}) ").map(&:uri).uniq.count
        # till_last_month_count = NewUserUsage.where("user_id=#{@user.id} and uri like '%#{s.name}%' and (end_time < #{start_date.to_time.to_i}) ").map(&:uri).uniq.count
        #logger.info"=====till last month=======#{till_last_month_count}"
        total_subject_usage_count = total_subject_usage  #((total_subject_usage*100)/subject_total_file_count rescue 0)
        #last_month_count = till_last_month_count#((till_last_month_count*100)/subject_total_file_count rescue 0)
        if subject_usage_duration !=0
          @total_time_spent  << subject_usage_duration/60
          if @subject_names.keys.include? s.name.downcase[0,3]
            subject_name =  @subject_names[s.name.downcase[0,3]]
            if @subject_usage.keys.include? subject_name
              @subject_usage[subject_name][1] = @subject_usage[subject_name][1]+total_subject_usage_count
              # @subject_usage[subject_name][2] = @subject_usage[subject_name][2]+last_month_count
              @subject_usage[subject_name][3] = @subject_usage[subject_name][3]+subject_usage_duration/60
              # @subject_usage[subject_name][4] = @subject_usage[subject_name][4]+subject_total_file_count
              @subject_chart[subject_name][1] = @subject_chart[subject_name][1]+subject_usage_duration/60
            else
              @subject_usage = @subject_usage.merge({"#{subject_name}"=>[subject_name,subject_usage_duration/60]})
              @subject_chart = @subject_chart.merge({"#{subject_name}"=>[subject_name,subject_usage_duration/60]})
            end
          else
            if @subject_usage.keys.include? s.name
              @subject_usage[s.name][1] = @subject_usage[s.name][1]+total_subject_usage_count
              #      @subject_usage[s.name][2] = @subject_usage[s.name][2]+last_month_count
              @subject_usage[s.name][3] = @subject_usage[s.name][3]+subject_usage_duration/60
              #      @subject_usage[s.name][4] = @subject_usage[s.name][4]+subject_total_file_count
              @subject_chart[s.name][1] = @subject_chart[s.name][1]+subject_usage_duration/60
            else
              #     @subject_usage = @subject_usage.merge({"#{s.name}"=>[s.name,total_subject_usage_count,last_month_count,subject_usage_duration/60,subject_total_file_count]})
              @subject_chart = @subject_chart.merge({"#{s.name}"=>[s.name,subject_usage_duration/60]})
            end
          end
          #end
          #@subject_usage = @subject_usage.merge({:})
          #@content_usage << [s.name,total_subject_usage_count,last_month_count,subject_usage_duration.first.usage_duration.to_i/60]
          #@chart_data << [s.name,subject_usage_duration.first.usage_duration.to_i/60]
        end
      end
      @data= true
    end
    @time_spent = @total_time_spent.sum
    #logger.info"==========#{@subject_usage}"
    #logger.info"==========#{@assessment_usage}"
    respond_to do |format|
      format.html{render :layout=> false}
      #format.json
      format.pdf do
        render :pdf => "#{@user.name}_#{@user.edutorid}",
               :disposition => 'attachment',
               :template=>"users/user_monthly_report.html.erb",
               #:show_as_html=>true,
               :disable_external_links => true,
               :print_media_type => true
      end
    end
  end

  def monthly_reports

  end


  #obs_user_registration
  def obs_user_registration
    user = User.find_by_edutorid(params[:user_id])
    #respond_to do |format|
    #  format.json {render json: {:user_accepted=>true}}
    #end
    respond_to do |format|
      if user && user.valid_password?(params[:password])
        sign_in('user',user)
        format.json {render json: {:user_accepted=>true,:user_name=>user.name}}
      else
        format.json {render json: {:user_accepted=>false,:error=>'Invalid User'}}
      end
    end
  end


  #user tab session i.e login and logout time is captured
  def user_tab_sessions
    user_session = JSON.load(params[:sessions])
    mac_id = params[:mac_id]
    deviceid = params[:device_id]
    ids = []
    user_session.each do |session|
      session_exist = UserDeviceSession.where(:mac_id=>mac_id,:deviceid=>deviceid,:user_id=>session['user_id'],:event_time=>session['time'].to_i,:event_type=>session['type'])
      if session_exist.empty?
        user_session_create = UserDeviceSession.new(:mac_id=>mac_id,:deviceid=>deviceid,:user_id=>session['user_id'],:event_time=>session['time'].to_i,:event_type=>session['type'])
        if user_session_create.save
          ids << session['id']
        end
      else
        ids << session['id']
      end
    end
    respond_to do |format|
      format.json { render json:ids }
    end
  end

  #user_device_sessions

  def user_device_sessions
    ids = []
    @session_ids = []
    #@user_sessions = UserDeviceSession.order('id desc')
    @user_device_sessions = UserDeviceSession.order('id desc')
    @user_device_sessions.each do |s|
      if !ids.include? s.id
        if s.event_type == -1
          login = @user_device_sessions.where("deviceid=? and id < ? and event_type=?",s.deviceid,s.id,1 ).order('id desc').first
          unless login.nil?
            ids << s.id
            ids << login.id
            @session_ids << [s.id,login.id]
          end
        end
      end
    end
    logger.info "========#{@session_ids}"
  end

  # user active status
  def get_user_status
    @result = {}
    @result = @result.merge({:server_time_in_seconds=>Time.now.to_i})
    if params[:edutorid].nil?
      respond_to do |format|
        format.json{ render json:@result }
      end
      return
    end
#    if params[:edutorid]
    @user = User.find_by_edutorid(params[:edutorid])
#    else
#     @user = User.find_by_edutorid(params[:user][:edutorid])
#    end
    if !@user.nil? && @user.is_activated
      @result = @result.merge({:isenrolled=>true,:print=>@user.is_printable})
    else
      @result = @result.merge({:isenrolled=>false,:msg=>'User login is disabled'})
    end
#@result = @result.merge({:print=>@user.is_printable})
    respond_to do |format|
      format.json{ render json:@result }
    end
  end



  def user_change_password
    @result = {:status=>false}
    @user = User.find_by_edutorid(params[:edutorid])
    if  @user and ( @user.valid_password? params[:old_password])
      if @user.reset_password!(params[:changed_password],params[:changed_password])
        @user.update_attribute(:plain_password,params[:changed_password])
        UserMailer.password_notification(@user,params[:changed_password]).deliver
        @result = @result.merge({:status=>true})
      end
    end
    respond_to do |format|
      format.json{ render json: @result}
    end
  end

  def user_forgot_password
    @result = {:status=>false}
    if params[:rollno].present?
      @user = User.find_by_rollno_and_email(params[:rollno],params[:email])
    else
      @user = User.find_by_edutorid_and_email(params[:edutorid],params[:email])
    end

    #  logger.info "==forgot=====#{@user.id}"
    if @user.nil?
      @result = @result.merge({:status=>false,:message=>"Invalid User or email"})
      respond_to do |format|
        format.json { render json: @result}
      end
      return
    end

    @user.send_reset_password_instructions
    @result = @result.merge({:status=>true,:message=>"Reset password instructions sent to your email"})

    respond_to do |format|
      format.json { render json: @result}
    end

  end

  def send_user_password
    @user = User.find_by_id_and_reset_password_token( params[:format],params[:reset_password_token])
    if @user.nil?
      render text:"Invalid token",:layout=>false
      return
    else
      new_password = rand(1..9).to_s+rand(1..9).to_s+rand(1..9).to_s+rand(1..9).to_s
      @user.password =  new_password
      @user.rollno = @user.edutorid  if @user.rollno.nil?
      @user.reset_password_token = nil
      @user.reset_password_sent_at = nil
      @user.plain_password = new_password
      if @user.save(:validate=>false) && UserMailer.password_notification(@user,new_password).deliver
        render text:"Reset password sent to your registered email",:layout=>false
        return
      else
        render text:"Invalid email or user",:layout=>false
        return
      end
    end
  end


  def user_login
    @result = {:status=>false}
    @user = User.find_by_edutorid(params[:edutorid])
    if @user and @user.valid_password?(params[:password])
      @result = {:status=>true}
    end
    respond_to do |format|
      format.json { render json:@result}
    end
  end

  def authenticate_password
    valid_password = current_user.valid_password? params[:password]
    if valid_password
      respond_to do |format|
        format.json { render json: {valid: true} }
      end
    else
      respond_to do |format|
        format.json { render json: {valid: false} }
      end

    end
  end

  def user_device_info
    if user_signed_in? and params[:user_build_info].present?
      @user_device_info = UserDeviceInfo.find_by_user_id(current_user.id)
      params[:user_build_info]["user_id"] = current_user.id
      if @user_device_info.nil?
        @info = UserDeviceInfo.new(params[:user_build_info])
        respond_to do |format|
          if @info.save
            format.json {render json: true}
          else
            format.json {render json: false}
          end
        end
      else
        respond_to do |format|
          if @user_device_info.update_attributes(params[:user_build_info])
            format.json {render json: true}
          else
            format.json {render json: true}
          end
        end
      end
    else
      respond_to do |format|
        format.json {render json: false}
      end
    end

  end


  def publish_stats
    @user = current_user
    @new_user_usages
  end


  def generate_user_publish_stats

    if current_user.is? :IA
      @users = current_user.institution.institute_admins + current_user.institution.centers.map{|p|p.center_admins}.flatten + current_user.institution.teachers
    elsif current_user.is? :CR
      @users = current_user.institution.centers.map{|p|p.center_admins}.flatten + current_user.center.teachers
    elsif current_user.is? :EA
    else
      @users = [current_user]

    end
    if !current_user.is? :ET
      if current_user.is? :IA
        if params[:new_user_usages][:institution_id].present?
          if params[:new_user_usages][:center_id].present?
            @users = Institution.find(params[:new_user_usages][:institution_id]).institute_admins + Center.find(params[:new_user_usages][:center_id]).center_admins + Center.find(params[:new_user_usages][:center_id]).teachers

          else
            @users = Institution.find(params[:new_user_usages][:institution_id]).institute_admins + Institution.find(params[:new_user_usages][:institution_id]).centers.map{|p|p.center_admins}.flatten  + Institution.find(params[:new_user_usages][:institution_id]).teachers
          end
        end
      end
    end

    csv_header = "User_name, User_role,user_class_name,teacher_section_name,content_published_to," \
                  "book_name,book_subject,book_class,display_name,published_file_name(Physical),type_of_content," \
                  "password_details,published_date,total_no_of_students,no_of_students_downloaded," \
                  "link_to_download_published_content,Published_to_inbox_or_TOC," \
                  "TOC_Subject_name,TOC_chapter_name,TOC_Topic_name".split(",")

    csv_header_uploads = "Teacher_Name,teacher_class_name,teacher_section_name,asset_name," \
                          "attachment_file_name,launch_file,content_type, number_of_times_published".split(",")
    file_name = Time.now.to_i.to_s+ "_" +(current_user.id).to_s+ ".csv"
    csv_data = FasterCSV.generate do |csv|
      csv << csv_header
      @users.each do |usr|
        usr.published_content_stats(params[:report_start_date].to_datetime,params[:report_end_date].to_datetime.end_of_day).each do |c|
          csv << c
        end
        usr.published_assessment_stats(params[:report_start_date].to_datetime,params[:report_end_date].to_datetime.end_of_day).each do |c|
          csv << c
        end
        usr.content_published_to_inbox(params[:report_start_date].to_datetime,params[:report_end_date].to_datetime.end_of_day).each do |c|
          csv << c
        end
        #csv_data = teacher.uploaded_content_stats
      end
    end

    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"


  end

  def single_pack_revoke
    license_set = LicenseSet.find(params[:license_id])
    user = license_set.users.where(id:params[:user_id]).first
    if user.present?
      license_set.users.delete(user)
      user.update_attribute("last_content_purchased",Time.now)
    end
    license_set.reevaluate_license_set
    flash[:notice] = "License sucessfully revoked"
    redirect_to "/users/#{params[:user_id]}"
  end


  def get_signup_status
    @result = {}
    if params[:email].nil?
      respond_to do |format|
        format.json{ render json:@result }
      end
      return
    end
    @user = User.where(:email=>params[:email],:institution_id=>params[:inst]).last

    if @user.nil?
      @result = @result.merge({:isVerified=>false,:isRegistered=>false})
      respond_to do |format|
        format.json{ render json:@result }
      end
      return
    end

    if @user.is_activated
      @result = @result.merge({:isVerified=>true,:isRegistered=>true})
    else
      @result = @result.merge({:isVerified=>false,:isRegistered=>true})
    end
    respond_to do |format|
      format.json{ render json:@result }
    end
  end

  def user_update_interface
  @institution_id = current_user.institution.id
  @user = current_user
  @students = []
  end
  def fetch_users
    section_id = params[:user][:section_id]
    @users = current_user
    @students = Section.find(section_id).students
    respond_to do |format|
      format.js
    end
  end
  def user_data_update
    @students = params[:students_update][:user_ids]
    section_id = params[:user][:section_id] if params[:user][:section_id].present?
    academic_class_id = params[:user][:academic_class_id] if params[:user][:academic_class_id].present?
    @message = "No taskselected"
    if params["delete_user_messages"].present?
      if params["delete_user_messages"] == "message_delete_function"
        User.delete_user_messages(user_ids = @students)
        @message1 = "Students's user_messages deleted successfully"
      end
    end
    if params["deactivate_students"].present?
      if params["deactivate_students"] == "user_deactivate_status"
        User.deactivate_users(user_ids = @students)
        @message2 = "Students deactivated successfully"
      end
    end
    if params["reactivate_students"].present?
      User.reactivate_users(user_ids = @students)
      @message3 = "Students reactivated successfully"
    end
    if params[:migrate_students].present?
      n, errs = 0, []
      @students.each do |student|
        user = User.find(student)
        device_id = user.devices.map(&:id)
        Device.where(:deviceid=>device_id).update_all(:mac_id=>nil,:android_id=>nil)
        DeviceMessage.where('deviceid=? OR group_id IN (?)',device_id,user.group_ids).destroy_all
        if user
          user.academic_class_id = academic_class_id
          user.section_id = section_id
          user.group_ids = nil
          user.save(:validate=>false)
        else
          errs << student
        end
      end
      if errs.any?
        errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
        errs.insert(0, userid)
        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row}
        end
        send_data errCSV,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=#{errFile}.csv"
      else
        flash[:notice] = 'User Migrated Successfully'
        # redirect_to user_update_interface_users_path
      end
      end
    # @message = @message1 + @message2
    redirect_to "/"
  end
end

