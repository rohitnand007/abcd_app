class DrmDrmPowerChipsController < ApplicationController
  # load_and_authorize_resource
  # Remove the check to make a open url
  #skip_before_filter :authenticate_user!, :only=>:get_license
  # GET /power_chips
  # GET /power_chips.json
  def index
    @power_chips = DrmPowerChip.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @power_chips }
    end
  end

  # GET /power_chips/1
  # GET /power_chips/1.json
  def show
    @power_chip = DrmPowerChip.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @power_chip }
    end
  end

  # GET /power_chips/new
  # GET /power_chips/new.json
  def new
    @power_chip = DrmPowerChip.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @power_chip }
    end
  end

  # GET /power_chips/1/edit
  def edit
    @power_chip = DrmPowerChip.find(params[:id])
  end

  # POST /power_chips
  # POST /power_chips.json
  def create
    @power_chip = DrmPowerChip.new(params[:power_chip])

    respond_to do |format|
      if @power_chip.save
        format.html { redirect_to @power_chip, notice: 'Power chip was successfully created.' }
        format.json { render json: @power_chip, status: :created, location: @power_chip }
      else
        format.html { render action: "new" }
        format.json { render json: @power_chip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /power_chips/1
  # PUT /power_chips/1.json
  def update
    @power_chip = DrmPowerChip.find(params[:id])

    respond_to do |format|
      if @power_chip.update_attributes(params[:power_chip])
        format.html { redirect_to @power_chip, notice: 'Power chip was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @power_chip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /power_chips/1
  # DELETE /power_chips/1.json
  def destroy
    @power_chip = DrmPowerChip.find(params[:id])
    @power_chip.destroy

    respond_to do |format|
      format.html { redirect_to power_chips_url }
      format.json { head :ok }
    end
  end

  # This method listens to the request from the user
  def get_license
    # Reading the request from the tab
    string = request.body.read
    # Data for testing
    #string = '[{"deviceId":"E010312204099","powerChipId":"PC_0002501","userId":"ES-0994"}]'
    power_chip_request =  ActiveSupport::JSON.decode(string)

    # The array to be returned with the license
    @power_chip_contents = []

    # Getting the license for each request
    power_chip_request.each do |request|
      content = Hash.new
      content["isValid"] = 'FALSE'
      content["errorMessage"] = ''

      # Checking if the request is valid or not

      # Check if device id is present in the request
      if !request['deviceId'].blank?
        deviceId = request['deviceId']
        # Check if powerchip id is present in the request
        if !request['powerChipId'].blank?
          powerChipId = request['powerChipId']
          # Check if user id is present in the request
           if !request['userId'].blank?
             userId = request['userId']
           else
             userId = 0
           end

          # Getting the License for the power chip and the device

          # Checking if the device is already present in the database
          devices = Device.where(:deviceid=>deviceId)
          if devices.length > 0
            # Checking if the chip is already present in the database
            chips = Chip.where(:chipid=>powerChipId)
            if chips.length > 0
              # TODO: Currently only checking if a Power Chip entry is present for the Chip
              power_chips = DrmPowerChip.where(:powerchipid=>powerChipId)
              if power_chips.length > 0
                # Handling the case when the power chip entry is already present in the database
                power_chips.each do |entry|
                  if entry.device_id == deviceId
                    content["isValid"] = "TRUE"
                    content["data"] = DrmPowerChip.find(entry.id)
                    break
                  end
                end

                if content["isValid"] == "FALSE"
                  content["errorMessage"] = "Please use the device assigned to the chip to get the license"
                end

              else
                # The user inserted the chip for the first time have to make an entry with the power chip id and the device id
                power_chip_row = DrmPowerChip.new
                power_chip_row.powerchipid = powerChipId
                power_chip_row.device_id = deviceId
                power_chip_row.user_id = userId
                if power_chip_row.save
                  # Entry for the power chip and device are created now getting the license from the publisher
                  license_created = update_license_key(power_chip_row.id)
                  if license_created
                    content["isValid"] = "TRUE"
                    content["data"] = DrmPowerChip.find(power_chip_row.id)
                  else
                    content["errorMessage"] = "An error occured in getting the license from the publisher"
                  end

                else
                  content["errorMessage"] = "An error occured in creating the license"
                end
              end

                  else
              content["errorMessage"] = "The Chip Id you requested is invalid"
            end

          else
            content["errorMessage"] = "The Device Id you requested is invalid"
          end

        else
          content["errorMessage"] = "Please send a Power Chip Id"
        end
      else
        content["errorMessage"] = "Please send a Device Id"
      end

      @power_chip_contents << content
    end

    respond_to do |format|
      format.json { render :json => @power_chip_contents }
    end
  end

  # This method listens to the request from the user and responds with the license keys
  def get_license_keys

    # Params for testing
    #params[:deviceId] = "E010312204098"
    #params[:powerChipId] = "PC_0002501"
    #params[:userId] = "ES-0994"
    #params[:contentIdPublisherIdMapperList] = Array.new
    #params[:contentIdPublisherIdMapperList] << {"publisherId" => "2", "contentId" => "CBSE/8th Class"}
    #params[:contentIdPublisherIdMapperList] << {"publisherId" => "3", "contentId" => "ICSE/9th Class"}

    # Basic parameters to be sent in the response
    result = Hash.new
    result["isValid"] = FALSE
    result["errorMessage"] = ''

    # Checking if the deviceId is present in the request
    if !params[:deviceId].blank?
      result["deviceId"] = params[:deviceId]

      # Checking if the powerChipId is present in the request
      if !params[:powerChipId].blank?
        result["powerChipId"] = params[:powerChipId]

        # Checking if the userId is present in the request
        # TODO: Currently not checking if the user is valid
        if !params[:userId].blank?
        result["userId"] = params[:userId]

        # Checking if the deviceId is valid
        devices = Device.where(:deviceid=>result["deviceId"])
        if devices.length > 0

          # Checking if the powerChipId is valid
          chips = Chip.where(:chipid=>result["powerChipId"])
          if chips.length > 0

            # Checking if the powerChip entry and device entry is present in the Power Chips Module
            only_power_chips = DrmPowerChip.where(:powerchipid=>result["powerChipId"])

            # TODO: Now checking the powerChip with deviceId if the Chip has to be used in other device this part need to be changed
            if only_power_chips.length > 0

                # Checking if the entries in power chips matches with the device id in the current request
                only_power_chips.each do |pc|
                  if pc.device_id == result["deviceId"]
                    result["isValid"] = TRUE
                  else
                    result["isValid"] = FALSE
                    result["errorMessage"] = "Please use the power chip in the assigned device"
                    break
                  end
                end

            else
              # No power chip entries are found the user is requesting the license for the first time for the chip so proceeding further
              result["isValid"] = TRUE
            end

            # Proceeding to get the license if the powerChip and device validation is done
            if result["isValid"]
              
              # Checking if the Content and Publisher parameters are present in the request
              if !params[:contentIdPublisherIdMapperList].blank? && (params[:contentIdPublisherIdMapperList].length > 0)
                license_request = params[:contentIdPublisherIdMapperList]

                  result["data"] = []
                  # For each license request getting the license keys
                  license_request.each do |request|
                    license_data = Hash.new
                    license_data["isValid"] = FALSE
                    license_data["Message"] = ""

                    if !request["publisherId"].blank?
                      license_data["publisherId"] = request["publisherId"].to_i

                      # Checking if contentId is present in the request
                      if !request["contentId"].blank?
                        license_data["contentId"] = request["contentId"]

                        # Checking if the publish is a valid publisher
                        publisherInfo = User.find(license_data["publisherId"])
                        if publisherInfo.type == "Publisher"

                          # Checking if the license already exists for the content and the publisher
                          # TODO: Currently not checking for the userId if the userId has to be introduced this block needs to be changed
                          license_info = DrmPowerChip.where(:powerchipid=>result["powerChipId"], :device_id=>result["deviceId"], :publisher_id=>license_data["publisherId"], :content_id=>license_data["contentId"], :status=>"issued")

                          if license_info.length > 0
                            license_entry = license_info.first

                            # License info is found for the request setting the validity to true
                            license_data["isValid"] = TRUE

                            # Preparing the data for the responding
                            license_data["license_key"] = license_entry.license_key
                            license_data["start_date"] = license_entry.start_date
                            license_data["end_date"] = license_entry.end_date
                            license_data["license_status"] = license_entry.license_status
                            license_data["license_type"] = license_entry.license_type
                            license_data["action_on_expiry"] = license_entry.action_on_expiry
                            license_data["message_on_expiry"] = license_entry.message_on_expiry
                            license_data["policy_id"] = license_entry.policy_id
                            license_data["extras"] = license_entry.extras
                            
                          else
                            # The license was not issued previously generating a new license record and getting the licenses
                            license = generate_license_enrty(result["powerChipId"],result["deviceId"],result["userId"],license_data["publisherId"],license_data["contentId"])

                            if license["isValid"]
                              license_entry = DrmPowerChip.find(license["id"])

                              # Sending the license data
                              license_data["isValid"] = TRUE
                              license_data["license_key"] = license_entry.license_key
                              license_data["start_date"] = license_entry.start_date
                              license_data["end_date"] = license_entry.end_date
                              license_data["license_status"] = license_entry.license_status
                              license_data["license_type"] = license_entry.license_type
                              license_data["action_on_expiry"] = license_entry.action_on_expiry
                              license_data["message_on_expiry"] = license_entry.message_on_expiry
                              license_data["policy_id"] = license_entry.policy_id
                              license_data["extras"] = license_entry.extras
                            else
                              # If we didn't get the licnese then showing a error message
                              license_data["Message"] = "An error occured in getting the license for the content"
                            end

                          end

                        else
                          # The publisher is not valid send a error message
                          license_data["Message"] = "The publisher you requested is not a valid publisher"
                        end

                      else
                        # If the contentId is not present then send a error message
                        license_data["Message"] = "Please Send a Content Id"
                      end

                    else
                      # If the publisherId is not present then send a error message
                      license_data["Message"] = "Please Send a Publisher Id"
                    end

                    result["data"] << license_data
                  end

              else
                result["errorMessage"] = "Please send the Publishers and Contents for which you require the licenses"
              end
            end

          else
            # If the powerChipId is not valid sending a error message
            result["errorMessage"] = "The Power Chip Id you requested is invalid"
          end

        else
          # If the deviceId is not valid sending a error message
          result["errorMessage"] = "The Device Id you requested is invalid"
        end

        else
          # If the userId is not present in the request sending a error message
          result["errorMessage"] = "Please send a User Id"
        end
        
      else
        # If the powerChipId is not present in the request sending a error message
        result["errorMessage"] = "Please send a DrmPowerChip Id"
      end

    else
      # If the deviceId is not present in the request sending a error message
      result["errorMessage"] = "Please send a Device Id"
    end

    respond_to do |format|
      format.json { render :json => result}
    end

  end

  # This method generates the power chip record for the request and tries to get the license for the content
  private
  def generate_license_enrty(powerChipId, deviceId, userId, publisherId, contentId)

    return_data = Hash.new
    return_data["isValid"] = FALSE
    # Checking if the user has requested for the license for the content previously but was not issued

    previous_license_requests = DrmPowerChip.where(:powerchipid=>powerChipId, :device_id=>deviceId, :publisher_id=>publisherId, :content_id=>contentId, :status=>"requested")

    if previous_license_requests.length > 0
      license = previous_license_requests.first
    else
      # Creating the new Power Chip Entry
      # TODO: Currently not adding the User ID have to add in the future for further requirement
      license = DrmPowerChip.new
      license.powerchipid = powerChipId
      license.device_id = deviceId
      license.publisher_id = publisherId
      license.publisher_name = Publisher.find(publisherId).name
      license.content_id = contentId
      license.status = "requested"
      license.user_id = userId
      license.save
    end

    alloted_license = get_license_key(publisherId, contentId)

    # If a valid license is found then updating the power chip entry
    if alloted_license["isValid"]
      alloted_license_data = DrmPowerChip.find(alloted_license["id"])

      # Updating the license entry with the alloted license entry
      license.update_attributes(:license_key => alloted_license_data["license_key"],
        :start_date => alloted_license_data["start_date"], :end_date => alloted_license_data["end_date"],
        :license_type => alloted_license_data["license_type"], :license_status => alloted_license_data["license_status"],
        :action_on_expiry => alloted_license_data["action_on_expiry"], :message_on_expiry => alloted_license_data["message_on_expiry"],
        :policy_id => alloted_license_data["policy_id"], :extras => alloted_license_data["extras"], :status => 'issued'
      )

      # Destroying the license entry
      alloted_license_data.destroy
      return_data["isValid"] = TRUE
      return_data["id"] = license.id
    end

    # Return the alloted license
    return return_data
  end

  # This method gets the license key for the data requested
  private
  def get_license_key(publisherId, contentId)

    alloted_license = Hash.new
    
    alloted_license["isValid"] =  FALSE

    # First finding any extra licenses are find for the content and publisher
    extra_licenses = DrmPowerChip.where(:publisher_id=>publisherId, :content_id=>contentId, :status=>"added")

    if extra_licenses.length > 0
      alloted_license["isValid"] = TRUE
      alloted_license["id"] =  extra_licenses.first.id
    else
      # No extra licenses are found try to get the licenses from the publisher licenses api
      license_added = get_license_from_publisher(publisherId, contentId)

      if license_added

        # New licenses are added allot one license to the Power Chip
        added_licenses = DrmPowerChip.where(:publisher_id=>publisherId, :content_id=>contentId, :status=>"added")

        if added_licenses.length > 0
          alloted_license["isValid"] = TRUE
          alloted_license["id"] =  added_licenses.first.id        
        end
      end
    end

    return alloted_license
    
  end

  # This method gets the license data from the publisher
  private
  def get_license_from_publisher(publisherId, contentId)
    
    # TODO: Currently Putting Some random junk date have to integrate with the publisher cloud in the future

    new_license = DrmPowerChip.new
    new_license.publisher_id = publisherId
    new_license.content_id = contentId
    new_license.license_key = (Time.now.to_i*rand(1000))+rand(100000)
    new_license.start_date = Time.now.to_i
    new_license.end_date = Time.now.to_i+31556926
    new_license.license_status = 'active'
    new_license.license_type = 'closed'
    new_license.action_on_expiry = 'delete'
    new_license.status = 'added'
    new_license.message_on_expiry = 'The license for this Content has expired Please purchase a new license'

    if new_license.save
      return TRUE
    else
      return FALSE
    end

  end

  # This method gets the license from the publisher cloud and updates the database with license information
  private
  def update_license_key(power_chips_content_id)
    # Getting the license data from the publisher
    # TODO: Have to introduce the parameters that are to be sent to the publisher
    license_data = get_license_key_from_publisher

    # If a valid license key is obtained update the database with license information
    if license_data["isValid"]
      power_chip_update = DrmPowerChip.find(power_chips_content_id)
      power_chip_update.update_attributes(:license_key => license_data["license_key"], :start_date => license_data["start_date"], :end_date => license_data["end_date"])
      return TRUE
    else
      return FALSE
    end
  end

  # This method gets the license key from the publisher cloud
  # TODO: Currently returning some junk data have to integrate with the publisher cloud
  private
  def get_license_key_from_publisher
    license_data = Hash.new
    license_data["license_key"] = (Time.now.to_i*rand(1000))+rand(100000)
    license_data["start_date"] = Time.now.to_i
    license_data["end_date"] = Time.now.to_i+31556926
    license_data["isValid"] = TRUE

    return license_data
  end
end
