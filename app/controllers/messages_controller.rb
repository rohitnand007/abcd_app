class MessagesController < ApplicationController
  authorize_resource
  # GET Autocomplete
  autocomplete :profile, :surname, :extra_data => [:firstname], :display_value => :display_method

  def profile_users
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      begin
        students = case current_user.rc
                     when 'EA'
                       User.students
                     when 'IA','EO'
                       current_user.users
                     when 'CR'
                       current_user.users
                     when 'ET'
                       class_room_groups = current_user.groups.select { |g| ["Institution", "Center"].exclude?(g.type)}.uniq.map(&:id)
                       class_room_groups.map{|group| User.find(group).users.students.students_activated}.flatten
                   end

        #students = students - students.students_de_enrolled unless current_user.is?'ET'# to filter the de enrolled students from the result
        users =  Profile.includes(:user).where('users.id'=>students).where("surname like ? or firstname like ? or users.edutorid like ? or users.rollno like ? ",like,like,like,like)
      rescue
        users =[]
      end
      #else
      # users = Profile.all
    end
    list = users.empty? ? users : users.map {|u| Hash[id: u.user_id, label: u.autocomplete_display_name, name: u.autocomplete_display_name]}
    render json: list
  end

  # GET /messages
  # GET /messages.json
  def index
    group_ids = current_user.groups.map(&:id)
    @messages = Message.all_received_messages(current_user,group_ids).order('created_at DESC').page(params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @messages }
    end
  end

  def sent
    @messages = Message.where(sender_id: current_user.id).order('created_at DESC').page(params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @messages }
    end
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
    @message = Message.find(params[:id])
    # @ack = MessageAcknowledg.where("message_id =? and user_id =? and status =? ",@message.id,current_user.id,false)
    #  unless @ack.empty?
    #  @ack.update_all(:status=>true)
    #end
    if current_user.is? "ES"
      authorize! :show, @message
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @message }
    end
  end

  # GET /messages/new
  # GET /messages/new.json
  def new
    @message = Message.new
    if params[:recipient_id]
      @recipient = User.find(params[:recipient_id])
    end
    if params[:content_id]
      @content = Content.find(params[:content_id])
    end
    @message.assets.build

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @message }
    end
  end

  # GET /messages/1/edit
  def edit
    @message = Message.find(params[:id])
  end

  # POST /messages
  # POST /messages.json
  def create
    @message = Message.new(params[:message])
    if params[:content_id]
      @content = Content.find(params[:content_id]) rescue nil
    end
    respond_to do |format|
      @message.transaction do
        @multiple_receiver_ids = @message.multiple_recipient_ids.split(',')
        #sending messages to individual or multiple individuals at a time
        unless @multiple_receiver_ids.empty?
          succ = 0
          @multiple_receiver_ids.each do |recipient_id|
            @message = Message.new(params[:message])
            @message.recipient_id = recipient_id
            @message.group_id = nil
            if @message.save
              #unless @message.recipient.nil?
              #  UserMessage.create(:user_id=>@message.recipient_id,:message_id=>@message.id)
              #end
              succ = succ + 1
              if @content
                url = (@content.type.eql?"Assessment") ? @content.asset.attachment.url : @content.assets.first.attachment.url
                @message.assets.create(:attachment=>File.new(Rails.root.to_s+"/public"+url,'r'))
                UserMailer.content_notification(@message.recipient,@content,@message).deliver
              end
            end
          end
          if succ > 0
            format.html { redirect_to @message, notice: "Message was successfully posted to #{User.where(:id=>@multiple_receiver_ids).map(&:fullname).join(',')}" }
            format.json { render json: @message, status: :created, location: @message }
          else
            @message.assets || @message.assets.build
            format.html { render action: "new" }
            format.json { render json: @message.errors, status: :unprocessable_entity }
          end
          # sending message to group
        else
          if @message.save
            if @content
              url = (@content.type.eql?"Assessment") ? @content.asset.attachment.url : @content.assets.first.attachment.url
              @message.assets.create(:attachment=>File.new(Rails.root.to_s+"/public"+url,'r'))
              UserMailer.content_notification(@message.recipient,@content,@message).deliver
            end

            #unless @message.group_id.nil?
            #  #UserGroup.includes(:user).where(:group_id=>@message.group_id).where('users.edutorid like?','%ES-%')
            #  UserGroup.includes(:user).where(:group_id=>@message.group_id).each do |user|
            #    UserMessage.create(:user_id=>user.user_id,:message_id=>@message.id)
            #    command ="mosquitto_pub -p 3333 -t #{user.user.edutorid} -m 2  -i Edeployer -q 2 -h 173.255.254.228"
            #    system(command)
            #  end
            #end

            format.html { redirect_to @message, notice: 'Message was successfully posted.' }
            format.json { render json: @message, status: :created, location: @message }
          else
            @message.assets || @message.assets.build
            format.html { render action: "new" }
            format.json { render json: @message.errors, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  def get_user_messages
    if params[:format] == 'json'
      @result = {}
      #logger.info"===#{params[:time]}"
      user_id = params[:user_id]  
    #  @user = User.find(user_id)
    #  system("mosquitto_pub -p 3333 -t #{@user.edutorid} -m 6  -i Edeployer -q 2 -h 173.255.254.228")
    #  system("mosquitto_pub -p 3333 -t #{@user.edutorid} -m 3  -i Edeployer -q 2 -h 173.255.254.228")
    #  if @user.devices
     #   @user.devices.each do |device|
        #  system("mosquitto_pub -p 3333 -t #{device.deviceid} -m 6  -i Edeployer -q 2 -h 173.255.254.228")
        #  system("mosquitto_pub -p 3333 -t #{device.deviceid} -m 3  -i Edeployer -q 2 -h 173.255.254.228")
      #  end
     # end
      if params[:time].to_i == 0 and !user_id.nil?
        @messages = Message.includes(:user_messages).where('user_messages.user_id =?',user_id)
        #  file = File.new(Rails.root.to_s+"/public/message_zero_time.txt", "a+")
        #  File.open(file,  "a", 0644) do |f|
        #   f.puts(user_id.to_s+"==="+Time.now.to_s+"==="+@messages.count.to_s)
        # #  f.puts(@user.id)
        #  end
      else
        @messages = Message.includes(:user_messages).where('user_messages.user_id =? AND user_messages.sync =?',user_id,1)
      end
      #@messages = @messages.as_json(:include=>:assets)
      #@result = @result.merge({:messages=>@messages})
    end
    respond_to do |format|
      format.json { render json: @messages.as_json(:include => :assets) }
    end
  end




  def user_messages_status
    @result = {}
    status_ids =  request.body.read
    message_ids = ActiveSupport::JSON.decode(status_ids)
    device_id = request.headers['device_id']
    #logger.info"================message_ids=========#{message_ids}"
   # is_primary = current_user.devices.where('deviceid=? and device_type=?',device_id,'Primary').exists?
    if current_user
      #logger.info "==================current user=#{current_user.id}"
     #is_primary = current_user.devices.where('deviceid=? and device_type=?',device_id,'Primary').exists?
      #if is_primary
        message_ids.each do |m|
          messages = Message.where(:message_id=>m['id']).map(&:id)
          UserMessage.where(:user_id=>current_user.id ,:message_id=>messages).update_all(:sync=>0)
        end
        @result = @result.merge({:response=>'success'})
      else
        @result = @result.merge({:edutorid=>404})
      #end
    end
    respond_to do  |format|
      format.json {render json: @result}
    end

  end


  # PUT /messages/1
  # PUT /messages/1.json
  def update
    @message = Message.find(params[:id])

    respond_to do |format|
      if @message.update_attributes(params[:message])
        format.html { redirect_to @message, notice: 'Message was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to messages_url }
      format.json { head :ok }
    end
  end
  def users
    if params[:id]
      @user = User.find(params[:id])
    elsif current_user
      @user = User.find(current_user.id) 
    end
  #  @user = User.find(current_user.id)
    @messages = []

    #for tablet request
    if params[:time]
      time  = params[:time].to_i
      # if device_id sent by tablet
      if !@user.devices.empty? and params[:device_id].present?
        device = Device.find_by_deviceid(params[:device_id]) rescue nil
        is_primary = @user.devices.map(&:id).include?(device.try(:id))
        # if device_id not sent by tablet and user has devices
      elsif !@user.devices.empty?
        is_primary = true
        # if device_id id not sent by tablet and user has no devices
      else
        is_primary = false
      end

      if !@user.groups.empty?
        group_ids = @user.groups.map(&:id)

        #append individual and group messages to @messages
        if @user.is_enrolled and is_primary
          @messages =  Message.all_received_messages(@user,group_ids).where('updated_at > ?',time)
        elsif @user.is_enrolled and !is_primary
          @messages = Message.where('updated_at > ?',time).limit(2).find_all_by_recipient_id_and_group_id(nil,group_ids)
          @messages << Message.where("recipient_id=? and updated_at > ?",@user,time).limit(2)
        elsif !@user.is_enrolled
          @messages =  Message.all_received_messages(@user,group_ids).where('updated_at > ? and message_type = ? ',time,'Control Message')
        end

        @messages.flatten!

      end
    end

    #for web request
    unless params[:time]
      group_ids = @user.groups.map(&:id)
      @messages =  Message.all_received_messages(@user,group_ids).order('created_at DESC').page(params[:page])
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @messages.as_json(:include => :assets)  }
    end
  end

  def acknowledgements
    #ack_string = request.body.read
    #acks =  ActiveSupport::JSON.decode(ack_string)
    #acks.each do |ack|
    #  @messageAck = MessageAcknowledg.find_by_user_id_and_message_id_and_status(ack['user_id'],ack['message_id'],false)
    #  respond_to do |format|
    #    if @messageAck
    #      @messageAck.update_attribute('status',true)
    #      format.json { @messageAck }
    #    else
    #      format.json { false }
    #    end
    #  end
    #end

    logger.debug params
    ack_string = request.body.read
#    logger.info"===============#{ack_string}"
    acks =  ActiveSupport::JSON.decode(ack_string)
 #   logger.info"===============#{acks}"
    ack_ids = []
    @user = current_user
    acks.uniq.each do |ack|
      logger.info "===#{ack}"
      message_id = ack["message_id"].to_s.gsub(".","_")
      @message_type = ack["message_id"].to_s.gsub(".","_").split(//)[0] == "-" ? 'DeviceMessage' :'Message'
    if ack["message_id"].include? "_"
      if ack["message_id"].to_s.gsub(".","_").split(//)[0] == "-"
        message = DeviceMessage.find_by_message_id(message_id)
      else
        message = Message.find_by_message_id(message_id)
      end
    else
      message = nil
       ack_ids <<  ack["message_id"]
    end
      if !message.nil?
        if ack["user_id"].to_s.split(//).size > 9
          user = Device.find_by_deviceid(ack["user_id"]).users.first
        else
          user = User.find_by_id(ack["user_id"].to_i)
        end
        if !user.nil?
          @messageAck_present = MessageAcknowledg.find_by_user_id_and_message_id_and_message_type(user.id,message.id,@message_type)
          #@messageAck_present = MessageAcknowledg.where(:user_id=>user.id,:message_id=>message.id,:message_type=>message.class.name)
          if !@messageAck_present.nil?
            @messageAck_present.update_attributes(:status=>ack["state"],:created_at=>ack["created_at"].to_i)
            ack_ids <<  ack["message_id"]
          else
            @messageAck = MessageAcknowledg.new(:user_id=>user.id,:message_id=>message.id,:status=>ack["state"],:message_type=>@message_type,:created_at=>ack['created_at'])
            @messageAck.save
            ack_ids <<  ack["message_id"]
          end
        end
     # else
     #   @messageAck = MessageAcknowledg.new(:user_id=>@user.id,:message_id=>ack["message_id"],:status=>ack["state"],:message_type=>@message_type,:created_at=>ack['created_at'])
      #  @messageAck.save
      #  ack_ids <<  ack["message_id"]
      end

    end

    respond_to do |format|
      format.json {render json: ack_ids }
    end
  end

  def update_message_status(message,user)
    MessageAcknowledg.update_all(:conditions=>['user_id=? and message_id=?'])
  end


 #Assessment  and concept map messages for a user

  def assessment_conceptmap_messages
    @user = current_user
    group_ids = @user.groups.map(&:id)
    @messages = Message.all_received_messages(@user,group_ids).where(:message_type=>['Assessment','ConceptMap'])
    respond_to do |format|
      format.json { render json: @messages.as_json(:include => :assets)  }
    end
  end

end
