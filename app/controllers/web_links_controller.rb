class WebLinksController < ApplicationController
  authorize_resource #:only=>[:edit, :index, :new, :show]
  def index
    #@web_links =  WebLink.where('extras !=?','NULL').page(params[:page])
    @web_links = case current_user.role.name
                  when 'Edutor Admin'
                    WebLink.where('extras !=?','NULL').page(params[:page])
                  when 'Institute Admin'
                    WebLink.where('extras !=?','NULL').where(:board_id=>current_user.institution.board_ids).page(params[:page])
                  when 'Center Representative'
                    WebLink.where('extras !=?','NULL').where(:board_id=>current_user.center.board_ids).page(params[:page])
                  when 'Teacher'
                    WebLink.where('extras !=?','NULL').where(:board_id=>current_user.center.board_ids).page(params[:page])
                  else
                    WebLink.where('extras !=?','NULL').page(params[:page])
                end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @web_links }
    end
  end

  # GET /WebLinks/1
  # GET /WebLinks/1.json
  def show
    @web_link = WebLink.find(params[:id])
    if !@web_link.web_link_video.nil?
      @web_link = WebLink.includes(:web_link_video).find(params[:id])
    end
    if !@web_link.web_link_flash.nil?
      @web_link = WebLink.includes(:web_link_flash).find(params[:id])
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @web_link }
    end
  end

  # GET /WebLinks/new
  # GET /WebLinks/new.json
  def new
    params_hash = {board_id: params[:board_id],content_year_id: params[:content_year_id],subject_id: params[:subject_id]}
    @web_link = WebLink.new(params_hash)
    @web_link.build_web_link_video
    @web_link.build_web_link_flash
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @web_link }
    end
  end

  # GET /WebLinks/1/edit
  def edit
    @web_link = WebLink.find(params[:id])
  end

  # POST /WebLinks
  # POST /WebLinks.json
  def create
    if current_user.is?("ET")
      @content = Content.find(params[:web_link][:subject_id])
      params[:web_link][:board_id] = @content.board_id
      params[:web_link][:content_year_id]= @content.content_year_id
    end
    @web_link = WebLink.new(params[:web_link])
    @web_link.extras = params[:web_link][:extras].gsub('https','http')
    if params[:link_type] == "video" || params[:link_type] == "flash"
      if params[:link_type] == "video"
        @web_link_video = @web_link.build_web_link_video(params[:web_link][:web_link_video_attributes])
      else
        @web_link_flash = @web_link.build_web_link_flash(params[:web_link][:web_link_flash_attributes])
      end
    end

    respond_to do |format|
      if @web_link.save
        format.html { redirect_to  @web_link, notice: 'WebLink was successfully created.' }
        format.json { render json: @web_link, status: :created, location: @web_link }
      else
        format.html { render action: "new" }
        format.json { render json: @web_link.errors, status: :unprocessable_entity }
      end
    end
  end

