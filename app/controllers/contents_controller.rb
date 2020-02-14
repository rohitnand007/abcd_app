class ContentsController < ApplicationController
  authorize_resource
  before_filter :check_actions

  def check_actions
    if params[:action].eql?'new'
      redirect_to contents_path
    end
  end

  #updating the order position of the content
  def position_update
    @content = Content.find(params[:subject_id])
    @content_layout = ContentUserLayout.new
    @content_layout.content_id = @content.id
    @content_layout.user_id = current_user.id
    @content_layout.content_layout = params[:content]
    if @content_layout.save!
      file =  generate_content_ncx(@content,@content_layout.content_layout)
      message = Message.new
      message.group_id = params[:message][:group_id]
      message.subject = "Updating content"
      message.body = "Updating content"
      message_asset = message.assets.build
      message_asset.attachment = File.open(file,"rb")
      message.message_type = "Content Update"
      message.sender_id = current_user.id
      message.save
      flash.now[:notice]  = "Content updated Successfully."
      redirect_to manage_content_path(@content)
    else
      flash.now[:notice]  = "Content not updated."
      redirect_to manage_content_path(@content)
    end
    #@subject = params[:subject]
    #content = Subject.find(id)
    #contents = Subject.includes(:chapters=>:topics).where(:id=>id).select("id,name")
    #chapters = []
    #content.chapters.each do|c|
    #  chapters << [c.id,c.name,[c.topics.select("id,name")]]
    #end
    #@contents = chapters
    #j = 1
    #@subject.each do |content|
    #  parent = content.split(":")[0]
    #  parent = parent.split("_")[2].to_i
    #  Content.find(parent).update_attribute(:play_order,j) unless parent.nil?
    #  childs = content.split(":")[1].split(',') unless content.split(":")[1].nil?
    #  unless childs.nil?
    #    i = 1
    #    childs.each do |child|
    #      Content.find(child.to_i).update_attribute(:play_order,i)
    #      i = 1+i
    #    end
    #  end
    #  j = j+1
    #end
    ##ncx update for the subject
    #generate_content_ncx(@content)

    #respond_to do |format|
    #  format.js
    #end
  end

  #Gneerate xml from content manage page
  def generate_content_ncx(content,content_layout)
    @content = content
    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum", :class=>"curriculum"){
          xml.content(:src=>"curriculum")
          xml.navPoint(:id=>"Content",:class=>"content"){
            xml.content(:src=>"content")
            xml.navPoint(:id=>@content.board.name,:class=>"course"){
              xml.content(:src=>@content.board.name+"_"+@content.asset.publisher_id.to_s)
              xml.navPoint(:id=>@content.content_year.name,:class=>"academic-class"){
                xml.content(:src=>@content.content_year.code,:params=>@content.content_year.params)
                xml.navPoint(:id=>@content.name,:class=>@content.type.downcase){
                  xml.content(:src=>@content.code)
                  content_layout.keys.each_with_index do |key,index|
                    chapter = Chapter.find(content_layout[key]["id"])
                    chapter_lock_status = content_layout[key]["is_locked"]
                    xml.navPoint(:id=>chapter.name,:class=>"chapter",:playOrder=>index+1,:lock=>chapter_lock_status){
                      xml.content(:src=>chapter.assets.first.src,:params=>chapter.params)
                      if content_layout[key]["data"]
                      content_layout[key]["data"].keys.each_with_index do |k,i|
                        topic = Topic.find(content_layout[key]['data'][k]["id"])
                        topic_lock_status = content_layout[key]['data'][k]["is_locked"]
                        xml.navPoint(:id=>topic.name,:class=>"topic",:playOrder=>i+1,:lock=>topic_lock_status){
                          xml.content(:src=>topic.assets.first.src,:params=>topic.params)
                        }
                      end
                     end
                    }
                  end
                }
              }
            }
          }
        }
      }
    end
    #path = File.expand_path("..",File.expand_path("..",Rails.root.to_s+"/public/"+@content.asset.url))
    path = Rails.root.to_s+"/tmp/cache/downloads/ncx_#{content.id}_#{Time.now.to_i}"
    FileUtils.mkdir_p path
    file = File.new(path+"/"+"index.ncx", "w+")
    File.open(file,'w') do |f|
      f.write(@builder.to_xml.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
    end
    create_zip("ncx_#{content.id}",path)
    #@content = Content.find(6).chapters.select("id,is_locked,name").map(&:id)
  end


  #Content lock
  def content_lock
    @ids = params[:ids]
    Content.where(:id=>@ids).update_all(:is_locked=>true)
    flash.now[:notice] = "Contents Locked Successfully."
    respond_to do |format|
      format.js
    end
  end

  #Content unlock
  def content_unlock
    @ids = params[:ids]
    Content.where(:id=>@ids).update_all(:is_locked=>false)
    flash.now[:notice] = "Contents Un-Locked Successfully."
    respond_to do |format|
      format.js
    end
  end

  #Content hide
  def content_hide
    @ids = params[:ids]
    Content.where(:id=>@ids).update_all(:is_hidden=>true)
    flash.now[:notice] = "Contents hidden Successfully."
    respond_to do |format|
      format.js
    end
  end

  def content_unhide
    @ids = params[:ids]
    Content.where(:id=>@ids).update_all(:is_hidden=>false)
    flash.now[:notice] = "Contents un hidden Successfully."
    respond_to do |format|
      format.js
    end
  end


  #get /contents/manage
  def manage
    if current_user.is?("CR")
      @content = ContentUserLayout.where(:user_id=>current_user.id,:content_id=>params[:id])
    else
      @teacher_content_layout = ContentUserLayout.where(:user_id=>current_user.id,:content_id=>params[:id])
      if @teacher_content_layout.empty?
        @content = ContentUserLayout.where(:user_id=>current_user.center.center_admins.map(&:id),:content_id=>params[:id])
      else
        @content = @teacher_content_layout
      end
    end
    unless @content.empty?
      @layout =  @content.last.content_layout
      @subject = @content.last.content
    else
      @subject = Subject.find(params[:id])
    end
    #per_page = 1
    #unless current_user.is?("ET")
    #  @contents =  Subject.includes(:chapters=>{:topics=>:sub_topics}).page(params[:page]).per(per_page)
    #else
    #  if ContentUserLayout.where(:content_id=>current_user.class_contents.map(&:id),:user_id=>current_user.id).empty?
    #  #@contents =  Subject.where(:id=>current_user.class_contents.map(&:id)).page(params[:page]).per(per_page)
    #  @contents = Subject.find(6)
    #  @subject = Subject.find(6)
    #  else
    #  #@contents =  Subject.where(:id=>current_user.class_contents.map(&:id)).page(params[:page]).per(per_page)
    #  @layout =  ContentUserLayout.last.content_layout
    #  @subject = ContentUserLayout.last.content
    #
    #  @contents = Content.includes(:topics).where(:id=>@layout.keys.map{|key|@layout[key]['id']})
    #  #@content_layouts =  ContentUserLayout.where(:content_id=>current_user.class_contents.map(&:id),:user_id=>current_user.id).page(params[:page]).per(per_page)
    #  #@content_layouts = @content_layouts.first
    #  #@contents =
    #  #@content_layouts.content_layout.split(";").each do |c|
    #  #  Content.find(c[0])
    #
    #  #end
    #
    #  end
    #end
    #render :layout=>false
  end

  # GET /contents
  # GET /contents.json
  def index
    if current_user.role.name.eql?("Edutor Admin") or current_user.role.name.eql?("Teacher")or current_user.role.name.eql?("Support Team") or current_user.role.name.eql?("publisher")
      status = params[:status].eql?('1') ? [1,10] : [params[:status]]
      if current_user.is?("EST")
        if params[:status]
          @contents = Content.where(:status=>status,:type=>["Assessment","Topic","SubTopic","Chapter","AssessmentHomeWork"]).default_order.page(params[:page])
        else
          @contents = Content.where(:status=>[1,2,3,5,6,10],:type=>["Assessment","Topic","SubTopic","Chapter","AssessmentHomeWork"]).default_order.page(params[:page])
        end
      else
        if params[:status]
          @contents = current_user.contents.where(:status=>status,:type=>["Assessment","Topic","SubTopic","Chapter","AssessmentHomeWork"]).default_order.page(params[:page])
        else
          @contents = current_user.contents.where(:status=>[1,2,3,5,6,10],:type=>["Assessment","Topic","SubTopic","Chapter","AssessmentHomeWork"]).default_order.page(params[:page])
        end
      end
      render "est_index"
    else
      @contents = current_user.contents.default_order.page(params[:page])
    end
#    respond_to do |format|
#      format.html # index.html.erb
#      format.json { render json: @contents }
#    end
  end

  # GET /contents/1
  # GET /contents/1.json
  def show
    @content = Content.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @content }
    end
  end

  # GET /contents/new
  # GET /contents/new.json
  def new
    @content = Content.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @content }
    end
  end

  # GET /contents/1/edit
  def edit
    @content = Content.find(params[:id])
  end

  # POST /contents
  # POST /contents.json
  def create
    @content = Content.new(params[:content])

    respond_to do |format|
      if @content.save
        #send_message_to_est(@content)
        format.html { redirect_to @content, notice: 'Content was successfully created.' }
        format.json { render json: @content, status: :created, location: @content }
      else
        format.html { render action: "new" }
        format.json { render json: @content.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /contents/1
  # PUT /contents/1.json
  def update
    @content = Content.find(params[:id])

    respond_to do |format|
      if @content.update_attributes(params[:content])
        format.html { redirect_to @content, notice: 'Content was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @content.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contents/1
  # DELETE /contents/1.json
  def destroy
    @content = Content.find(params[:id])
    @content.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to (current_user.is?"ET")? teacher_contents_path  : contents_url }
      format.json { head :ok }
    end
  end

  #after creating content. The message and email alert is sent to est
  def send_message_to_est(content)
    user = User.where('edutorid like ?','%EST-%').first
    message = Message.new
    message.sender_id = current_user.id
    message.recipient_id = user.id
    message.subject = "Contet to be processord"
    message.body = "New content is uploaded. Click "+ "#{view_context.link_to content.filename,content_path(content)}"+" to visit the contant "
    message.label = "Content"
    message.message_type = "Content process"
    message.save
    UserMailer.content_notification(user,content,message)
  end


  #Content download for the EST and status  update
  def est_download
    @content = Content.find(params[:id])
    if current_user.role.name.eql?('Support Team')
      @content.update_attribute(:status,5)
    end
    asset = (@content.type == "Assessment" or @content.type == "AssessmentHomeWork" ? @content.asset : @content.assets.first)
    send_file process_zip(@content,asset)
  end


  def process_zip(content,asset)
    path = Rails.root.to_s+"/tmp/cache/downloads/content_#{content.id}"
    src = asset.src
    logger.info "==#{src}=src1"
    src = src.gsub(asset.attachment_file_name,"")
    logger.info "==#{src}=src2"
    folder_path = path+src
    file_path = Rails.root.to_s+"/public"+src
    #file_path = Rails.root.to_s+"/public"+src
    logger.info "==#{file_path}=filepath"
    FileUtils.mkdir_p folder_path
    FileUtils.cp_r "#{file_path}/.",folder_path
    generate_ncx(content,path)
  end


  def download_zip
    @content = Content.find(params[:id])
    #@content = @content.type.constantize.find(params[:id])
    url = (@content.type == "Assessment" or @content.type == "AssessmentHomeWork")? @content.asset.src : @content.assets.first.src
    send_file create_content_zip(@content.name,url)
  end
  def create_content_zip(name,url)
    @outputFile = (Rails.root.to_s+"/tmp/cache/"+name+".zip")
    if File.exist?(@outputFile)
      FileUtils.rm_rf (@outputFile)
      logger.info"===========deleated existing file"
    end
    @inputDir = File.expand_path("..",Rails.root.to_s+"/public/"+url)
    entries = Dir.entries(@inputDir)
    entries.delete(".")
    entries.delete("..")
    io = Zip::ZipFile.open(@outputFile, Zip::ZipFile::CREATE)
    writeEntries(entries, "", io)
    io.close();
    send_file @outputFile
  end
  def writeEntries(entries, path, io)
    puts"===============path",path
    entries.each { |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(@inputDir, zipFilePath)
      puts "==Deflating==" + diskFilePath
      if File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir = Dir.entries(diskFilePath)
        subdir.delete(".")
        subdir.delete("..")
        writeEntries(subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
      end
    }
  end

  def ncx_upload

  end


  def bulk_upload
    unless params[:data].present?
      flash[:error] = "File can't be blank."
    else
      name =  params[:data].original_filename
      if File.extname(name) == '.ncx'
        @error_type =''
        begin
          ActiveRecord::Base.transaction do
            directory = "#{Rails.root.to_s}/ncx"
            path = File.join(directory, name)
            File.open(path, "wb") { |f| f.write(params[:data].read) }
            doc =  Nokogiri::XML(open(path))
            @requires = Hash.new
            @uri = Hash.new
            root_path = directory
            @root_path = root_path
            doc.xpath("/navMap").children.each do |d|
              puts d.attr("id")
              research(d, "",root_path,"")
            end
          end
          flash[:success] = "Content uploaded successfully."
        rescue ActiveRecord::RecordNotFound
          flash[:error] = "No Board Found.Please confirm the respective board and code presence."
        rescue Exception => e
          puts "Exception in NCX uploading...............#{e.message}"
          logger.info "Exception in NCX uploading...............#{e}"
          flash[:error] = "#{e.message} for #{e.try(:record).try(:class).try(:name)}"
        end

      else
        flash[:error] = "File type must be a ncx."
      end

    end
    redirect_to ncx_upload_path
  end

  def research(d,path1,path2,uri_1)
    file = File.open("#{Rails.root.to_s}/readme.doc","rb")
    if d.name.eql?("navPoint")
      src = path1 + "/" + d.xpath("content").attr("src").to_s
      uri = uri_1+"/"+d.attr("id")
      name = d.attr("displayName") ? d.attr("displayName") : d.attr("id")
      puts "==============uri==#{uri}"
      puts set_src(d,src,path2)

#=begin
      case d.attr("class")

        when "course"
          board_name = name
          @requires[:src] = set_src(d,src,path2)
          board_code = d.xpath("content").first.attr("src").split('_')[0] rescue nil
          board = Board.find_by_name_and_code(board_name,board_code)
          raise ActiveRecord::RecordNotFound if board.nil?
          @requires[:publisher_id] = d.xpath("content").first.attr("src").split("_")[1]
          @requires[:board_id] = board.id

        when "academic-class"
          code = d.xpath("content").first.attr("src")
          @requires[:src]= set_src(d,src,path2)
          content_year = ContentYear.where(:board_id=>@requires[:board_id],:name=>name,:code=>d.xpath("content").first.attr("src"))
          if content_year.empty?
            content_year = ContentYear.new(:board_id=>@requires[:board_id],:name=>name,:uri=>uri,:code=>d.xpath("content").first.attr("src"))
            content_year.build_asset
            #content_year.asset.attachment = file
            content_year.asset.publisher_id = @requires[:publisher_id]
            content_year.asset.src = @requires[:src]
            content_year.save!
            @requires[:content_year_id] = content_year.id
          else
            @requires[:content_year_id] = content_year.first.id
          end

        when "subject"
          @requires[:src]= set_src(d,src,path2)
          @requires[:subject_code]=  d.xpath("content").attr("src").to_s
          subject = Subject.where(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:name=>name,:code=>@requires[:subject_code])
          if subject.empty?
            subject = Subject.new(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:name=>name,:code=>@requires[:subject_code],:uri=>uri)
            subject.build_asset
            #subject.asset.attachment =  file
            subject.asset.publisher_id = @requires[:publisher_id]
            subject.asset.src = @requires[:src]
            subject.save!
            @requires[:subject_id] = subject.id
          else
            @requires[:subject_id] = subject.first.id
          end

        when "chapter"
          @requires[:src]= set_src(d,src,path2)
          chapter = Chapter.where(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name)
          if chapter.empty?
            chapter = Chapter.new(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").first.attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type"))
            c_asset = chapter.assets.build
            #c_asset.attachment =  file
            c_asset.publisher_id = @requires[:publisher_id]
            c_asset.src = @requires[:src]
            chapter.save!
            @requires[:chapter_id] = chapter.id
          else
            chapter.first.update_attribute(:params,d.xpath("content").first.attr("params").to_s)
            @requires[:chapter_id] = chapter.first.id
          end
#=begin
        when "topic"
          @requires[:src]= set_src(d,src,path2)
          topic = Topic.where(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:chapter_id=>@requires[:chapter_id])
          if topic.empty?
            topic = Topic.new(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:chapter_id=>@requires[:chapter_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").first.attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s)
            t_asset = topic.assets.build
            #t_asset.attachment =  file
            t_asset.publisher_id = @requires[:publisher_id]
            t_asset.src = @requires[:src]
            topic.save!
            @requires[:topic_id] = topic.id
          else
            topic.first.update_attribute(:params,d.xpath("content").first.attr("params").to_s)
            @requires[:topic_id] = topic.first.id
          end

        when "subtopic"
          @requires[:src]= set_src(d,src,path2)
          sub_topic = SubTopic.where(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:chapter_id=>@requires[:chapter_id],:topic_id=>@requires[:topic_id])
          if sub_topic.empty?
            sub_topic = SubTopic.new(:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:chapter_id=>@requires[:chapter_id],:topic_id=>@requires[:topic_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").first.attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s)
            t_asset = sub_topic.assets.build
            #t_asset.attachment =  file
            t_asset.publisher_id = @requires[:publisher_id]
            t_asset.src = @requires[:src]
            sub_topic.save!
            @requires[:sub_topic_id] = sub_topic.id
          else
            @requires[:sub_topic_id] = sub_topic.first.id
          end
        when "assessment-practice-tests"
          @requires[:src]= set_src(d,src,path2)
          puts "parent", get_chapter_topic_uri(d)
          assessment_practice_test = AssessmentPracticeTest.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri =? or uri = ?')
          if assessment_practice_test.empty?
            assessment_practice_test = AssessmentPracticeTest.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:pre_requisite=>d.attr("prerequiste").to_s}.merge(content_update_attributes(d)))
            assessment_practice_test.build_asset
            #assessment_practice_test.asset.attachment =  file
            assessment_practice_test.asset.publisher_id = @requires[:publisher_id]
            assessment_practice_test.asset.src = @requires[:src]
            assessment_practice_test.save!
          end

        when "assessment-quiz"
          @requires[:src]= set_src(d,src,path2)
          puts "parent", get_chapter_topic_uri(d)
          assessment_quiz = AssessmentQuiz.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri =? or uri = ?')
          if assessment_quiz.empty?
            assessment_quiz = AssessmentQuiz.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:pre_requisite=>d.attr("prerequiste").to_s}.merge(content_update_attributes(d)))
            assessment_quiz.build_asset
            #assessment_quiz.asset.attachment =  file
            assessment_quiz.asset.publisher_id = @requires[:publisher_id]
            assessment_quiz.asset.src = @requires[:src]
            assessment_quiz.save!
          end

        when "weblink"
          @requires[:src]= set_src(d,src,path2)
          puts "parent", get_chapter_topic_uri(d)
          weblink = WebLink.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri =? or uri = ?')
          if weblink.empty?
            weblink = WebLink.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:uri=>uri,:extras=>d.xpath("content").attr("src").to_s}.merge(content_update_attributes(d)))
            weblink.build_asset
            #weblink.asset.attachment =  file
            weblink.asset.publisher_id = @requires[:publisher_id]
            weblink.asset.src = d.xpath("content").attr("src").to_s
            weblink.save!
          end

        when "assessment-insti-tests"
          @requires[:src]= set_src(d,src,path2)
          puts "parent", get_chapter_topic_uri(d)
          assessment_insti_test = AssessmentInstiTest.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))
          if assessment_insti_test.empty?
            assessment_insti_test = AssessmentInstiTest.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:pre_requisite=>d.attr("prerequiste").to_s}.merge(content_update_attributes(d)))
            assessment_insti_test.build_asset
            #assessment_insti_test.asset.attachment =  file
            assessment_insti_test.asset.publisher_id = @requires[:publisher_id]
            assessment_insti_test.asset.src = @requires[:src]
            assessment_insti_test.save!
          end
        when "home-work"
          @requires[:src]= set_src(d,src,path2)
          puts "parent", get_chapter_topic_uri(d)
          assessment_home_work = AssessmentHomeWork.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri =? or uri = ?',uri,new_uri)
          if assessment_home_work.empty?
            assessment_home_work = AssessmentHomeWork.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:pre_requisite=>d.attr("prerequiste").to_s}.merge(content_update_attributes(d)))
            assessment_home_work.build_asset
            #assessment_home_work.asset.attachment =  file
            assessment_home_work.asset.publisher_id = @requires[:publisher_id]
            assessment_home_work.asset.src = @requires[:src]
            assessment_home_work.save!
          end
        when "assessment-iit"
          @requires[:src]= set_src(d,src,path2)
          assessment_iit = AssessmentIit.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri=? or uri=?',uri,new_uri)
          if assessment_iit.empty?
            assessment_iit = AssessmentPracticeTest.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:pre_requisite=>d.attr("prerequiste").to_s}.merge(content_update_attributes(d)))
            assessment_iit.build_asset
            #assessment_iit.asset.attachment =  file
            assessment_iit.asset.publisher_id = @requires[:publisher_id]
            assessment_iit.asset.src = @requires[:src]
            assessment_iit.save!
          end
        when "animation"
          @requires[:src]= set_src(d,src,path2)
          animation = Animation.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri=? or uri=?',uri,new_uri)
          if animation.empty?
            animation = Animation.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:pre_requisite=>d.attr("prerequiste").to_s}.merge(content_update_attributes(d)))
            animation.build_asset
            #animation.asset.attachment =  file
            animation.asset.publisher_id = @requires[:publisher_id]
            animation.asset.src = @requires[:src]
            animation.save!
          end
        when "tsp"
          @requires[:src]= set_src(d,src,path2)
          tsp = Tsp.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri=? or uri=?',uri,new_uri)
          if tsp.empty?
            tsp = Tsp.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s,:pre_requisite=>d.attr("prerequiste").to_s}.merge(content_update_attributes(d)))
            tsp.build_asset
            #tsp.asset.attachment =  file
            tsp.asset.publisher_id = @requires[:publisher_id]
            tsp.asset.src = @requires[:src]
            tsp.save!
          end
        when "concept-map"
          @requires[:src]= set_src(d,src,path2)
          concept_map = ConceptMap.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri =? or uri=?',uri,new_uri)
          if concept_map.empty?
            concept_map = ConceptMap.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").first.attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s}.merge(content_update_attributes(d)))
            concept_map.build_asset
            #concept_map.asset.attachment =  file
            concept_map.asset.publisher_id = @requires[:publisher_id]
            concept_map.asset.src = @requires[:src]
            concept_map.save!
          end
        when "activity"
          @requires[:src]= set_src(d,src,path2)
          activity = Activity.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri =? or uri=?',uri,new_uri)
          if activity.empty?
            activity = Activity.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").first.attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s}.merge(content_update_attributes(d)))
            activity.build_asset
            #activity.asset.attachment =  file
            activity.asset.publisher_id = @requires[:publisher_id]
            activity.asset.src = @requires[:src]
            activity.save!
          end

        when "keywords"
          @requires[:src]= set_src(d,src,path2)
          keyword = Keyword.where({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:chapter_id=>@requires[:chapter_id],:topic_id=>@requires[:topic_id],:uri=>uri}.merge(content_update_attributes(d)))#.where('uri =?',uri)
          if keyword.empty?
            keyword = Keyword.new({:board_id=>@requires[:board_id],:content_year_id=>@requires[:content_year_id],:subject_id=>@requires[:subject_id],:name=>name,:chapter_id=>@requires[:chapter_id],:topic_id=>@requires[:topic_id],:play_order=>d.attr('playOrder'),:uri=>uri,:params=>d.xpath("content").first.attr("params").to_s,:mime_type=>d.xpath("content").first.attr("mime_type").to_s}.merge(content_update_attributes(d)))
            keyword.build_asset
            #keyword.asset.attachment =  file
            keyword.asset.publisher_id = @requires[:publisher_id]
            keyword.asset.src = d.xpath("content").attr("src").to_s
            keyword.save!

          end
