class AssessmentHomeWorksController < ApplicationController
  authorize_resource
  # GET /AssessmentHomeWorks
  # GET /AssessmentHomeWorks.json
  def index
   unless current_user.is?"ET"
    @assessment_home_works =  AssessmentHomeWork.joins(:asset).where('assets.publisher_id = ?',current_user.id).default_order.page(params[:page])
   else
    @assessment_home_works =  current_user.contents.where(:type=>"AssessmentHomeWork").default_order.page(params[:page])
   end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_home_works }
    end
  end

  # GET /AssessmentHomeWorks/1
  # GET /AssessmentHomeWorks/1.json
  def show
   @assessment_home_work = AssessmentHomeWork.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_home_work }
    end
  end

  # GET /AssessmentHomeWorks/new
  # GET /AssessmentHomeWorks/new.json
  def new
   @assessment_home_work = AssessmentHomeWork.new
   @assessment_home_work.build_asset
   @assessment_home_work.build_content_profile
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_home_work }
    end
  end

  # GET /AssessmentHomeWorks/1/edit
  def edit
   @assessment_home_work = AssessmentHomeWork.find(params[:id])
  end

  # POST /AssessmentHomeWorks
  # POST /AssessmentHomeWorks.json
  def create
   @assessment_home_work = AssessmentHomeWork.new(params[:assessment_home_work])
   subject = Subject.find(params[:assessment_home_work][:subject_id]) rescue nil
    @assessment_home_work.board_id = subject.try(:board).try(:id)
    @assessment_home_work.content_year_id = subject.try(:content_year).try(:id)
    respond_to do |format|
      if @assessment_home_work.save
        if File.extname(@assessment_home_work.asset.attachment_file_name) == ".zip"
          extracting_zip_file(@assessment_home_work)
          path = Rails.root.to_s+"/tmp/cache/downloads/zip_home_work_#{@assessment_home_work.id}/"
          Dir.entries(path).sort.each do |d|
            if File.extname(d) =='.etx'
              @i  = 1
              break
            end
          end
          if @i == 1
            FileUtils.rm(Rails.root.to_s+'/public'+@assessment_home_work.asset.src.to_s,:force=>true)
            src = @assessment_home_work.asset.src.gsub(@assessment_home_work.asset.attachment_file_name,"")
            dest_path = Rails.root.to_s+"/public"+src
            FileUtils.cp_r "#{path}/.",dest_path
            flash[:notice]='Assessment HomeWork was successfully uploaded.'
            format.html { redirect_to  assessment_home_works_path }
            format.json { render json: @assessment_home_work, status: :created, location: @assessment_home_work }
          else
            @assessment_home_work.asset.delete
            @assessment_home_work.delete
            flash[:error]= "The zip file dosen't contain etx file"
            format.html { render action: "new" }
          end
        elsif  File.extname(@assessment_home_work.asset.attachment_file_name) == ".doc"  or File.extname(@assessment_home_work.asset.attachment_file_name) == ".docx"
          @assessment_home_work.update_attribute(:status,1)
          est = current_user.center.est
          Content.send_message_to_est(est,current_user,@assessment_home_work)
        else
           flash[:notice]='Assessment HomeWork was successfully uploaded.'
           format.html { redirect_to assessment_home_works_path }
           format.json { render json: @assessment_home_work, status: :created, location: @assessment_home_work }
        end
      else
        format.html { render action: "new" }
        format.json { render json: @assessment_home_work.errors, status: :unprocessable_entity }
      end
    end
  end

  #zip extration
  def extracting_zip_file(content)
    @extract_path =  Rails.root.to_s+"/tmp/cache/downloads/zip_home_work_#{content.id}"
    Zip::ZipFile.open(Rails.root.to_s+'/public'+content.asset.src.to_s) { |zip_file|
      zip_file.each { |f|
        puts f.name
        f_path=File.join(@extract_path, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f,f_path)    }
    }
