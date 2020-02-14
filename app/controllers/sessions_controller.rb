class SessionsController < Devise::SessionsController

  # POST /resource/sign_in
  def create
    unless params[:format].eql?'json'
      resource = warden.authenticate!(auth_options)
      #set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with resource, :location => after_sign_in_path_for(resource)
    else
      #resource = warden.authenticate!(auth_options)
      @result = {}
      #password is bypassing for temporary
      pass = true
      #-----Code for checking login info just with edutorid and password
      # if params[:user][:edutorid].present? && params[:user][:password].present?
      #   resource = User.find_by_edutorid(params[:user][:edutorid])
      #   if resource.valid_password?(params[:user][:password])
      #     sign_in(resource_name, resource)
      #   else
      #     @result = @result.merge({:edutorid_error_message=>'wrong password'})
      #   end
      # else
      #   @result = @result.merge({:edutorid_error_message=>'Edutorid not found in the database'})
      # end
      #------code ends here
      logger.info"=======login_info==========#{params[:user]}"
      if !params[:user][:edutorid].blank?
        resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
        if resource.nil?
          @result = @result.merge({is_primary: nil,sign_in: false,:edutorid_error_message=>'Edutorid not found in the database'})
          respond_to do |format|
            format.json {render json: @result}
          end
          return
        end
      else
        @result = @result.merge({:edutorid_error_message=>'edutorid is null'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
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
        device = nil
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
      #if pass
      #sign_in('user', resource)
      user_devices = resource.devices

      if user_devices.empty?
        is_primary = false
      else
        is_primary = true
      end
      #is_primary = user_devices.where('deviceid=? and device_type=?',params[:user][:deviceid],'Primary').exists? unless user_devices.empty?


      #check the edutor device in DB
      #is_edutor_device_present = Device.find_by_deviceid(params[:user][:deviceid])
      is_edutor_device_present = device

      unless is_edutor_device_present.nil?
        #if user has no devices alloted then map this device as primary device
        if user_devices.empty?
          if is_edutor_device_present.users.count >= 300
            #sign_out(resource_name)
            @result = @result.merge({sign_in: false,:message=>'Device max user limit exceeded.'})
          else
            if (resource.institution_id == is_edutor_device_present.institution_id) and resource.valid_password?(params[:user][:password])
              resource.device_ids = [is_edutor_device_present.id]
              sign_in(resource_name,resource)
              institution = is_edutor_device_present.institution
              center = is_edutor_device_present.center
              class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
              section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
              @result = @result.merge({is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
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
          #current_user = resource
          @result = @result.merge({is_primary: is_primary,sign_in: true,:message=>'Primary device'})
        end
      else
        sign_out(resource_name)
        @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
      end
      #end
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
    flag = false
    if !cookies['_auth_name'].nil?
      cookies.delete '_auth_name'
      cookies.delete '_auth_ses'
      flag = true
    end

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      if flag
        #format.html {redirect_to 'https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/logout?post_logout_redirect_uri=http%3A%2F%2Flocalhost%3A3000'}
        #format.html {redirect_to 'https://login.microsoftonline.com/b17428d7-01b4-4dfc-bb98-9eca1ace67a5/oauth2/logout?post_logout_redirect_uri=http%3A%2F%2Fportal.myedutor.com'}
        format.html {redirect_to 'https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/logout?post_logout_redirect_uri=http%3A%2F%2Fportal.myedutor.com'}
      else
        format.any(*navigational_formats) { redirect_to redirect_path }
        format.all do
          head :no_content
        end
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

  def pearson_create

    @result = {}
    logger.info"=======login_info==========#{params[:user]}"
    #resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
    name_user = params[:user][:edutorid].gsub(/ES-/, "")
    if !User.find_by_edutorid(params[:user][:edutorid]).nil?
      resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
    elsif !User.where("users.institution_id = 25607 and rollno = '#{name_user}'").empty?
      resource = User.includes(:profile,:devices).where("users.institution_id = 25607 and rollno = '#{name_user}'").first
    elsif !Profile.includes(:user).where("users.institution_id = 25607 and web_screen_name = '#{name_user}'").empty?
      screen_name_id = Profile.includes(:user).where("users.institution_id = 25607 and web_screen_name = '#{name_user}'").first.user_id
      resource = User.includes(:profile,:devices).find(screen_name_id)
    end
    mDeviceID = ""

    if !params[:user][:edutorid].blank?
      if !resource
        @result = @result.merge({sign_in: false,:edutorid_error_message=>'Edutorid not found in the database',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
      end
    else
      @result = @result.merge({sign_in: false,:edutorid_error_message=>'edutorid is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    if !params[:user][:password].blank?
      if resource && !resource.valid_password?(params[:user][:password])
        @result = @result.merge({sign_in: false,:password_error_message=>'wrong password',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
        #return @result.to_json
      end
    else
      @result = @result.merge({sign_in: false,:password_error_message=>'password is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end


    if  (resource.devices.count >= 3) and !resource.devices.map(&:mac_id).include? (params[:device][:mac_id])
      @result = @result.merge({sign_in: false,:message=>'Maximum devices'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    elsif resource.devices.count <= 2 or resource.devices.map(&:mac_id).include? (params[:device][:mac_id])
      devices = Device.where(:mac_id=>params[:device][:mac_id])
      if !devices.empty?
        if resource.devices.map(&:deviceid).include? (devices.last.deviceid)  or devices.first.users.empty?
          mDeviceID = devices.last.deviceid
          @myReturn = set_device(resource,params,mDeviceID)
        else
          @result = @result.merge({sign_in: false,:message=>"Device already assigned to other user-- #{devices.first.users.first.edutorid}"})
          respond_to do |format|
            format.json {render json: @result}
          end
          return
        end
      else
        mDeviceID = "PSA"+get_device_id_sa;
        @myReturn = set_device(resource,params,mDeviceID)
      end
    else
      logger.info"--- check this scenario ---"
    end


    device = Device.find_by_deviceid(mDeviceID)
    if !mDeviceID.nil?

      if !device
        @result = @result.merge({sign_in: false,:deviceid_error_message=>'Deviceid not found in the database',:message=>'Deviceid not found in the database'})
      end
    else
      @result = @result.merge({sign_in: false,:deviceid_error_message=>'deviceid is null',:message=>'deviceid is null'})
    end

    if !resource.nil? && !device.nil?
      if (resource.institution_id != device.institution_id)
        @result = @result.merge({sign_in: false,:device_move_error_message=>'Device might NOT have been moved !!',:message=>'Device might NOT have been moved !!'})
      end
    end


    unless device.nil?
      if (resource.institution_id == device.institution_id) and resource.valid_password?(params[:user][:password])
        sign_in(resource_name,resource)
        institution = device.institution
        center = device.center
        class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
        section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
        @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
      end
    else
      sign_out(resource_name)
      @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
    end

    respond_to do |format|
      format.json {render json: @result}
    end
  end



  def set_device(user,argParams,deviceID)
    device = nil
    device_info = JSON.load(argParams[:device][:info])
    argParams[:device][:deviceid]=deviceID

    if !request.content_type.empty?
      if argParams[:device][:mac_id].present? and argParams[:device][:android_id].present? and deviceID.present?
        devices = Device.where(:deviceid=>deviceID,:mac_id=>argParams[:device][:mac_id])

        if devices.empty?
          device = Device.new(argParams[:device])
          old_device_property = DeviceProperty.where(:mac_id => device_info['mac_id']);
          if old_device_property.empty?
            device_property = DeviceProperty.new(device_info)
          else
            device_property = old_device_property.first
          end
          device[:institution_id] = user.institution_id
          device[:center_id] = user.center_id
          device[:device_type]= 'Primary'
          device[:status]= 'Assigned'
          if device.save  and device_property.save
            DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)
            user.user_devices.create(:device_id=>device.id)
            #DeviceProperty.create()
            @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
            puts "New Device Created"
            logger.info "New Device Created on request from tab."
          else
            @result = {status: :unprocessable_entity,:message=>"Failed to create device",errors: device.errors.full_messages,time: Time.now.to_i}
          end


        else
          if  !devices.first.nil? and !devices.first.users.empty?
            device = devices.first
            n_user = devices.first.users.first
            if user.id == n_user.id
              old_device_property = DeviceProperty.where(:mac_id => device_info['mac_id']);
              if old_device_property.empty?
                device_property = DeviceProperty.create(device_info)
              else
                device_property = old_device_property.first
              end
              DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)

              @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
              logger.info"---Same user re-registered, device_property created--- "
            else
              old_device_property = DeviceProperty.where(:mac_id => device_info['mac_id']);
              if old_device_property.empty?
                device_property = DeviceProperty.create(device_info)
              else
                device_property = old_device_property.first
              end
              device_user_info = DeviceInfo.where(:user_id=>n_user.id,:device_id=>device.id,:device_property_id=>device_property.id)
              if !device_user_info.empty?
                device_user_info.first.update_attribute(:user_id,user.id)
              else
                DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)
              end
              user.user_devices.create(:device_id => device.id)
              @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
              logger.info"--- Different user took over a occupied tab --- device_property, device_info and user_devices created"
            end
          elsif devices.first.users.empty?
            device = devices.first
            old_device_property = DeviceProperty.where(:mac_id => device_info['mac_id']);
            if old_device_property.empty?
              device_property = DeviceProperty.create(device_info)
            else
              device_property = old_device_property.first
            end
            DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)
            user.user_devices.create(:device_id => device.id)
            @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
            logger.info"--- Different user took over a existing but not occupied tab ---"
          end
        end
      else
        @result = {:message=>"Please provide deviceid, mac_id and android_id",time: Time.now.to_i}
      end
    end

    logger.info"xx=======vivek==========#{@result}"
  end


  def get_device_id_sa
    p = GetDeviceId.new
    p.save
    #q = GetDeviceId.last[:id]
    p = p.id.to_s.rjust(10,'0')
    return p
  end


  def user_registration

    @result = {}
    logger.info"=======login_info==========#{params[:user]}"
    #resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
    if params[:user][:edutorid].blank?
      @result = @result.merge({sign_in: false,:edutorid_error_message=>'Edutorid not found in the database',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end
    name_user = params[:user][:edutorid].gsub(/ES-/, "")
    if !User.find_by_edutorid(params[:user][:edutorid]).nil?
      resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
    elsif !User.where("email = '#{name_user}'").empty?
      resource = User.includes(:profile,:devices).where("email = '#{name_user}'").first
    elsif !User.where("rollno = '#{name_user}'").empty?
      resource = User.includes(:profile,:devices).where("rollno = '#{name_user}'").first
    elsif !Profile.includes(:user).where("web_screen_name = '#{name_user}'").empty?
      screen_name_id = Profile.includes(:user).where("web_screen_name = '#{name_user}'").first.user_id
      resource = User.includes(:profile,:devices).find(screen_name_id)
    end

    mDeviceID = ""

    if !params[:user][:edutorid].blank?
      if !resource
        @result = @result.merge({sign_in: false,:edutorid_error_message=>'Edutorid not found in the database',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
      end
    else
      @result = @result.merge({sign_in: false,:edutorid_error_message=>'edutorid is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    if !params[:user][:password].blank?
      if resource && !resource.valid_password?(params[:user][:password])
        @result = @result.merge({sign_in: false,:password_error_message=>'wrong password',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
        #return @result.to_json
      end
    else
      @result = @result.merge({sign_in: false,:password_error_message=>'password is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    @device_count = resource.institution.user_configuration.devices_per_user

    if  (resource.devices.uniq.count >= @device_count) and !resource.devices.map(&:mac_id).include? (params[:device][:mac_id])
      @result = @result.merge({sign_in: false,:message=>'Maximum devices'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    elsif resource.devices.count < @device_count or resource.devices.map(&:mac_id).include? (params[:device][:mac_id])
      devices = Device.where(:mac_id=>params[:device][:mac_id])
      if !devices.empty?
        if resource.devices.map(&:deviceid).include? (devices.last.deviceid)  or devices.first.users.empty?
          mDeviceID = devices.last.deviceid
          @myReturn = set_device_ignitor(resource,params,mDeviceID)
        elsif resource.institution_id == 167367
          mDeviceID = devices.last.deviceid
          @myReturn = set_device_ignitor(resource,params,mDeviceID)
        else
          @result = @result.merge({sign_in: false,:message=>"Device already assigned to other user -- #{devices.first.users.first.edutorid}"})
          respond_to do |format|
            format.json {render json: @result}
          end
          return
        end
      else
        mDeviceID = "ES"+get_device_id_sa;
        @myReturn = set_device_ignitor(resource,params,mDeviceID)
      end
    else
      logger.info"--- check this scenario ---"
    end


    device = Device.find_by_deviceid(mDeviceID)
    if !mDeviceID.nil?

      if !device
        @result = @result.merge({sign_in: false,:deviceid_error_message=>'Deviceid not found in the database',:message=>'Deviceid not found in the database'})
      end
    else
      @result = @result.merge({sign_in: false,:deviceid_error_message=>'deviceid is null',:message=>'deviceid is null'})
    end
    #Skiped the condition for bookden users
    if resource.institution_id != 167367
      if !resource.nil? && !device.nil?
        if (resource.institution_id != device.institution_id)
          @result = @result.merge({sign_in: false,:device_move_error_message=>'Device might NOT have been moved !!',:message=>'Device might NOT have been moved !!'})
        end
      end
    end

    unless device.nil?
      # if (resource.institution_id == device.institution_id) and resource.valid_password?(params[:user][:password])
      sign_in(resource_name,resource)
      institution = resource.institution
      center = resource.center
      unless resource.rc == "EO"
        class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
        section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
        @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
      else
          center = institution.centers.first
          class_obj = center.academic_classes.first
          section_obj = class_obj.sections.first
          class_info = [Hash[class: class_obj.as_json(:include=>:profile)]] rescue []
          section_info = [Hash[section: section_obj.as_json(:include=>:profile)]]  rescue []
          resource_json = resource.as_json(:include => :profile).merge({"academic_class_id"=>class_obj.id, "section_id"=>section_obj.id})
          @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource_json,institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
      end
      # end
    else
      sign_out(resource_name)
      @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
    end
    #    logger.info"xx=======vivekkkkkkkkkkkkkk==========#{@result}"

    respond_to do |format|
      format.json {render json: @result}
    end
  end

  def set_device_ignitor(user,argParams,deviceID)
    device = nil
    device_info = JSON.load(argParams[:device][:info])
    argParams[:device][:deviceid]=deviceID

    #if !request.content_type.empty?
      if argParams[:device][:mac_id].present? and argParams[:device][:android_id].present? and deviceID.present?
        devices = Device.where(:deviceid=>deviceID,:mac_id=>argParams[:device][:mac_id])

        if devices.empty?
          device = Device.new(argParams[:device])
          old_device_property = DevicePropertyIgnitor.where(:mac_id => device_info['mac_id']);
          if old_device_property.empty?
            device_property = DevicePropertyIgnitor.new(device_info)
          else
            device_property = old_device_property.first
          end
          device[:institution_id] = user.institution_id
          device[:center_id] = user.center_id
          device[:device_type]= 'Primary'
          device[:status]= 'Assigned'
          if device.save  and device_property.save
            DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)
            if !user.devices.pluck(:deviceid).include? device.deviceid
              user.user_devices.create(:device_id => device.id)
            end
            #DeviceProperty.create()
            @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
            puts "New Device Created"
            logger.info "New Device Created on request from tab."
          else
            @result = {status: :unprocessable_entity,:message=>"Failed to create device",errors: device.errors.full_messages,time: Time.now.to_i}
          end


        else
          if  !devices.first.nil? and !devices.first.users.empty?
            device = devices.first
            n_user = devices.first.users.first
            if user.id == n_user.id
              old_device_property = DevicePropertyIgnitor.where(:mac_id => device_info['mac_id']);
              if old_device_property.empty?
                device_property = DevicePropertyIgnitor.create(device_info)
              else
                device_property = old_device_property.first
              end
              DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)

              @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
              logger.info"---Same user re-registered, device_property created--- "
            else
              old_device_property = DevicePropertyIgnitor.where(:mac_id => device_info['mac_id']);
              if old_device_property.empty?
                device_property = DevicePropertyIgnitor.create(device_info)
              else
                device_property = old_device_property.first
              end
              device_user_info = DeviceInfo.where(:user_id=>n_user.id,:device_id=>device.id,:device_property_id=>device_property.id)
              if !device_user_info.empty?
                device_user_info.first.update_attribute(:user_id,user.id)
              else
                DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)
              end
              if !user.devices.pluck(:deviceid).include? device.deviceid
                user.user_devices.create(:device_id => device.id)
              end
              @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
              logger.info"--- Different user took over a occupied tab --- device_property, device_info and user_devices created"
            end
          elsif devices.first.users.empty?
            device = devices.first
            old_device_property = DevicePropertyIgnitor.where(:mac_id => device_info['mac_id']);
            if old_device_property.empty?
              device_property = DevicePropertyIgnitor.create(device_info)
            else
              device_property = old_device_property.first
            end
            DeviceInfo.create(:user_id=>user.id,:device_id=>device.id,:device_property_id=>device_property.id)
            if !user.devices.pluck(:deviceid).include? device.deviceid
              user.user_devices.create(:device_id => device.id)
            end
            @result = {device_primarykey_id: device.id,status: :ok,time: Time.now.to_i}
            logger.info"--- Different user took over a existing but not occupied tab ---"
          end
        end
      else
        @result = {:message=>"Please provide deviceid, mac_id and android_id",time: Time.now.to_i}
      end
    #end

    #logger.info"xx=======vivek==========#{@result}"
  end

  # New registraton method for ap gov multiple user login on a device.
  def ap_user_registration

    @result = {}
    #logger.info"===AP====login_info==========#{params[:user]}"
    #resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
    name_user = params[:user][:edutorid].gsub(/ES-/, "")
    if !User.find_by_edutorid(params[:user][:edutorid]).nil?
      resource = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
    elsif !User.where("rollno = '#{name_user}'").empty?
      resource = User.includes(:profile,:devices).where("rollno = '#{name_user}'").first
    elsif !Profile.includes(:user).where("web_screen_name = '#{name_user}'").empty?
      screen_name_id = Profile.includes(:user).where("web_screen_name = '#{name_user}'").first.user_id
      resource = User.includes(:profile,:devices).find(screen_name_id)
    end

    mDeviceID = ""

    if !params[:user][:edutorid].blank?
      if !resource
        @result = @result.merge({sign_in: false,:edutorid_error_message=>'Edutorid not found in the database',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
      end
    else
      @result = @result.merge({sign_in: false,:edutorid_error_message=>'edutorid is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    if !params[:user][:password].blank?
      if resource && !resource.valid_password?(params[:user][:password])
        @result = @result.merge({sign_in: false,:password_error_message=>'wrong password',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
        #return @result.to_json
      end
    else
      @result = @result.merge({sign_in: false,:password_error_message=>'password is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    devices = Device.where(:mac_id=>params[:device][:mac_id])
    if !devices.empty?
      mDeviceID = devices.last.deviceid
    else
      mDeviceID = "ES"+get_device_id_sa;
      @myReturn = set_device_ignitor(resource,params,mDeviceID)
    end


    if !mDeviceID.nil?
      device = Device.find_by_deviceid(mDeviceID)
      if device.nil?
        @result = @result.merge({sign_in: false,:deviceid_error_message=>'Deviceid not found in the database',:message=>'Deviceid not found in the database'})
      end
    else
      @result = @result.merge({sign_in: false,:deviceid_error_message=>'deviceid is null',:message=>'deviceid is null'})
    end


    unless device.nil?
      if resource.valid_password?(params[:user][:password])
        sign_in(resource_name,resource)
        institution = resource.institution
        center = resource.center
        class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
        section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
        @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
      end
    else
      sign_out(resource_name)
      @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
    end
    logger.info"=======AP-result==========#{@result}"

    respond_to do |format|
      format.json {render json: @result}
    end
  end

  # New registraton method for windows office 365 sending emailid insted of edutorid and password
  def office365_demo_user_registration

    @result = {}

    resource = User.includes(:profile,:devices).find_by_email(params[:user][:email_id])

    if resource.nil?
      @result = @result.merge({sign_in: false,:edutorid_error_message=>'Email not found in the database',:message=>'Invalid emailid, enter correct Emailid'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    mDeviceID = ""

    @device_count = resource.institution.user_configuration.devices_per_user

    if  (resource.devices.count >= @device_count) and !resource.devices.map(&:mac_id).include? (params[:device][:mac_id])
      @result = @result.merge({sign_in: false,:message=>'Maximum devices'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    elsif resource.devices.count < @device_count or resource.devices.map(&:mac_id).include? (params[:device][:mac_id])
      devices = Device.where(:mac_id=>params[:device][:mac_id])
      if !devices.empty?
        if resource.devices.map(&:deviceid).include? (devices.last.deviceid)  or devices.first.users.empty?
          mDeviceID = devices.last.deviceid
          @myReturn = set_device_ignitor(resource,params,mDeviceID)
        else
          @result = @result.merge({sign_in: false,:message=>"Device already assigned to other user -- #{devices.first.users.first.edutorid}"})
          respond_to do |format|
            format.json {render json: @result}
          end
          return
        end
      else
        mDeviceID = "ES"+get_device_id_sa;
        @myReturn = set_device_ignitor(resource,params,mDeviceID)
      end
    else
      logger.info"--- check this scenario ---"
    end

    device = Device.find_by_deviceid(mDeviceID)

    if !device
      @result = @result.merge({sign_in: false,:deviceid_error_message=>'Deviceid not found in the database',:message=>'Deviceid not found in the database'})
    else
      @result = @result.merge({sign_in: false,:deviceid_error_message=>'deviceid is null',:message=>'deviceid is null'})
    end

    if !resource.nil? && !device.nil?
      if (resource.institution_id != device.institution_id)
        @result = @result.merge({sign_in: false,:device_move_error_message=>'Device might NOT have been moved !!',:message=>'Device might NOT have been moved !!'})
      end
    end
    unless device.nil?
      if (resource.institution_id == device.institution_id) and true #resource.valid_password?(params[:user][:password])
        sign_in(resource_name,resource)
        institution = resource.institution
        center = resource.center
        class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
        section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
        @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>resource.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
      end
    else
      sign_out(resource_name)
      @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
    end
    respond_to do |format|
      format.json {render json: @result}
    end
  end

  def onenote_demo_user_registration

    @result = {}

    unless params[:user][:email_id].blank?

      @user = User.includes(:profile,:devices).find_by_email(params[:user][:email_id])

      if @user.nil?
        @user = User.new
        @user_profile = @user.build_profile
        @user.rollno = params[:user][:email_id]
        @user.institution_id = 130120
        @user.center_id = 130122
        @user.academic_class_id = 130124
        @user.section_id = 130125
        @user.email = params[:user][:email_id]
        @user.password = 4123
        @user.role_id = 4
        @user_profile.firstname = params[:user][:email_id].split("@").first
        @user.save
      end

      # @license_set = LicenseSet.find(1573)
      # @license_set.users << @user unless @license_set.users.include?(@user)

      @devices = Device.where(:mac_id=>params[:device][:mac_id])
      if !@devices.empty?
        mDeviceID = @devices.last.deviceid
        @myReturn = set_device_ignitor(@user,params,mDeviceID)
        @device = @devices.last
      else
        mDeviceID = "ES"+get_device_id_sa;
        @myReturn = set_device_ignitor(@user,params,mDeviceID)
        @device = Device.find_by_deviceid(mDeviceID)
      end

      unless @device.nil?
        sign_in(resource_name,@user)
        institution = @user.institution
        center = @user.center
        class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
        section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
        @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>@user.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
      end
    else
      @result = @result.merge({is_primary: nil,sign_in: false,:message=>'Email is blank'})
    end
    respond_to do |format|
      format.json {render json: @result}
    end
  end



  def app_user_device_registration

    @result = {}
    if params[:user][:edutorid].blank?
      @result = @result.merge({sign_in: false,:edutorid_error_message=>'Edutorid not found in the database',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    # checking the params[:user][:edutorid] have email id
    if params[:user][:edutorid].match(/\A[^@]+@([^@\.]+\.)+[^@\.]+\z/).nil?
      @user = User.includes(:profile,:devices).find_by_edutorid(params[:user][:edutorid])
    else
      @user = User.includes(:profile,:devices).where("users.email=? and users.institution_id=?",params[:user][:edutorid],params[:user][:inst]).first
    end


    if !params[:user][:edutorid].blank?
      if !@user
        @result = @result.merge({sign_in: false,:edutorid_error_message=>'Edutorid not found in the database',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
      end
    else
      @result = @result.merge({sign_in: false,:edutorid_error_message=>'edutorid is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end

    unless params[:user][:via].present?
    if !params[:user][:password].blank?
      if @user && !@user.valid_password?(params[:user][:password])
        @result = @result.merge({sign_in: false,:password_error_message=>'wrong password',:message=>'Invalid userid/password, enter correct userid/password'})
        respond_to do |format|
          format.json {render json: @result}
        end
        return
      end
    else
      @result = @result.merge({sign_in: false,:password_error_message=>'password is null',:message=>'Invalid userid/password, enter correct userid/password'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    end
    end

    @device_count = @user.institution.user_configuration.devices_per_user

    if (@user.devices.size >= @device_count) and !@user.devices.map(&:mac_id).include? (params[:device][:mac_id])
      @result = @result.merge({sign_in: false,:message=>'Maximum devices'})
      respond_to do |format|
        format.json {render json: @result}
      end
      return
    else
      @devices = Device.where(:mac_id=>params[:device][:mac_id])
      if !@devices.empty?
        @mDeviceID = @devices.last.deviceid
        set_device_ignitor(@user,params,@mDeviceID)
      else
        @mDeviceID = "ES"+get_device_id_sa;
        set_device_ignitor(@user,params,@mDeviceID)
      end
    end

    @device = Device.find_by_deviceid(@mDeviceID)

    unless @device.nil?
      sign_in(resource_name,@user)
      institution = @user.institution
      center = @user.center
      class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
      section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
      @result = @result.merge({device_id:@mDeviceID,sign_in:true,is_primary:true,:message=>'Alloted this device as primary',:user=>@user.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
    else
      sign_out(@user)
      @result = @result.merge({is_primary: nil,sign_in: false,:message=>'No device found in edutor list'})
    end

    respond_to do |format|
      format.json {render json: @result}
    end
  end



  def onenote_demo_store_user_registration

    @result = {}

    unless params[:user][:email_id].blank?

      @user = User.includes(:profile,:devices).find_by_email(params[:user][:email_id])

      if @user.nil?
        @user = User.new
        @user_profile = @user.build_profile
        @user.rollno = params[:user][:email_id]
        @user.institution_id = 60688
        @user.center_id = 60690
        @user.academic_class_id = 60692
        @user.section_id = 60693
        @user.email = params[:user][:email_id]
        @user.password = 4123
        @user.role_id = 4
        @user_profile.firstname = params[:user][:email_id].split("@").first
        @user.save
      end

      # @license_set = LicenseSet.find(1573)
      # @license_set.users << @user unless @license_set.users.include?(@user)

      @devices = Device.where(:mac_id=>params[:device][:mac_id])
      if !@devices.empty?
        mDeviceID = @devices.last.deviceid
        @myReturn = set_device_ignitor(@user,params,mDeviceID)
        @device = @devices.last
      else
        mDeviceID = "ES"+get_device_id_sa;
        @myReturn = set_device_ignitor(@user,params,mDeviceID)
        @device = Device.find_by_deviceid(mDeviceID)
      end

      unless @device.nil?
        sign_in(resource_name,@user)
        institution = @user.institution
        center = @user.center
        class_info = center.academic_classes.any? ? center.academic_classes.map{|ac_class| Hash[class: ac_class.as_json(:include=>:profile)] } : []
        section_info = center.sections.any? ? center.sections.map{|section| Hash[section: section.as_json(:include=>:profile)] }  : []
        @result = @result.merge({device_id:mDeviceID,is_primary: true,sign_in: true,:message=>'Alloted this device as primary',:user=>@user.as_json(:include => :profile),institution: institution.as_json(:include=>:profile),center: center.as_json(:include=>:profile),class_arry: class_info,sections_arry: section_info, store_url:current_user.get_store_url.present?, authentication_token: current_user.authentication_token})
      end
    else
      @result = @result.merge({is_primary: nil,sign_in: false,:message=>'Email is blank'})
    end
    respond_to do |format|
      format.json {render json: @result}
    end
  end


end
