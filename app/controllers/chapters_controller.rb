require 'zip/zip'
require 'find'
require "nokogiri"
class ChaptersController < ApplicationController
   authorize_resource
  # GET /contents
  # GET /contents.json
  def index
    #unless current_user.is?("ET")
    #@chapters = Chapter.page(params[:page])
    #else
    #@chapters = current_user.chapters.page(params[:page])
    #end
    @chapters = case current_user.role.name
                  when 'Edutor Admin'
                    Chapter.page(params[:page])
                  when 'Institute Admin'
                    #Chapter.by_boards_and_published_by_assets(current_user.institution.board_ids,current_user.institution.publisher_ids).page(params[:page])
                    Chapter.where(:board_id=>current_user.institution.board_ids).page(params[:page])
                  when 'Center Representative'
                    #Chapter.by_boards_and_published_by_assets(current_user.center.board_ids,current_user.institution.publisher_ids).page(params[:page])
                    Chapter.where(:board_id=>current_user.center.board_ids).page(params[:page])
                  when 'Teacher'
                    current_user.chapters.page(params[:page])
                  else
                    Chapter.page(params[:page])
                end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @chapters }
    end
  end

  # GET /Chapters/1
  # GET /Chapters/1.json
  def show
    @chapter = Chapter.find(params[:id])
    @topics = @chapter.topics.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @chapter }
    end
  end

  # GET /Chapters/new
  # GET /Chapters/new.json
  def new
    params_hash = {board_id: params[:board_id],content_year_id: params[:content_year_id],subject_id: params[:subject_id]}
    @chapter = Chapter.new(params_hash)
    @chapter.assets.build
    @chapter.build_content_profile
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @chapter }
    end
  end

  # GET /Chapters/1/edit
  def edit
    @chapter = Chapter.find(params[:id])
  end

  # POST /Chapters
  # POST /Chapters.json
  def create
    if current_user.is?("ET")
      @content = Content.find(params[:chapter][:subject_id])
      params[:chapter][:board_id] = @content.board_id
      params[:chapter][:content_year_id]= @content.content_year_id
    end
    @chapter = Chapter.new(params[:chapter])
    respond_to do |format|
      if @chapter.save
        if [".pdf",".swf",".mp4"].include?(File.extname(@chapter.assets.first.attachment_file_name))
          @chapter.update_attribute(:status,0)
        elsif @chapter.status == 1
          # extracting_zip_file(@chapter)
          # reading_and_updating_content(@extract_path)
          Content.send_message_to_est(false,current_user,@chapter)
        else
          true
        end
        format.html { redirect_to current_user.is?("ET")? teacher_contents_path(@teacher) : @chapter, notice: 'Chapter was successfully created.' }
        format.json { render json: @chapter, status: :created, location: @chapter }
      else
        format.html { render action: "new" }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

# PUT /Chapters/1
# PUT /Chapters/1.json
  def update
    @chapter = Chapter.find(params[:id])
    if current_user.role.id == 7
      params[:chapter][:status] = 6
      params[:chapter][:vendor_id] = @chapter.vendor_id
    end
    respond_to do |format|
      if @chapter.update_attributes(params[:chapter])
        if @chapter.status == 6
          Content.send_message_to_est(@chapter.vendor,current_user,@chapter)
        end
        format.html { redirect_to @chapter, notice: 'Chapter was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

# DELETE /Chapters/1
# DELETE /Chapters/1.json
  def destroy
    @chapter = Chapter.find(params[:id])
    @chapter.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to chapters_url }
      format.json { head :ok }
    end
  end



  def extracting_zip_file(chapter)
    @extract_path = Rails.root.to_s+"/public/zip-files/"+chapter.name
    Zip::ZipFile.open(Rails.root.to_s+'/public'+chapter.assets.first.url) { |zip_file|
      zip_file.each { |f|
        puts f.name
        f_path=File.join(@extract_path, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f,f_path)    }
    }

  end

  def reading_and_updating_content(root_path)
    i = 0
    Find.find(root_path) do |path|
      if FileTest.directory?(path)
        Dir.entries(path).sort.each do |d|
          if File.fnmatch(d,'index.xml')
            logger.info "===========#{path}=========="
            doc = Nokogiri::XML(open(path+'/index.xml'))
            doc.xpath('/index/display').each do |xml|
              logger.info "===========#{xml.attr("type")}"
              case xml.attr("type")
                when "content"
                  logger.info "===content==="
                when "course"
                  xml.attr("uri").split('_')[1] =~ /cb/
                  @course =  Course.create(:name=>xml.attr("uri").split('_')[1])
                  unless File.directory?(Rails.root.to_s+"/public/archives/"+@course.name)
                    Dir.chdir(Rails.root.to_s+"/public/archives/")
                    Dir.mkdir(@course.name)
                    puts "=====created course folder"
                    FileUtils.cp_r  path+"/index.xml",Rails.root.to_s+"/public/archives/"
                  end
                #create_directory
                when "Subject"
                  logger.info "===subject==="
                  @subject = Subject.create(:name=>xml.attr("uri"))
                when "year"
                  @year =  AcademicYear.create(:name=>xml.attr('uri'))
                when "Topic"
                  logger.info "===topic==="
                else
                  logger.info "====dosen't have expected data===="
              end
            end
          end
        end
      end
    end
  end

  def create_dir_structure(object,path)
    case object.class.name
      when "Course"

      when "AcademicYear"
        ""
      when "Subject"
        ""
    end
  end


#Chapter download for the EST and status  update
  def est_download
    @chapter = Chapter.find(params[:id])
    if current_user.role.name.eql?('Support Team')
      @chapter.update_attribute(:status,'EST is Processing')
    end
    redirect_to @chapter.assets.first.attachment.url
  end


# Get populating the topics for a chapter
  def get_topics
    @chapter = Chapter.find(params[:id]) unless params[:id].blank?
    if current_user.is?("EA") or current_user.is?("IA")
      list = @chapter.topics.map {|u| Hash[value: u.id, name: u.name]}
    else
      topic_ids = ContentUserLayout.get_unlocked_topics(@chapter,current_user)
      if !topic_ids.nil?
        list = @chapter.topics.where(:id=>topic_ids).map {|u| Hash[value: u.id, name: u.name]}
      else
        list = @chapter.topics.map {|u| Hash[value: u.id, name: u.name]}
      end
    end
    render json: list
  end

# Get populating the topics for a chapter
  def get_topics_values
    @chapter = Chapter.find(params[:id]) unless params[:id].blank?
    if current_user.is?("EA") or current_user.is?("IA")
      list = @chapter.topics.map {|u| Hash[value: (u.id.to_s+'|'+get_params(u.params.to_s)), name: u.name]}
    else
      topic_ids = ContentUserLayout.get_unlocked_topics(@chapter,current_user)
      if !topic_ids.nil?
        list = @chapter.topics.where(:id=>topic_ids).map {|u| Hash[value: (u.id.to_s+'|'+get_params(u.params.to_s)), name: u.name]}
      else
        list = @chapter.topics.map {|u| Hash[value: (u.id.to_s+'|'+get_params(u.params.to_s)), name: u.name]}
      end
    end
    render json: list
  end

  def get_params(u)
    unless u.nil?
      a = {}
      u.split(',').each do |i|
        a = a.merge({i.split(':')[0].to_s=>i.split(':')[1].to_s})
      end
      a = a['page_start'].to_s+','+a['page_end'].to_s
    else
      a = ''
    end
    return a
  end


end