#=end
      end
#=end
    end
    #puts "====src===",@requires[:src]
    if d.children
      d.children.each do |x|
        #puts "====src===", set_src(d,src,path2)
        research(x,src,set_src(d,src,path2),uri)
      end
    end
    file.close
  end

  #set chapter_id, topic_id and sub_topic_id
  def content_update_attributes(d)
    if d.parent.attr("class") == "topic"
      {:chapter_id=>@requires[:chapter_id],:topic_id=>@requires[:topic_id]}
    elsif d.parent.attr("class") == "chapter"
      {:chapter_id=>@requires[:chapter_id]}
    elsif d.parent.attr("class") == "sub-topic"
      {:chapter_id=>@requires[:chapter_id],:topic_id=>@requires[:topic_id],:sub_topic_id=>@requires[:sub_topic_id]}
    else
      {:subject_id=>@requires[:subject_id]}
    end
  end


  #setting the uri based on the parent
  def get_chapter_topic_uri(d)
    if d.parent.attr("class") == "topic"
      "/"+d.parent.parent.attr("id")+d.parent.attr("id")
    elsif d.parent.attr("class") == "chapter"
      "/"+d.parent.attr("id")
    else
      puts d.parent.attr("id")
    end
  end


  #uploading the file based on the src
  def upload_file(src)
    if File.directory?(src)
      #puts "==============src directory",src
      File.open("#{Rails.root}/readme.doc","rb")
    else
      #puts "==============src file",src
      File.open(src,"rb")
    end
  end

  #set src based on the navpoint id
  def set_uri(x,uri,new_uri)


  end

  #set src based on the string
  def set_src(x,src,path2)
    src_node = x.xpath("content").attr("src").to_s
    if x.xpath("content").attr("mime_type")
      src_node
    else
      if src_node.match(/^[a-zA-z0-9]+/)
        src
      elsif src_node.match(/^[.]{2}/)
        File.expand_path(src_node,path2)
      elsif src_node.match(/^[\/][a-zA-z]+/)
        src_node
      end
    end

  end

  #processed content upload by EST
  def upload
    @content = Content.find(params[:id])
  end

  #processed content upload by EST saved to db
  def save_upload
    @content = Content.find(params[:id])
    case @content.type when "Assessment"
                         @content.update_attributes(params[:assessment])
      when "Chapter"
        @content.update_attributes(params[:chapter])
      when "Topic"
        @content.update_attributes(params[:Topic])
      when "SubTopic"
        @content.update_attributes(params[:SubTopic])
      when "AssessmentHomeWork"
        @content.update_attributes(params[:AssessmentHomeWork])
      else
        @content.update_attributes(params[":"+@content.type.downcase])
    end
    @message = params[:message][:message]
    # assessment creation for first time i.e create and publish now options
    if @content.type.eql?("Assessment") and @content.test_configurations.size !=0 and @content.test_configurations.first.status == 20
      logger.info "=========================works"
      @content.test_configurations.first.subject =   params[:message][:subject]
      @content.test_configurations.first.publish_and_send_message
    else
      @content.update_attribute(:status,6)
    end
    if @content.type == "Assessment"  or @content.type == "AssessmentHomeWork"
      user =  @content.asset.user
    else
      user =  @content.assets.first.user
    end
    #Content.send_message_to_est(user,current_user,@content)
    Content.send_message_to_teacher(user,current_user,@content,@message)
    redirect_to contents_path
  end

  #processed content rejected by EV or ET
  def reject
    @content = Content.find(params[:id])
    @content.update_attribute(:status,3)
    UserMailer.content_notification(@content.publisher,@content,"Content rejected").deliver
    redirect_to contents_path
  end

  #processed content published by EV or ET
  def publish
    @content = Content.find(params[:id])
