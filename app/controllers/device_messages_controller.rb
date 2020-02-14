class DeviceMessagesController < ApplicationController
  #authorize_resource
  before_filter :check_login
  # GET /device_messages
  # GET /device_messages.json
  def index
    if current_user.is?"IA"
     @device_messages = DeviceMessage.where("deviceid is NOT NULL AND sender_id = #{current_user.id}").order("id desc").page(params[:page])
    else
    # @device_messages = DeviceMessage.where("deviceid is NOT NULL").order("id desc").page(params[:page])
     @device_messages = DeviceMessage.order("id desc").page(params[:page])
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @device_messages }
    end
  end

  # GET /device_messages/1
  # GET /device_messages/1.json
  def show
    @device_message = DeviceMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device_message }
    end
  end

  # GET /device_messages/new
  # GET /device_messages/new.json
  def new
    @device_message = DeviceMessage.new
    @device_message.assets.build

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @device_message }
    end
  end

  # GET /device_messages/1/edit
  def edit
    @device_message = DeviceMessage.find(params[:id])
  end

  # POST /device_messages
  # POST /device_messages.json
  def create
    @device_message = DeviceMessage.new(params[:device_message])
    respond_to do |format|
      @device_message.transaction do
        @multiple_receiver_ids = @device_message.multiple_recipient_ids.split(',')

        unless @multiple_receiver_ids.empty?
          succ = 0
          @multiple_receiver_ids.each do |recipient_id|
            @device_message = DeviceMessage.new(params[:device_message])
            @device_message.deviceid = recipient_id
            if @device_message.save
              succ = succ + 1
            end
          end
          if succ > 0
            format.html { redirect_to @device_message, notice: 'Device message was successfully created.' }
            format.json { render json: @device_message, status: :created, location: @device_message }
          else
            format.html { render action: "new" }
            format.json { render json: @device_message.errors, status: :unprocessable_entity }
          end
        else
          if @device_message.save
            format.html { redirect_to @device_message, notice: 'Device message was successfully created.' }
            format.json { render json: @device_message, status: :created, location: @device_message }
          else
            format.html { render action: "new" }
            format.json { render json: @device_message.errors, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  # PUT /device_messages/1
  # PUT /device_messages/1.json
  def update
    @device_message = DeviceMessage.find(params[:id])

    respond_to do |format|
      if @device_message.update_attributes(params[:device_message])
        format.html { redirect_to @device_message, notice: 'Device message was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @device_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /device_messages/1
  # DELETE /device_messages/1.json
  def destroy
    @device_message = DeviceMessage.find(params[:id])
    @device_message.destroy
    #@device_message.update_attributes(:deviceid=>nil,:recipient_id=>nil,:group_id=>nil)
    #@device_message.deviceid = nil
    #@device_message.recipient_id= nil
    #@device_message.group_id = nil
    #@device_message.save(:validate=>false)
    respond_to do |format|
      format.html { redirect_to device_messages_url }
      format.json { head :ok }
    end
  end

  #
  def get_deviceids
    if params[:term].present?
      term = "%#{params[:term]}%"
      if current_user.is?"IA"
      @devices = Device.where("deviceid like ? AND institution_id=?",term,current_user.institution.id).limit(20)
      else
      @devices = Device.where("deviceid like ? ",term).limit(20)
      end
      respond_to do |format|
        format.json { render json: @devices.map{|u| Hash[id: u.deviceid, name: u.deviceid]} }
      end
    else
      respond_to do |format|
        format.json { render json: "please type" }
      end
    end
  end

  def delete_device_messages
    group_ids = []
    if params[:device_message]
      params[:device_message][:multiple_ids].split(',').each do |d|
        device = Device.find_by_deviceid(d)
        if !device.nil?
          group_ids <<  UserGroup.where(:user_id=>device.users.map(&:id)).map(&:group_id)
        end
       end
     DeviceMessage.where('deviceid IN (?) OR group_id IN (?)',params[:device_message][:multiple_ids].split(','),group_ids).destroy_all
     # DeviceMessage.where(:deviceid=>params[:device_message][:multiple_ids].split(','),:group_id=>group_ids.uniq).destroy_all
      redirect_to device_messages_path
    end
  end



private
  def check_login
    if !(current_user.is?"EA" or ((current_user.is?"IA" or current_user.is?"CR") and  current_user.institution.user_configuration.is_admin_privilege))
      redirect_to root_path
    else
      true
    end
  end

end
