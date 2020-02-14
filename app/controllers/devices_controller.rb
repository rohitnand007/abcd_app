class DevicesController < ApplicationController
  include ApplicationHelper
   authorize_resource :except=>:get_device
  # GET /devices
  # GET /devices.json
  skip_before_filter :authenticate_user!, :only=>:get_device
  autocomplete :profile, :surname, :extra_data => [:firstname], :display_value => :display_method

  def students
    if request.xhr?
      like= "%".concat(params[:q].concat("%"))
      if current_user.is?'EA'
        @users = User.where('edutorid like ? or edutorid like ?',"%ES%","%ET%").includes(:profile).where('is_group=? and institution_id=? and center_id=? and profiles.firstname like ? ',false,params[:institution_id],params[:center_id],like)
      else
        @users = current_user.users.where('edutorid like ? or edutorid like ?',"%ES%","%ET%").includes(:profile).where('center_id=? and profiles.firstname like ? ',params[:center_id],like)
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users.map{|u| Hash[id: u.id,label: u.profile.try(:autocomplete_display_name), name: u.profile.try(:autocomplete_display_name)]} }
    end
  end

  def index
    require "DataTable"
    @devices = case current_user.rc when 'EA'
                                             Device.page(params[:page])
                                           when 'CR'
                                             current_user.center.center_devices.page(params[:page])
                                           when 'IA'
                                             current_user.institution.institution_devices.page(params[:page])
                 else
                   current_user.center.center_devices.page(params[:page])
               end
    #@current_user = current_user.role.name
    if request.xhr?
      @move_devices = Device.where("deviceid like ?","%#{params[:q]}%")
    end

    if request.xhr? && params[:q].blank?
      data = DataTable.new(current_user)
      globalSearchParams = params[:search_term]
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], Device.count)
      
      #fetch_records using search paramter
      devices = case @current_user.rc when 'EA'
                                             Device.where("deviceid like :search or mac_id like :search", search: "%#{params[:sSearch]}%")
                                           when 'CR'
                                             @current_user.center.center_devices.where("deviceid like :search or mac_id like :search", search: "%#{params[:sSearch]}%")
                                           when 'IA'
                                             @current_user.institution.institution_devices.where("deviceid like :search or mac_id like :search", search: "%#{params[:sSearch]}%")
                                           else
                                             @current_user.center.center_devices.where("deviceid like :search or mac_id like :search", search: "%#{params[:sSearch]}%")
               end
      #Including Global Search
      devices = devices.where("deviceid like :search or mac_id like :search", search: "%#{globalSearchParams}%")

      devices=devices.includes(users: [:profile], institution: [:profile], center: [:profile])
      devices=devices.joins("inner join profiles InstituteProfile on institution_id=InstituteProfile.user_id")
      devices=devices.joins("inner join profiles CenterProfile on center_id=CenterProfile.user_id")
      total_devices= devices.count
      data.set_total_records(total_devices)
      devices = devices.page(data.page).per(data.per_page)
      
      #fetch_records including sort
      columns = ["deviceid", "mac_id", "model","InstituteProfile.firstname", "CenterProfile.firstname", "status", "device_type"]
      if(params[:iSortCol_0].present?)
        column = columns[params[:iSortCol_0].to_i]
        direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
        devices = devices.order(column +" "+  direction)
      end
      #Mapping records as a hash      
      devices.map!.with_index do |device, index|
        if(device.model)
          model = view_context.link_to(device.model, device_path(device))
        else
          model = ''
        end
        if(device.users.size>4)
          users = device.users.size.to_s + " members"
        else
          users = []
          device.users.each do |user|
            users << view_context.link_to(user.name, user_path(user))
          end
        end
        last_column = []
        last_column << view_context.link_to("Show",device_path(device)) << " "
        last_column << view_context.link_to('Reset', reset_device_device_path(device)) << " "
        last_column << view_context.link_to('Sync' , device_sync_path(device))
        row_class = index%2 == 0 ? "tr-even": "tr-odd"
        {
          "DT_RowId" => "device_#{device.id}",
          "DT_RowClass" => row_class,
          "0"=> device.deviceid,
          "1"=> device.mac_id,
          "2"=> model,
          "3"=> device.institution.try(:name),
          "4"=> device.center.try(:name),
          "5"=> device.status,
          #"6"=> device.device_type,
          "6"=> users,
          "7"=> display_date_time(device.created_at),
          "8"=> view_context.link_to("Show",device_path(device)),
          "9"=> view_context.link_to('Reset', reset_device_device_path(device)),
          "10"=> view_context.link_to('Sync' , device_sync_path(device))
        }
      end
    end

    respond_to do |format|
      format.html 
      #format.json { render json: ::DeviceDatatable.new(view_context, current_user) }
      if request.xhr?
        if params[:q].present?
          format.json { render json: @move_devices.map{|d| Hash[id: d.id,name: d.deviceid]} }
        else
          format.json { render json: data.as_json(devices)}
        end
      else
        format.json { render json: @devices }
      end
    end
  end

  # GET /devices/1
  # GET /devices/1.json
  def show
    @device = Device.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device }
    end
  end

  # GET /devices/new
  # GET /devices/new.json
  def new
    @device = Device.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @device }
    end
  end

  # GET /devices/1/edit
  def edit
    @device = Device.find(params[:id])
  end

  # POST /devices
  # POST /devices.json
  def create
    user_device_token_ids
    @device = Device.new(params[:device])

    respond_to do |format|
      if @device.save
        format.html { redirect_to @device, notice: 'Device was successfully created.' }
        format.json { render json: @device, status: :created, location: @device }
      else
        format.html { render action: "new" }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /devices/1
  # PUT /devices/1.json
  def update
    @device = Device.find(params[:id])
    user_device_token_ids
    respond_to do |format|
      if @device.update_attributes(params[:device])
        format.html { redirect_to @device, notice: 'Device was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /devices/1
  # DELETE /devices/1.json
  def destroy
    @device = Device.find(params[:id])
    @device.update_attribute(:status,Device::DEVICE_STATUS[2])


    respond_to do |format|
      format.html { redirect_to devices_url }
      format.json { head :ok }
    end
  end

  def move_devices

  end

  def user_device_token_ids
    unless params[:device][:user_ids].blank?
      params[:device][:user_ids] = params[:device][:user_ids].split(',')
    end
  end

  def update_devices
    unless params[:institution_id].blank? and params[:center_id].blank?
      if params[:device_tokens].present?
        Device.where(:id=>params[:device_tokens].split(',')).update_all(:institution_id=>params[:institution_id],:center_id=>params[:center_id])
      end
    end
    flash[:notice] = "Devices updated successfully."
    redirect_to devices_path
  end

  def reset_device
    device = Device.find(params[:id])
    device.update_attribute('mac_id', nil) unless device.nil?
    device.update_attribute('android_id', nil) unless device.nil?
    flash[:notice] = "Device updated successfully"
    redirect_to devices_path
  end

  def get_device
    device = nil
    if request.content_type == 'application/json'
      if params[:device][:mac_id].present? and params[:device][:android_id].present? and params[:device][:deviceid].present?
        devices = Device.where(:deviceid=>params[:device][:deviceid],:mac_id=>nil,:android_id=>nil)
        if devices.empty?
          #ignoring mac id
          #todo
          #any_device_with_device_id_or_mac_or_android =  Device.exists?(['deviceid = ? or mac_id=? or android_id =? ',params[:device][:deviceid],params[:device][:mac_id],params[:device][:android_id]])
          any_device_with_device_id_or_mac_or_android =  Device.exists?(['deviceid = ? or android_id =? ',params[:device][:deviceid],params[:device][:android_id]])
          #any_device_with_device_id_and_mac_and_android =  Device.exists?(['deviceid = ? and mac_id=? and android_id =? ',params[:device][:deviceid],params[:device][:mac_id],params[:device][:android_id]])
          any_device_with_device_id_and_mac_and_android =  Device.exists?(['deviceid = ? and android_id =? ',params[:device][:deviceid],params[:device][:android_id]])

          if !any_device_with_device_id_or_mac_or_android and !any_device_with_device_id_and_mac_and_android
            device = Device.new(params[:device])
            if device.save
              @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
              puts "New Device Created"
              logger.info "New Device Created on request from tab."
            else
              @result = {status: :unproecessable_entity,:message=>"Failed to create device",errors: device.errors.full_messages,time: Time.now.to_i}
            end
          end

          if  any_device_with_device_id_and_mac_and_android
            puts "3 Combinations mac and android and device exists.Need to send primary key of device"
            device = Device.find_by_deviceid_and_mac_id_and_android_id(params[:device][:deviceid],params[:device][:mac_id],params[:device][:android_id])
            @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
            logger.info "3 Combinations mac and android and device exists.Need to send primary key of device"
          end

          if !any_device_with_device_id_and_mac_and_android and any_device_with_device_id_or_mac_or_android
            puts "One of the three mac or android or deviceid exists.Need to send -1"
            @result = {device_primarykey_id: -1,status: :ok,time: Time.now.to_i}
            logger.info "One of the three mac or android or deviceid exists.Need to send -1"
          end
        else
          if  !devices.first.nil? and !devices.first.users.empty?
            devices.first.update_attributes(:mac_id=>params[:device][:mac_id],:android_id=>params[:device][:android_id])
            user = devices.first.users.first
            #users = devices.first.users
            institution = user.institution
            center = user.center
            class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
            section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []

            @result = {device_primarykey_id: devices.first.id,:user=>user.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info,time: Time.now.to_i}
            logger.info "JSON ARRAY ======== #{@result}"
          elsif  !devices.first.nil?
            @result = {device_primarykey_id: devices.first.id,status: :ok,time: Time.now.to_i}
          else
            @result = {device_primarykey_id: -2,status: :ok,time: Time.now.to_i}
          end
        end
      else
        @result = {:message=>"Please provide deviceid,mac_id and android_id",time: Time.now.to_i}
      end
    end
    logger.info "result ---- #{@result}"
    #@result = (!device.nil? and device.save) ?  {device_primarykey_id: device.id, status: :ok} : {status: :unprocessable_entity ,message: "Failed to get device id",device_primarykey_id: -1 }
    respond_to do |format|
      format.json {render json: @result}
    end
  end

   def get_device_restore
    mac_id =  params[:device][:mac_id]
    android_id = params[:device][:android_id]
    deviceid = params[:device][:deviceid]

    #@result = {}

    if mac_id.nil?
      @result = {device_primarykey_id: -2,status: :ok,time: Time.now.to_i}
    else
      devices =  Device.where(:mac_id=>mac_id)
      if devices.count  != 1
        @result = {device_primarykey_id: -2,status: :ok,time: Time.now.to_i}
      else
        user = devices.first.users.last
        institution = user.institution
        center = user.center
        class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
        section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
        @result = {deviceid: devices.first.deviceid, device_primarykey_id: devices.first.id,:user=>user.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info,time: Time.now.to_i}
      end
    end
    respond_to do |format|
      format.json {render json: @result}
    end
  end  


   # This method send the sync command to the tab
   def device_sync
     logger.info"========#{request.url}"
     @device = Device.find(params[:id])
     command ="mosquitto_pub -p 3333 -t #{@device.deviceid} -m 12  -i Edeployer -q 2 -h 173.255.254.228"
     system(command)
     flash[:notice] = 'Sync message sent to the tab successfully'
     redirect_to (:back)
   end


end