#    case @content.type
#      when "Chapter"
#        url = "#{Rails.root.to_s}/public/archives/#{@content.board.name}_#{@content.content_year.name}/#{@content.subject.name}"
#      when "Topic"
#        url = "#{Rails.root.to_s}/public/archives/#{@content.board.name}_#{@content.content_year.name}/#{@content.subject.name}/#{@content.chapter.name}"
#      when "SubTopic"
#        url = "#{Rails.root.to_s}/public/archives/#{@content.board.name}_#{@content.content_year.name}/#{@content.subject.name}/#{@content.chapter.name}/#{@content.topic.name}"
#    end
#     path_url = @content.type == "Assessment"? @content.asset.url : @content.assets.first.url
#    file = File.expand_path("..",Rails.root.to_s+"/public/"+path_url.to_s)
#    FileUtils.cp_r file,url
#updated_index_xml(@content)
#@content.update_attribute(:status,4)
    if @content.type.eql?("Chapter") or @content.type.eql?("Topic") or @content.type.eql?("SubTopic") or @content.type.eql?("AssessmentHomeWork")
      redirect_to publish_content_teacher_path(@content)
    elsif @content.type?("Assessment")
      redirect_to assessment_test_configuration_path(@content)
    end
  end

  # Updating the subjects based on the content_year
  def get_subjects
    @content_year = ContentYear.find_by_name(params[:name].to_i) unless params[:name].blank?
    list = @content_year.subjects.map {|u| Hash[value: u.id, name: u.name]}
    render json: list
  end


  #Content usage reports
  def usage_reports

    @names,@counts,@durations,@max_Y = ""
    @usages = []
    per_page = 8
    #case current_user.role.name when 'Edutor Admin'
    @list =  Subject.page(params[:page]).per(per_page)
    #@usages = @list.map{|inst| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(inst.students)}
    @usages = @list.map{|subject| Usage.where("content_id like?","%/#{subject.code}/%").count}
    #end


    if @usages
      @names = @list.map{|subject| subject.name }.join(',')

      count_ary = @usages.map{|usage_count| usage_count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      #@url_append_ids = @list.map{|inst| inst.id.to_s+"_institutions"}.join(',')



      count_max = @usages.max
      #duration_max = duration_ary.map(&:to_i).max
      #@max_Y = count_max

      #count_max = count_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      #duration_max = duration_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      max_val = count_max

      max_YVal = 1.to_s.ljust(max_val.to_s.size+1, "0").to_i

      @max_Y = max_YVal
      @tick_Y =  (max_YVal/10)
      puts "count max ",count_max
      puts "=====max_y",@max_Y
      puts "========tick_Y",@tick_Y
    end
  end


  #catching and redirecting the download url
  def manage_download
    logger.info "in download manager"
    url = request.uri
    send_file url
  end






end
