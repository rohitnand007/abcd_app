class SessionsController < Devise::SessionsController

  # POST /resource/sign_in
  def create
    unless params[:format].eql?'json'
      resource = warden.authenticate!(auth_options)
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with resource, :location => after_sign_in_path_for(resource)
    else
      #resource = warden.authenticate!(auth_options)
      @result = {}
      #password is bypassing for temporary
      pass = true

      logger.info"=======login_info==========#{params[:user]}"
      if !params[:user][:edutorid].blank?
        resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
        if !resource
          @result = @result.merge({:edutorid_error_message=>'Edutorid not found in the database'})
        end
      else
        @result = @result.merge({:edutorid_error_message=>'edutorid is null'})
      end

      if !params[:user][:password].blank?
        resource = User.find_by_edutorid(params[:user][:edutorid])
        if resource && !resource.valid_password?(params[:user][:password])
          @result = @result.merge({:password_error_message=>'wrong password'})
        end
      else
        @result = @result.merge({:password_error_message=>'password is null'})
      end

      if !params[:user][:deviceid].blank?
        device = Device.find_by_deviceid(params[:user][:deviceid])
        if !device
          @result = @result.merge({:deviceid_error_message=>'Deviceid not found in the database'})
        end
      else
        @result = @result.merge({:deviceid_error_message=>'deviceid is null'})
      end

      if !resource.nil? && !device.nil?
        if (resource.institution_id != device.institution_id)
          @result = @result.merge({:device_move_error_message=>'Device might NOT have been moved !!'})
        end

        if !(resource.user_devices.map(&:device_id).include?(device.id))
          @result = @result.merge({:device_relate_error_message=>'Device and User are not related'})
        end
      end
      #end of bypassing password code
      if pass
        sign_in('user', resource)
        user_devices = resource.devices
        is_primary = false
        is_primary = user_devices.where('deviceid=? and device_type=?',params[:user][:deviceid],'Primary').exists? unless user_devices.empty?


        #check the edutor device in DB
        is_edutor_device_present = Device.find_by_deviceid(params[:user][:deviceid])

        unless is_edutor_device_present.nil?
          #if user has no devices alloted then map this device as primary device
          if user_devices.empty?
            if is_edutor_device_present.users.count >= 300
              sign_out(resource_name)
              @result = @result.merge({sign_in: false,:message=>'Device max user limit exceeded.'})
            else
              if (resource.institution_id == is_edutor_device_present.institution_id) and resource.valid_password?(params[:user][:password])
                resource.device_ids = [is_edutor_device_present.id]
                sign_in(resource_name,resource)
                institution = is_edutor_device_present.institution
                center = is_edutor_device_present.center
                class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
                section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
                @result = @result.merge({is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info})
              end
            end
            #if this device is not primary and user has devices then assign this device as one of the secondary device
          elsif (is_primary == false and !user_devices.empty?)
            if resource && resource.valid_password?(params[:user][:password])
              sign_in(resource_name, resource)
              @result = @result.merge({is_primary: is_primary,sign_in: true,:message=>'Secondary device',is_enrolled: resource.is_enrolled})
            else
              sign_out(resource_name)
              @result = @result.merge({is_primary: nil,sign_in: false,:message=>'Secondary device with wrong password',is_enrolled: resource.is_enrolled})
            end
          elsif is_primary && resource && !resource.valid_password?(params[:user][:password])
            resource.password = params[:user][:password]
            resource.password_confirmation = params[:user][:password]
            resource.save!
            sign_in(resource_name, resource)
            @result = @result.merge({is_primary: is_primary,sign_in: true,:message=>'Primary device',:password_update=>'password updated'})
          elsif is_primary
            sign_in(resource_name, resource)
            current_user = resource
            @result = @result.merge({is_primary: is_primary,sign_in: true,:message=>'Primary device'})
          end
        else
          sign_out(resource_name)
          @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
        end
      end
      respond_to do |format|
        format.json {render json: @result}
      end

    end


  end


  def destroy
    redirect_path = after_sign_out_path_for(resource_name)
    if current_user
      current_user.update_attribute(:last_sign_out_at,Time.now.to_i)
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    end
    set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.any(*navigational_formats) { redirect_to redirect_path }
      format.all do
        head :no_content
      end
    end
  end


  # TODO add json response code

  def new

    respond_to do |format|
      format.html
      format.json {render json: 'login'}
    end
  end

  def set_device(argParams,deviceID)
    device = nil
    success = false
    logger.info"xx=========#{argParams[:device][:mac_id]}"
    logger.info"xx=========#{argParams[:device][:android_id]}"
    logger.info"xx=========#{deviceID}"
    argParams[:device][:deviceid]=deviceID
    logger.info"xx=========#{argParams[:device]}"
    logger.info"xx=========request.content_type#{request.content_type}"
    if !request.content_type.empty?
      if argParams[:device][:mac_id].present? and argParams[:device][:android_id].present? and deviceID.present?
        devices = Device.where(:deviceid=>deviceID,:mac_id=>nil,:android_id=>nil)

        logger.info"xx=============devices#{devices}"
        if devices.empty?
          #ignoring mac id
          #todo
          #any_device_with_device_id_or_mac_or_android =  Device.exists?(['deviceid = ? or mac_id=? or android_id =? ',params[:device][:deviceid],params[:device][:mac_id],params[:device][:android_id]])
          any_device_with_device_id_or_mac_or_android =  Device.exists?(['deviceid = ? or android_id =? ',deviceID,argParams[:device][:android_id]])
          #any_device_with_device_id_and_mac_and_android =  Device.exists?(['deviceid = ? and mac_id=? and android_id =? ',params[:device][:deviceid],params[:device][:mac_id],params[:device][:android_id]])
          any_device_with_device_id_and_mac_and_android =  Device.exists?(['deviceid = ? and android_id =? ',deviceID,argParams[:device][:android_id]])

          logger.info"xx=============any_device_with_device_id_or_mac_or_androidxx#{any_device_with_device_id_or_mac_or_android}"
          logger.info"xx=============any_device_with_device_id_and_mac_and_androidxx#{any_device_with_device_id_and_mac_and_android}"

          if !any_device_with_device_id_or_mac_or_android and !any_device_with_device_id_and_mac_and_android
            device = Device.new(argParams[:device])
            device[:institution_id] = 25607;
            device[:center_id] = 25609;
            logger.info"xx=============xx"
            if device.save
              success = true
              @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
              puts "New Device Created"
              logger.info "New Device Created on request from tab."
            else
              @result = {status: :unproecessable_entity,:message=>"Failed to create device",errors: device.errors.full_messages,time: Time.now.to_i}
            end
          end

          if  any_device_with_device_id_and_mac_and_android
            puts "3 Combinations mac and android and device exists.Need to send primary key of device"
            device = Device.find_by_deviceid_and_mac_id_and_android_id(deviceID,argParams[:device][:mac_id],argParams[:device][:android_id])
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
            devices.first.update_attributes(:mac_id=>argParams[:device][:mac_id],:android_id=>argParams[:device][:android_id])
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
    #@result = (!device.nil? and device.save) ?  {device_primarykey_id: device.id, status: :ok} : {status: :unprocessable_entity ,message: "Failed to get device id",device_primarykey_id: -1 }
    # respond_to do |format|
    #  format.json {render json: @result}
    logger.info"xx=======vivek==========#{@result}"
    logger.info"xx=======vivek==========#{success}"
    if(success)
      return nil;
    else
      return @result;
    end
  end


  def pearson_create
    unless params[:format].eql?'json'
      resource = warden.authenticate!(auth_options)
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with resource, :location => after_sign_in_path_for(resource)
    else
      #resource = warden.authenticate!(auth_options)
      @result = {}
      #password is bypassing for temporary
      pass = true
      logger.info"=======login_info==========#{params[:user]}"
      if !params[:user][:edutorid].blank?
        resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
        if !resource
          @result = @result.merge({:edutorid_error_message=>'Edutorid not found in the database'})
        end
      else
        @result = @result.merge({:edutorid_error_message=>'edutorid is null'})
      end

      if !params[:user][:password].blank?
        resource = User.find_by_edutorid(params[:user][:edutorid])
        if resource && !resource.valid_password?(params[:user][:password])
          @result = @result.merge({:password_error_message=>'wrong password'})
          return @result.to_json
        end
      else
        @result = @result.merge({:password_error_message=>'password is null'})
        return @result.to_json
      end

      if resource.devices.empty?
        logger.info "================resource ===#{resource.devices}"
        logger.info"=======vivek==========#{params[:user][:deviceid]}"
        mDeviceID = "";
        if params[:user][:deviceid].blank? || params[:user][:deviceid].nil?
          devices = Device.where(:mac_id=>params[:device][:mac_id])
          if !devices.empty?
            mDeviceID = devices[0].deviceid
          else
            mDeviceID = "PSA"+get_device_id_sa;
            @myReturn = set_device(params,mDeviceID)
            logger.info"=======vivek==========#{@myReturn}"
            if(!(@myReturn.nil? || @myReturn.empty? ))
              @result = @myReturn
              mDeviceID = nil;
            else
              resource.device_ids = [mDeviceID]
            end
          end
        end
      elsif resource.devices.first.mac_id != params[:device][:mac_id]
        logger.info "=#{params[:device][:mac_id]}"
        logger.info "=#{resource.devices.first.mac_id}"
        @result = @result.merge({:macid_error_message=>'Invalid Mac id'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
      else
        mDeviceID = resource.devices.first.deviceid
      end
      if !mDeviceID.blank?
        device = Device.find_by_deviceid(mDeviceID)
        if !device
          @result = @result.merge({:deviceid_error_message=>'Deviceid not found in the database'})
        end
      else
        @result = @result.merge({:deviceid_error_message=>'deviceid is null'})
      end

      if !resource.nil? && !device.nil?
        if (resource.institution_id != device.institution_id)
          @result = @result.merge({:device_move_error_message=>'Device might NOT have been moved !!'})
        end

        if !(resource.user_devices.map(&:device_id).include?(device.id))
          @result = @result.merge({:device_relate_error_message=>'Device and User are not related'})
        end
      end
      #end of bypassing password code
      if pass
        sign_in('user', resource)
        user_devices = resource.devices
        is_primary = false
        is_primary = user_devices.where('deviceid=? and device_type=?',mDeviceID,'Primary').exists? unless user_devices.empty?


        #check the edutor device in DB
        is_edutor_device_present = Device.find_by_deviceid(mDeviceID)

        unless is_edutor_device_present.nil?
          #if user has no devices alloted then map this device as primary device
          if true
            if is_edutor_device_present.users.count >= 300
              sign_out(resource_name)
              @result = @result.merge({sign_in: false,:message=>'Device max user limit exceeded.'})
            else
              if (resource.institution_id == is_edutor_device_present.institution_id) and resource.valid_password?(params[:user][:password])
                resource.device_ids = [is_edutor_device_present.id]
                sign_in(resource_name,resource)
                institution = is_edutor_device_present.institution
                center = is_edutor_device_present.center
                class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
                section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
                @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info})
              end
            end
            #if this device is not primary and user has devices then assign this device as one of the secondary device
          elsif (is_primary == false and !user_devices.empty?)
            if resource && resource.valid_password?(params[:user][:password])
              sign_in(resource_name, resource)
              @result = @result.merge({device_id:mDeviceID,is_primary: is_primary,sign_in: true,:message=>'Secondary device',is_enrolled: resource.is_enrolled})
            else
              sign_out(resource_name)
              @result = @result.merge({device_id:mDeviceID,is_primary: nil,sign_in: false,:message=>'Secondary device with wrong password',is_enrolled: resource.is_enrolled})
            end
          elsif is_primary && resource && !resource.valid_password?(params[:user][:password])
            resource.password = params[:user][:password]
            resource.password_confirmation = params[:user][:password]
            resource.save!
            sign_in(resource_name, resource)
            @result = @result.merge({device_id:mDeviceID,is_primary: is_primary,sign_in: true,:message=>'Primary device',:password_update=>'password updated'})
          elsif is_primary
            sign_in(resource_name, resource)
            current_user = resource
            @result = @result.merge({device_id:mDeviceID,is_primary: is_primary,sign_in: true,:message=>'Primary device'})
          end
        else
          sign_out(resource_name)
          @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
        end
      end
      respond_to do |format|
        format.json {render json: @result}
      end
    end
  end


  def get_device_id_sa
    p = GetDeviceId.new
    p.save
    q = GetDeviceId.last[:id]
    logger.info"=======vivek==========aaaaaaaaaaaa#{q}"
    q = q.to_s.rjust(10,'0')
    logger.info"=======vivek==========#{q}"
    return q
  end


end
