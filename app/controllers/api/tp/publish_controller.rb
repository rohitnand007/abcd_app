class Api::Tp::PublishController < Api::Tp::BaseController

  def get_access_groups
    result = []
    if current_user.is? "ET" or current_user.is? "EO"
      # result = current_user.groups.where("Type NOT IN (?)",["INSTITUTION","CENTER"]).map{|i|{ id: i.id,name: i.name}}
      result = current_user.student_groups.map{|i|{ id: i.id,name: i.name}}
    end
    render json: result
  end

  def get_users_by_search
    result = []
    like= "%".concat(params[:text].concat("%"))
    if current_user.is? "ET"
      users =  Profile.includes(:user).where("users.academic_class_id = ? and( surname like ? or firstname like ? or users.edutorid like ? )",current_user.academic_class_id,like,like,like).limit(10)
    else
      users = Profile.includes(:user).where("users.institution_id=? and (surname like ? or firstname like ? or users.edutorid like ? or users.rollno like ?) and users.rc IN (?)",current_user.institution_id,like,like,like,like,["ET","ES"]).limit(10)
    end
    result = users.empty? ? users : users.map {|u| Hash[id: u.user_id, name: u.autocomplete_display_name]} unless users.empty?
    render json: result
  end

  def upload_asset
    asset_types = {"pdf"=>"pdf","text"=>"pdf","video"=>"video-lecture","audio"=>"audio","weblink"=>"weblink","image"=>"text-book"}
    @pdf_name = (params["asset_name"].gsub!(/[^0-9A-Za-z]/, '_').nil? ? params["asset_name"] : params["asset_name"].gsub!(/[^0-9A-Za-z]/, '_'))+"_"+Time.now.to_i.to_s+".pdf"
    @asset = UserAsset.new
    @asset.attachment = set_attachment
    @asset.weblink_url = params["file"] unless params["asset_type"] != "weblink"
    @asset.guid = SecureRandom.uuid
    @asset.asset_name = params["asset_name"]
    @asset.user_id = current_user.id
    @asset.asset_type = params["asset_type"]
    @asset.launch_file = set_launch_file
    if @asset.save
      #@asset.extract_encrypt_and_zip  unless @asset.asset_type == "weblink"
      @asset.extract_encrypt_and_zip  unless @asset.asset_type == "weblink"
      render json:{status: true,guid: @asset.guid}
    else
      render json:{status: false,message: @asset.errors}
    end
  end

  def publish_asset
    @content_delivery = ContentDelivery.new
    @ibook = Ibook.find_by_ibook_id(params["book_guid"])
    @user_asset = UserAsset.find_by_guid(params["asset_guid"])
    @target_uri = params["uri"]+"/"+(@user_asset.asset_name.gsub!(/[^0-9A-Za-z]/, '_').nil? ? @user_asset.asset_name : @user_asset.asset_name.gsub!(/[^0-9A-Za-z]/, '_'))+ "_" + Time.now.to_i.to_s
    ActiveRecord::Base.transaction do
      @content_delivery.ibook_id = @ibook.id
      @content_delivery.user_id = current_user.id
      @content_delivery.uri = @target_uri
      @content_delivery.user_asset_id = @user_asset.id
      @content_delivery.published_as = @user_asset.asset_type
      @content_delivery.is_content = true
      @content_delivery.is_assessment = false
      @content_delivery.is_homework = false
      @content_delivery.show_in_live_page = true
      @content_delivery.show_in_toc =  true
      @content_delivery.display_name = @user_asset.asset_name
      @content_delivery.guid = @user_asset.guid
      @content_delivery.parent_guid = params["parent_guid"]

      if params["group_id"].present?
        @content_delivery.group_id = params["group_id"]
      else
        @content_delivery.to_group = false
        @content_delivery.recipients = params["multiple_user_ids"].split(",").uniq.join(",")
      end

      if @content_delivery.save
        render json:{ status:true}
      else
        render json:{ status: false, message: @content_delivery.errors }
      end
    end
  end

  def set_attachment
    if params["asset_type"] == "text"
      pdf = WickedPdf.new.pdf_from_string(params["file"],
                                          page_height:50,
                                          page_width:100,
                                          margin:{top:15, bottom:15, left:15, right:15 }

      )
      save_path = Rails.root.join('public/pdf_reports',@pdf_name)
      File.open(save_path, 'wb') do |file|
        file << pdf
      end
      return File.open(save_path)
    elsif params["asset_type"] == "image"
      @image = Image.new
      @image.attachment = params["file"]
      @image.save
      @data =  {"finalJSON"=>[{"imageSource"=>"image_020fc14c-720c-48d8-a3a5-03fa0e4795de.png", "itemClass"=>"item active"}], "images"=>["image_020fc14c-720c-48d8-a3a5-03fa0e4795de.png"], "instructions"=>"Play the image", "name"=>"Image", "description"=>"", "class"=>"", "subject"=>"", "topics"=>"1675", "learning_activity_type"=>"image_gallery", "logo"=>""}
      @data["finalJSON"].first["imageSource"] = @image.attachment_file_name
      @data["name"] = params["asset_name"]
      @data["description"] = "Image published from teacher"
      @data["images"] = [@image.attachment_file_name,"ignitor_logo.png"]
      @learning_activity = LearningActivity.new
      @learning_activity.user_id = current_user.id
      @learning_activity.learning_activity_type = "image_gallery"
      @learning_activity.data = @data
      @learning_activity.name = params["asset_name"]
      @learning_activity.description = "Image published from teacher"
      @learning_activity.save
      return File.open(@learning_activity.download_package)
    elsif params["asset_type"] == "weblink"
      nil
    else
      params["file"]
    end
  end


  def set_launch_file
    if params["asset_type"] == "image"
      "play_image_gallery/play_image_gallery.html"
    elsif params["asset_type"] == "text"
      @pdf_name
    elsif params["asset_type"] == "weblink"
      ""
    else
      params["file"].original_filename.gsub(" ","_")
    end
  end

end