# PUT /WebLinks/1
# PUT /WebLinks/1.json
  def update
    @web_link = WebLink.find(params[:id])
    respond_to do |format|
      if @web_link.update_attributes(params[:chapter])
        if @web_link.status == 6
          Content.send_message_to_est(@web_link.vendor,current_user,@web_link)
        end
        format.html { redirect_to @web_link, notice: 'WebLink was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @web_link.errors, status: :unprocessable_entity }
      end
    end
  end

# DELETE /WebLinks/1
# DELETE /WebLinks/1.json
  def destroy
    @web_link = WebLink.find(params[:id])
    @web_link.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to chapters_url }
      format.json { head :ok }
    end
  end


  def publish_form
    @web_link = WebLink.find(params[:id])
    @message = Message.new
  end

  def publish_message
    @web_link = WebLink.find(params[:id])
    if !@web_link.web_link_video.nil?
      @web_link_video = @web_link.web_link_video
    else !@web_link.web_link_flash.nil?
      @web_link_flash = @web_link.web_link_flash
    end

    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum", :class=>"curriculum"){
          xml.content(:src=>"curriculum")
          xml.navPoint(:id=>"Content",:class=>"content"){
            xml.content(:src=>"content")
            xml.navPoint(:id=>@web_link.subject.board.name,:class=>"course"){
              xml.content(:src=>@web_link.subject.board.code+"_02")
              xml.navPoint(:id=>@web_link.subject.content_year.name,:class=>"academic-class"){
                xml.content(:src=>@web_link.subject.content_year.code)
                # The code for handling the data if the subject has a subject as a parent
                if !@web_link.subject.subject_id.nil?
                  xml.navPoint(:id=>@web_link.subject.parent_subject.name,:class=>"subject")
                  xml.content(:src=>@web_link.subject.parent_subject.code)
                end
                # End of code for handling the data if the subject has a subject as a parent

                xml.navPoint(:id=>@web_link.subject.name,:class=>"subject"){
                  xml.content(:src=>@web_link.subject.code)

                  if !@web_link.chapter_id.nil? and @web_link.topic_id.nil? and @web_link.sub_topic_id.nil?
                    xml.navPoint(:id=>@web_link.chapter.name, :class=>"chapter",:playOrder=>@web_link.chapter.play_order.nil? ? 0 :@web_link.chapter.play_order){
                      xml.content(:src=>@web_link.chapter.assets.first.src)
                      if !@web_link.web_link_video.nil? or !@web_link.web_link_flash.nil?
                        if !@web_link.web_link_video.nil?
                          xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                            xml.content(:src=>"/#{@web_link_video.attachment_file_name}",:params=>@web_link.params)
                          }
                        end
                        if !@web_link.web_link_flash.nil?
                          xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                            xml.content(:src=>"/#{@web_link_flash.attachment_file_name}",:params=>@web_link.params)
                          }
                        end
                      else
                        xml.navPoint(:id=>@web_link.uri.split('/').last, :displayName => @web_link.name, :class=>"weblink"){
                          xml.content(:src=>@web_link.extras,:params=>@web_link.params)
                        }
                      end
                    }
                  elsif !@web_link.topic_id.nil?  and !@web_link.chapter_id.nil? and @web_link.sub_topic_id.nil?
                    xml.navPoint(:id=>@web_link.topic.chapter.name, :class=>"chapter",:playOrder=>@web_link.chapter.play_order.nil? ? 0 :@web_link.chapter.play_order){
                      xml.content(:src=>@web_link.topic.chapter.assets.first.src)
                      xml.navPoint(:id=>@web_link.topic.name, :class=>"topic",:playOrder=>@web_link.topic.play_order.nil? ? 0 :@web_link.topic.play_order){
                        xml.content(:src=>@web_link.topic.assets.first.src)
                        if !@web_link.web_link_video.nil? or !@web_link.web_link_flash.nil?
                          if !@web_link.web_link_video.nil?
                            xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                              xml.content(:src=>"/#{@web_link_video.attachment_file_name}",:params=>@web_link.params)
                            }
                          end
                          if !@web_link.web_link_flash.nil?
                            xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                              xml.content(:src=>"/#{@web_link_flash.attachment_file_name}",:params=>@web_link.params)
                            }
                          end
                        else
                          xml.navPoint(:id=>@web_link.uri.split('/').last, :displayName => @web_link.name, :class=>"weblink"){
                            xml.content(:src=>@web_link.extras,:params=>@web_link.params)
                          }
                        end
                      }
                    }
                  elsif !@web_link.sub_topic_id.nil? and !@web_link.chapter_id.nil? and !@web_link.topic_id.nil?
                    xml.navPoint(:id=>@web_link.sub_topic.chapter.name, :class=>"chapter"){
                      xml.content(:src=>@web_link.sub_topic.chapter.assets.first.src)
                      xml.navPoint(:id=>@web_link.sub_topic.topic.name, :class=>"topic"){
                        xml.content(:src=>@web_link.sub_topic.topic.assets.first.src)
                        xml.navPoint(:id=>@web_link.sub_topic.name, :class=>"subtopic"){
                          xml.content(:src=>@web_link.sub_topic.assets.first.src)
                          if !@web_link.web_link_video.nil? or !@web_link.web_link_flash.nil?
                            if !@web_link.web_link_video.nil?
                              xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                                xml.content(:src=>"/#{@web_link_video.attachment_file_name}",:params=>@web_link.params)
                              }
                            end
                            if !@web_link.web_link_flash.nil?
                              xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                                xml.content(:src=>"/#{@web_link_flash.attachment_file_name}",:params=>@web_link.params)
                              }
                            end
                          else
                            xml.navPoint(:id=>@web_link.uri.split('/').last, :displayName => @web_link.name, :class=>"weblink"){
                              xml.content(:src=>@web_link.extras,:params=>@web_link.params)
                            }
                          end
                        }
                      }
                    }
                  else
                    if !@web_link.web_link_video.nil? or !@web_link.web_link_flash.nil?
                      if !@web_link.web_link_video.nil?
                        xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                          xml.content(:src=>"/#{@web_link_video.attachment_file_name}",:params=>@web_link.params)
                        }
                      end
                      if !@web_link.web_link_flash.nil?
                        xml.navPoint(:id=>@web_link.name, :displayName => @web_link.name, :class=>"animation"){
                          xml.content(:src=>"/#{@web_link_flash.attachment_file_name}",:params=>@web_link.params)
                        }
                      end
                    else
                      xml.navPoint(:id=>@web_link.uri.split('/').last, :displayName => @web_link.name, :class=>"weblink"){
                        xml.content(:src=>@web_link.extras,:params=>@web_link.params)
                      }
                    end
                  end
                }
              }
            }
          }
        }
      }
    end

    path = Rails.root.to_s+"/tmp/cache/web_links/"+Time.now.to_i.to_s
    FileUtils.mkdir_p path
    index_file = File.new(path+"/index.ncx", "w")
    File.open(path+"/index.ncx",  "w+b", 0644) do |f|
      f.write(@builder.to_xml.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><') )
    end

    attachment_file = "#{Rails.root.to_s}/tmp/cache/web_links/#{@web_link.name}_#{Time.now.to_i.to_s}.zip"

    if !@web_link.web_link_video.nil?
      animation_file = "#{Rails.root.to_s}/public/weblinks/video/#{@web_link_video.id}/#{@web_link_video.attachment_file_name}"
    end
    if !@web_link.web_link_flash.nil?
      animation_file = "#{Rails.root.to_s}/public/weblinks/flash/#{@web_link_flash.id}/#{@web_link_flash.attachment_file_name}"
    end

    Archive::Zip.archive(attachment_file, "#{path}/.")
    if !@web_link.web_link_video.nil? or !@web_link.web_link_flash.nil?
      Archive::Zip.archive(attachment_file, animation_file)
    end
    attachment = File.new(attachment_file,'r')

    @multiple_receiver_ids = params[:message][:multiple_recipient_ids].split(',')
    unless @multiple_receiver_ids.empty?
      @multiple_receiver_ids.each do |i|
        @message = Message.new(params[:message])
        @message.recipient_id =  i.to_i #params[:quiz_targeted_group][:group_id]
        @message.sender_id = current_user.id
        @message.body = "$:#{@web_link.uri}"
        @message.message_type = 'Content'
        @message.subject = @web_link.name
        @asset = @message.assets.build
        @asset.attachment = attachment
        @message.save
      end
    else
      @message = Message.new(params[:message])
      @message.group_id =  params[:quiz_targeted_group][:group_id]
      @message.sender_id = current_user.id
      @message.body =  "$:#{@web_link.uri}"
      @message.message_type = 'Content'
      @message.subject = @web_link.name
      @asset = @message.assets.build
      @asset.attachment = attachment
      @message.save
    end
    respond_to do |format|
      format.html { redirect_to web_links_url }
    end

  end

end
