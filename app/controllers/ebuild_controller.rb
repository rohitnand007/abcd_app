class EbuildController < ApplicationController

  def index
    @ebuilds = EbuildTag.all
    if params[:id]
      @ebuilds = EbuildTag.where(:institution_id=>params[:id])
      @list = [({value:nil,name:'New'})] + @ebuilds.map {|u| Hash[value: u.id, name: u.ebuild_name]}
      render json: @list
    end
  end


  def show
    @ebuild= EbuildTag.find(params[:id])
    respond_to do |format|
      format.js
      format.html
    end
  end

  def ebuild_new
    @ebuild_tag = EbuildTag.new
    @ebuild_app = @ebuild_tag.ebuild_apps.build
    @ebuild_publish = @ebuild_tag.ebuild_publish.build
  end

  def post_ebuild_new
    @ebuild_tag = EbuildTag.new(params[:ebuild_tag])
    respond_to do |format|
      if @ebuild_tag.save
        format.html {redirect_to ebuild_path(@ebuild_tag)}
      else
        format.html { render action: "ebuild_new" }
      end
    end
  end


  def ebuild_publish
    @ebuild = EbuildTag.find(params[:id])
  end

  def ebuild_publish_save
    @publish = EbuildPublish.new(params[:ebuild_publish])
    @publish.save
  end

  def edutor_build_update
    @result = {}
    apps = JSON.load(params[:apps])
    count = 1
    build_id = ''
    unless user_signed_in?
      respond_to do |format|
        format.json { render json: {:edutorid=>nil,:password=>nil} }
      end
      return
    end

    apps.each do |app|
      ebuild_arr_ids = EbuildApp.where(:package => app['pkgName'], :sharedUserId => app['sharedUserId'], :versionCode => app['versionCode']).map(&:ebuild_tag_id).uniq
      ebuild_arr = EbuildTag.includes(:ebuild_publish).where("institution_id=? and ebuild_tags.id IN (?) and ebuild_publishes.user_id IN (?)",current_user.institution_id,ebuild_arr_ids,current_user.group_ids).map(&:id).uniq
      build_id = ebuild_arr if count == 1
      build_id = build_id & ebuild_arr
      count += 1
    end
    logger.info "build array==========#{build_id}"
    if !build_id.empty?
      #build_tag_old = EbuildTag.find(build_id.first)
      build_tag_id = EbuildPublish.where(:ebuild_tag_id => build_id.first)
      if !build_tag_id.empty?
        if !build_tag_id.last.publish_ebuild_tag_id.nil?
          if current_user.group_ids.include?(build_tag_id.last.user_id)
            build_tag = EbuildTag.find(build_tag_id.last.publish_ebuild_tag_id)
            if build_tag.institution_id == current_user.institution_id
              build_tag.ebuild_apps.each do |push_app|
                size = push_app.attachment_file_size
                hash = Digest::MD5.hexdigest(File.read(push_app.attachment.path))
                name = push_app.attachment_file_name
                @result = @result.merge({:apps => [:file_size=>size,:file_hash=>hash,:file_name=>name,:file_url=>get_edutor_apk_path(:id=>push_app.id) ]})  if push_app.publish_flag == true
                logger.info "#{@result}"
              end
            end
          end
        end
      end
      logger.info "==build_result===#{@result}"
    end
    respond_to do |format|
      format.json { render json: @result }
    end
  end

  def get_edutor_build_apk
    ebuild_app = EbuildApp.find(params[:id])
    response.header["Accept-Ranges"] = "bytes"
    send_file ebuild_app.attachment.path,:disposition=>'inline',:x_sendfile=>true
  end

  def new_windows_build
    @windows_build = WindowsBuild.new
  end

  def create_windows_build
    @windows_build = WindowsBuild.new(params[:windows_build])
    respond_to do |format|
      if @windows_build.save
        format.html {redirect_to show_windows_build_path(@windows_build)}
      else
        format.html { render action: "new_windows_build" }
      end
    end

  end

  def show_windows_build
    @windows_build = WindowsBuild.find(params[:id])
  end

  def get_windows_build
    @result = {}
    if user_signed_in?
      @windows_build =  WindowsBuild.where(:academic_class_id=>current_user.academic_class_id).order("created_at desc")
      unless @windows_build.empty?
        @build = @windows_build.first
        size = @build.attachment_file_size
        #hash = Digest::MD5.hexdigest(File.read(@build.attachment.path))
        version = @build.version
        name = @build.attachment_file_name
        @result = @result.merge({:file_size=>size,:version=>version,:file_name=>name,:file_url=>download_windows_build_url(:id=>@build.id)})
      end
    end
    respond_to do |format|
      format.json { render json: @result }
    end
  end

  def download_windows_build
    @windows_build = WindowsBuild.find(params[:id])
    response.header["Accept-Ranges"] = "bytes"
    send_file @windows_build.attachment.path,:disposition=>'inline',:x_sendfile=>true
  end

end
