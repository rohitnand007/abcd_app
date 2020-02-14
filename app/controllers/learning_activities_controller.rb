class LearningActivitiesController < ApplicationController
  before_filter :check_tags_db_assigned
  def index
    @learning_activities = LearningActivity.where(user_id: current_user.id)
    #render :file=>"learning_activities/preview_name_the_image",:layout=>false

  end


  def new
    if params[:name].present? and ["flash_cards", "image_gallery", "match_the_item", "name_the_image", "concept_map"].include? params[:name]
      tags = current_user.my_tags
      @class_tags = tags['class_tags']
      @subject_tags = tags['subject_tags']
      @concept_tags = tags['concept_tags']
      render :file=>"learning_activities/#{params[:name]}",:layout=>false
    else
      redirect_to learning_activities_path
    end
  end

  def upload_image_file
    image =  Image.new(:attachment=>params[:file])
    if params[:file].present?
      if image.save
        render :text=>image.attachment_file_name
      else
        render :text=>"Failed to upload the file name =>"+"#{image.error.message}"
      end
    else
      render :text=>"Failed to upload the file because the file was empty."
    end

  end


  def download_image_file
    @image = Image.find_by_attachment_file_name(params[:image_name])
    send_file @image.attachment.path, :type => 'image/jpeg', :disposition => 'attachment'
  end

  def upload_image_url
    if params[:url].present?
      image = Image.new
      image.attachment = image.image_from_url(params[:url])
      image.save
      if image.save
        render :text=>image.attachment_file_name
      else
        render :text=>"Failed to upload the file name =>"+"#{image.error.message}"
      end
    else
      render :text=>"Failed to upload the file because the file was empty."
    end
  end

  def create
    @data = params
    @learning_activity = LearningActivity.new
    @learning_activity.user_id = current_user.id
    @learning_activity.learning_activity_type = @data["learning_activity_type"]
    @learning_activity.data = @data
    @learning_activity.name = @data["name"]
    @learning_activity.description = @data["description"]
    if  @learning_activity.save
      @learning_activity.guid = generate_guid
      @learning_activity.tag_mappings.create(tag_id: @data["class"])
      @learning_activity.tag_mappings.create(tag_id: @data["subject"])
      @learning_activity.tag_mappings.create(tag_id: @data["topics"])
      render :json=>{:status=>true}
    else
      render :json=>{:status=>false}
    end
  end


  def download_learning_activity
    @learning_activity = LearningActivity.find(params[:id])
    send_file @learning_activity.download_package,:filename=>@learning_activity.download_package.split("/").last ,:disposition=>'inline',:type=>"application/zip",:x_sendfile=>true
  end


  def edit
    @learning_activity = LearningActivity.find(params[:id])
  end


  def preview
    @learning_activity = LearningActivity.find(params[:id])
    # respond_to do |format|
    #   format.html
    #   format.js
    # end
    render :layout => false
  end

  def get_activity_data
    @learning_activity = LearningActivity.find(params[:id])
    render :json => @learning_activity.data.to_json
  end

  def check_tags_db_assigned
    if current_user.tags_db.present?
      true
    else
      redirect_to :back, notice: 'No Tags DB is assigned.'
    end
  rescue ActionController::RedirectBackError
    redirect_to root_path, notice: "No Tags DB is assigned."
  end
  private
  def generate_guid
    SecureRandom.uuid
  end

end