end



  # PUT /AssessmentHomeWorks/1
  # PUT /AssessmentHomeWorks/1.json
  def update
   @assessment_home_work = AssessmentHomeWork.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_home_work][:status] = 6
    end
    respond_to do |format|
      if @assessment_home_work.update_attributes(params[:assessment_home_work])
        format.html { redirect_to@assessment_home_work, notice: 'AssessmentHomeWork was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_home_work.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentHomeWorks/1
  # DELETE /AssessmentHomeWorks/1.json
  def destroy
   @assessment_home_work = AssessmentHomeWork.find(params[:id])
   @assessment_home_work.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_home_works_url }
      format.json { head :ok }
    end
  end

  def publish_form
    @message = Message.new
  end


  def publish
    @assessment_home_work = AssessmentHomeWork.find(params[:id])

    puts "src==",@assessment_home_work.asset.src
    file = process_zip( @assessment_home_work, @assessment_home_work.asset)
    @message = Message.new(params[:message])
    @message_asset = @message.assets.build
    @message_asset.attachment = File.open(file,"rb")
    @message.message_type = "Content"
    @message.label =  @assessment_home_work.type
    @message.body = params[:message][:body]+"$:#{@assessment_home_work.uri}"
    @message.save
    @attachments_json_ary = []
    @attachments_json_ary << {:file_info=>{:path=>@message.assets.first.url,:name=>@message.assets.first.name,:type=>@assessment_home_work.asset.archive_type,:size=>@message.assets.first.file_size}}
    @message.attachments = @attachments_json_ary
    @message.save
    FileUtils.remove_dir(Rails.root.to_s+"/tmp/cache/downloads/home_work_#{@assessment_home_work.id}",:force=>true)
    FileUtils.rm(Rails.root.to_s+"/tmp/cache/downloads/home_work_#{@assessment_home_work.id}.zip",:force=>true)

    if @assessment_home_work.status == 0 or @assessment_home_work.status == 6
      @assessment_home_work.update_attribute(:status,4)
    end

    redirect_to assessment_home_works_url, notice: 'homework was successfully published.'
  end

  def process_zip(content,asset)
    path = Rails.root.to_s+"/tmp/cache/downloads/home_work_#{content.id}"
    src = asset.src
    src = src.gsub(asset.attachment_file_name,"")
    folder_path = path+src
    file_path = Rails.root.to_s+"/public"+src
    FileUtils.mkdir_p folder_path
    FileUtils.cp_r "#{file_path}/.",folder_path
    generate_ncx(content,path)
  end

  def generate_ncx(content,path)
    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum", :class=>"curriculum"){
          xml.content(:src=>"curriculum")

          # Changed By Nrupul for the new type of NCX
          xml.navPoint(:id=>"Content",:class=>"content"){
            xml.content(:src=>"content")
            xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
              xml.content(:src=>content.subject.board.code+"_"+content.asset.publisher_id.to_s, :params=>content.subject.board.params)
              xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                xml.content(:src=>content.subject.content_year.code, :params=>content.subject.content_year.params)
                
                # The code for handling the data if the subject has a subject as a parent
                      if !content.subject.subject_id.nil?
                        xml.navPoint(:id=>content.subject.parent_subject.name,:class=>"subject")
                        xml.content(:src=>content.subject.parent_subject.code, :params=>content.subject.parent_subject.params)
                      end
                    # End of code for handling the data if the subject has a subject as a parent
                    
                xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                  xml.content(:src=>content.subject.code, :params=>content.subject.params)

                  # Handling the case if chapter, topic and sub topic are NULL
                  if !content.subject_id.nil? and content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                  xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"assessment-home-work",:submitTime=>content.content_profile.expiry_date.to_i*1000, :container_type => "homework"){
                    if File.extname(content.asset.attachment_file_name) == ".zip"
                      Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                        if File.extname(d) =='.etx'
                          @name  = d
                          break
                        end
                      end
                      xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.subject.params)
                    else
                      xml.content(:src=>content.asset.src, :params=>content.subject.params)
                    end
                  }
                  end

                  # Handling the case if topic and sub topic are NULL
                  if !content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                    xml.navPoint(:id=>content.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.chapter.assets.first.src, :params=>content.chapter.params)
                        xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"assessment-home-work",:submitTime=>content.content_profile.expiry_date.to_i*1000, :container_type => "homework", :playOrder=>content.chapter.play_order){
                          if File.extname(content.asset.attachment_file_name) == ".zip"
                            Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                              if File.extname(d) =='.etx'
                                @name  = d
                                break
                              end
                            end
                            xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.chapter.params)
                          else
                            xml.content(:src=>content.asset.src, :params=>content.chapter.params)
                          end
                        }
                    }

                  end

                  # Handling the case if sub topic is NULL
                  if !content.topic_id.nil?  and !content.chapter_id.nil? and content.sub_topic_id.nil?
                    xml.navPoint(:id=>content.topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.topic.chapter.assets.first.src, :params=>content.chapter.params)
                        xml.navPoint(:id=>content.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"general-home-work",:submitTime=>content.content_profile.expiry_date.to_i*1000*1000, :container_type => "homework", :playOrder=>content.topic.play_order){
                            if File.extname(content.asset.attachment_file_name) == ".zip"
                              Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                if File.extname(d) =='.etx'
                                  @name  = d
                                  break
                                end
                              end
                              xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.topic.params)
                            else
                              xml.content(:src=>content.asset.src, :params=>content.topic.params)
                            end
                          }
                        }
                      }

                  end

                  # Handling the case if all are present
                  if !content.sub_topic_id.nil? and !content.chapter_id.nil? and !content.topic_id.nil?
                    xml.navPoint(:id=>content.sub_topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                       xml.content(:src=>content.sub_topic.chapter.assets.first.src, :params=>content.chapter.params)
                        xml.navPoint(:id=>content.sub_topic.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.sub_topic.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.sub_topic.name, :class=>"subtopic", :playOrder=>content.sub_topic.play_order){
                            xml.content(:src=>content.sub_topic.assets.first.src, :params=>content.sub_topic.params)
                            xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"general-home-work",:submitTime=>content.content_profile.expiry_date.to_i*1000, :container_type => "homework", :playOrder=>content.sub_topic.play_order){
                              if File.extname(content.asset.attachment_file_name) == ".zip"
                                Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                  if File.extname(d) =='.etx'
                                    @name  = d
                                    break
                                  end
                                end
                                xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.sub_topic.params)
                              else
                                xml.content(:src=>content.asset.src, :params=>content.sub_topic.params)
                              end
                            }


                          }
                        }
                     }
                  end
                }
              }
            }
          }
          # End of change by Nrupul for the new type of NCX

          xml.navPoint(:id=>"HomeWork",:class=>"home-work"){
            xml.content(:src=>"homework")
            xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
              xml.content(:src=>content.subject.board.code+"_"+content.asset.publisher_id.to_s, :params=>content.subject.board.params)
              xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                xml.content(:src=>content.subject.content_year.code, :params=>content.subject.content_year.params)
                
                # The code for handling the data if the subject has a subject as a parent
                      if !content.subject.subject_id.nil?
                        xml.navPoint(:id=>content.subject.parent_subject.name,:class=>"subject")
                        xml.content(:src=>content.subject.parent_subject.code, :params=>content.subject.parent_subject.params)
                      end
                    # End of code for handling the data if the subject has a subject as a parent
                    
                xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                  xml.content(:src=>content.subject.code,:params=>content.subject.params)

                  # Handling the case if chapter, topic and sub topic are NULL
                  if !content.subject_id.nil? and content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                  xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"general-home-work",:submitTime=>content.content_profile.expiry_date.to_i*1000, :prerequiste=>content.subject.uri){
                    if File.extname(content.asset.attachment_file_name) == ".zip"
                      Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                        if File.extname(d) =='.etx'
                          @name  = d
                          break
                        end
                      end
                      xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.subject.params)
                    else
                      xml.content(:src=>content.asset.src, :params=>content.subject.params)
                    end
                  }
                  end

                  # Handling the case if topic and sub topic are NULL
                  if !content.chapter_id.nil? and content.topic_id.nil? and content.sub_topic_id.nil?
                    xml.navPoint(:id=>content.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.chapter.assets.first.src,:params=>content.chapter.params)
                        xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"general-home-work",:submitTime=>content.content_profile.expiry_date.to_i*1000, :prerequiste=>content.chapter.uri, :playOrder=>content.chapter.play_order){
                          if File.extname(content.asset.attachment_file_name) == ".zip"
                            Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                              if File.extname(d) =='.etx'
                                @name  = d
                                break
                              end
                            end
                            xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.chapter.params)
                          else
                            xml.content(:src=>content.asset.src, :params=>content.chapter.params)
                          end
                        }
                    }
                  end

                  # Handling the case if sub topic is NULL
                  if !content.topic_id.nil?  and !content.chapter_id.nil? and content.sub_topic_id.nil?
                    xml.navPoint(:id=>content.topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                        xml.content(:src=>content.topic.chapter.assets.first.src,:params=>content.chapter.params)
                        xml.navPoint(:id=>content.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"general-home-work",:submitTime=>content.content_profile.expiry_date.to_i*1000, :prerequiste=>content.topic.uri, :playOrder=>content.topic.play_order){
                            if File.extname(content.asset.attachment_file_name) == ".zip"
                              Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                if File.extname(d) =='.etx'
                                  @name  = d
                                  break
                                end
                              end
                              xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.topic.params)
                            else
                              xml.content(:src=>content.asset.src, :params=>content.topic.params)
                            end
                          }
                        }
                      }
                  end

                  # Handling the case if all are present
                  if !content.sub_topic_id.nil? and !content.chapter_id.nil? and !content.topic_id.nil?
                    xml.navPoint(:id=>content.sub_topic.chapter.name, :class=>"chapter", :playOrder=>content.chapter.play_order){
                       xml.content(:src=>content.sub_topic.chapter.assets.first.src,:params=>content.chapter.params)
                        xml.navPoint(:id=>content.sub_topic.topic.name, :class=>"topic", :playOrder=>content.topic.play_order){
                          xml.content(:src=>content.sub_topic.topic.assets.first.src, :params=>content.topic.params)
                          xml.navPoint(:id=>content.sub_topic.name, :class=>"subtopic", :playOrder=>content.sub_topic.play_order){
                            xml.content(:src=>content.sub_topic.assets.first.src, :params=>content.sub_topic.params)
                            xml.navPoint(:id=>content.uri.split('/').last, :displayName => content.name, :class=>File.extname(content.asset.attachment_file_name) == ".zip" ? "assessment-practice-tests" :"general-home-work", :submitTime=>content.content_profile.expiry_date.to_i*1000, :prerequiste=>content.sub_topic.uri, :playOrder=>content.sub_topic.play_order){
                              if File.extname(content.asset.attachment_file_name) == ".zip"
                                Dir.entries(Rails.root.to_s+"/public"+content.asset.src.gsub(content.asset.attachment_file_name,"")).sort.each do |d|
                                  if File.extname(d) =='.etx'
                                    @name  = d
                                    break
                                  end
                                end
                                xml.content(:src=>content.asset.src.gsub(content.asset.attachment_file_name,"")+@name, :params=>content.sub_topic.params)
                              else
                                xml.content(:src=>content.asset.src, :params=>content.sub_topic.params)
                              end
                            }
                          }
                        }
                     }
                  end


                 }
              }
            }
          }
        }
      }
    end
    xml_string =  @builder.to_xml.to_s
    file = File.new(path+"/"+"index.ncx", "w+")
    File.open(file,'w') do |f|
      f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
    end
    create_zip("home_work_#{content.id}",path)
  end


end