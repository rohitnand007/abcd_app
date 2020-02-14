class TeachersController < ApplicationController
  authorize_resource
  # GET /teachers
  # GET /teachers.json
  def index
    require "DataTable"
    @teachers = case current_user.rc
                  when 'EA'
                    Teacher.includes(:profile).page(params[:page])
                  when 'IA','EO'
                    current_user.institution.teachers.includes(:profile).page(params[:page])
                  when 'MOE'
                    current_user.institution.teachers.includes(:profile).page(params[:page])
                  when 'CR'
                    if params[:mode].present?
                      User.where(:id=>current_user.teachers.select('id').select{|teacher| teacher.incomplete_class_details? }.flatten).includes(:profile).page(params[:page])
                    else
                      current_user.teachers.includes([:profile,{:center=>:profile},:teacher_class_rooms]).page(params[:page])
                    end

                end
    #New Changes for Datatable
    if request.xhr?
      data = DataTable.new(current_user)
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      globalSearchParams = params[:search_term]
      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], Teacher.count)
      teachers =  case current_user.rc
                    when 'EA'
                      Teacher.includes(:profile).where("rollno like :search or profiles.firstname like :search or profiles.surname like :search or profiles.middlename like :search", search: "%#{searchParams}%")
                    when 'IA','EO'
                      center_ids = Center.includes(:profile).where("profiles.firstname like :search or profiles.surname like :search or profiles.middlename like :search", search: "%#{searchParams}%").map(&:id)
                      t=current_user.institution.teachers.includes(:profile)
                      unless center_ids.present?
                        t.where("rollno like :search or profiles.firstname like :search or profiles.surname like :search or profiles.middlename like :search", search: "%#{searchParams}%")
                      else
                        t.where(center_id: center_ids)
                      end
                    when 'MOE'
                      current_user.institution.teachers.includes(:profile).where("rollno like :search or profiles.firstname like :search or profiles.surname like :search or profiles.middlename like :search", search: "%#{searchParams}%")
                    when 'CR'
                      if params[:mode].present?
                        User.where(:id=>current_user.teachers).includes(:profile).where("rollno like :search or profiles.firstname like :search or profiles.surname like :search or profiles.middlename like :search", search: "%#{searchParams}%")
                      else
                        current_user.teachers.includes([:profile,{:center=>:profile}]).where("rollno like :search or profiles.firstname like :search or profiles.surname like :search or profiles.middlename like :search", search: "%#{searchParams}%")
                      end

                  end
      if params[:sectionId].present?
        teachers = Teacher.includes(:profile).where(:section_id => params[:sectionId])
      end
      #including Global Search
      teachers = teachers.where("edutorid like :search or rollno like :search or profiles.firstname like :search or profiles.middlename like :search or profiles.surname like :search", search: "%#{globalSearchParams}%")
      total_teachers = teachers.count
      teachers = teachers.page(data.page).per(data.per_page)
      data.set_total_records(total_teachers)
      #Sorting Records
      columns = ["profiles.firstname"]
      if(params[:iSortCol_0].present?)
        column = columns[params[:iSortCol_0].to_i]
        direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
        teachers = teachers.order(column + " " +  direction)
      end
      #Mapping Records as hash
      teachers.map!.with_index do |teacher, index|

        # %tr{:class => cycle("tr-odd", "tr-even"),:id=>"teacher_#{teacher.id}"}
        #     %td.col
        #       = image_tag('web-app-theme/icons/cross.png',:alt => 'Incomplete',:title=>'Incomplete class details') if teacher.incomplete_class_details?
        #       = link_to teacher.name, teacher_path(teacher)
        #     %td.col= teacher.center.try(:name)
        #     %td.col= teacher.edutorid
        #     %td.col= display_date_time(teacher.created_at)
        #     %td.col
        #       = link_to_show(teacher_path(teacher))
        #       -#= link_to_edit(edit_teacher_path(teacher))
        #       -#=link_to_delete(teacher_path(teacher))
        zeroth_column = []
        # if(teacher.incomplete_class_details?)
        #   zeroth_column << view_context.image_tag('web-app-theme/icons/cross.png',:alt => 'Incomplete',:title=>'Incomplete class details')
        # end
        zeroth_column << view_context.link_to(teacher.name, view_context.teacher_path(teacher))
        row_class = index%2==0 ? "tr-even" : "tr-odd"
        {
            "DT_RowId" => "teacher_#{teacher.id}",
            "DT_RowClass" => row_class,
            "0" => zeroth_column,
            "1" => teacher.center.try(:name),
            "2" => teacher.edutorid,
            "3" => teacher.rollno,
            "4" => view_context.display_date_time(teacher.created_at),
            "5" => view_context.link_to_show(view_context.teacher_path(teacher))
        }
      end
    end
    #New Changes for Datatable
    respond_to do |format|
      format.html # index.html.erb
      if request.xhr?
        format.json {render json: data.as_json(teachers)}
      else
        format.json { render json: @teachers }
      end
    end
  end

  # GET /teachers/1
  # GET /teachers/1.json
  def show
    @teacher = Teacher.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @teacher }
    end
  end

  # GET /teachers/new
  # GET /teachers/new.json
  def new
    params_hash = {institution_id: params[:institution_id],
                   center_id: params[:center_id],
                   academic_class_id: params[:academic_class_id],section_id: params[:section_id]}
    @teacher = Teacher.new(params_hash)
    @teacher.user_groups.build
    @teacher.build_profile
    @teacher.class_rooms.build
    @teacher.devices.build
    #1.times do @teacher.class_rooms.build end #TODO for temporary

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @teacher }
    end
  end

  # GET /teachers/1/edit
  def edit
    @teacher = Teacher.includes(:institution,:center,:academic_class,:section,:user_groups,:class_rooms).find(params[:id])
    @teacher.devices.build if @teacher.devices.empty?
  end

  # POST /teachers
  # POST /teachers.json
  def create
    teacher_groups_token_ids #to enroll the groups through classrooms too
    @teacher = Teacher.new(params[:teacher])

    respond_to do |format|
      if @teacher.save
        format.html { redirect_to @teacher, notice: 'Teacher was successfully created.' }
        format.json { render json: @teacher, status: :created, location: @teacher }
      else
        # @teacher.build_profile unless @teacher.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /teachers/1
  # PUT /teachers/1.json
  def update
    @teacher = Teacher.find(params[:id])
    teacher_groups_token_ids #to enroll the groups through classrooms too
    respond_to do |format|
      if @teacher.update_attributes(params[:teacher])
        format.html { redirect_to @teacher, notice: 'Teacher was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /teachers/1
  # DELETE /teachers/1.json
  def destroy
    @teacher = Teacher.find(params[:id])
    #@teacher.destroy
    @teacher.is_activated? ? @teacher.update_attribute(:is_activated,false) : @teacher.update_attribute(:is_activated,true)
    respond_to do |format|
      format.html { redirect_to teachers_url }
      format.json { head :ok }
    end
  end

  def my_students
    get_users
  end

  def get_users
    @teacher = Teacher.find(params[:id])
    group = User.find(params[:group_id])

    if group.type.eql?'StudentGroup'
      @users = group.inverse_groups.students.search_includes.page(params[:page])
    else
      @users = group.students.search_includes.page(params[:page])
    end
  end

  def update_activation_status
    if request.xhr?
      case params[:mode]
        when 'EN'
          if params[:status].eql?"Enroll"
            #after creating the message the user enroll status will be updated  by callback in message model
            User.send_messages(params[:user_ids].split(','),current_user.id,"Enroll")
          else
            #after creating the message the user enroll status will be updated  by callback in message model
            User.send_messages(params[:user_ids].split(','),current_user.id,"De-Enroll")
          end
      end
      # @users = get_users
      respond_to do |format|
        format.js{}
      end
    end
  end

  def my_students_report

    @names,@counts,@durations,@max_Y = ""
    @usages = []
    per_page = 3
    @teacher = Teacher.find(params[:id])
    group = User.find(params[:group_id])

    #group will be the section or student group.then for this we need to get the classroom object to get the teacher content

    unless group.type.eql?'AcademicClass'
      class_room_group = @teacher.teacher_class_rooms.find_by_group_id(group)
      class_room_group_contents = (class_room_group.content.type.eql?'Board' or class_room_group.content.type.eql?'ContentYear') ? class_room_group.content.subjects : [class_room_group.content]
      teacher_group_subject_uris = class_room_group_contents.map(&:uri) rescue []
    end




    if group.type.eql?'StudentGroup'
      @list =  group.inverse_groups.students.includes(:profile).page(params[:page]).per(per_page)
      @names = @list.map{|std| std.name}.join(',')
    else
      @list =  group.students.includes(:profile).page(params[:page]).per(per_page)
      @names = @list.map{|std| std.name}.join(',')
    end

    if group.type.eql?'AcademicClass'
      @usages = @list.map{|std| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(std.id)}
    else

      # @list.map{|std|
      #result = teacher_group_subject_uris.map{|uri| Usage.where('user_id=? and uri like ?', std.id,"%#{uri}%").select('sum(count) as count,sum(duration)/60 as duration').group('uri')}
      #@usages << ((result.blank?) ? [] : result.flatten)
      #}
      @usages = @list.map{|std|
        teacher_group_subject_uris.map{|uri|
          usage=Usage.where('uri like ?', "%#{uri}%").select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(std.id)
          usage if !usage.duration.nil? and !usage.count.nil?
        }.compact.flatten
      }
      @usages = @usages.map{|usage| (usage.empty? ? nil: usage.first)}
    end


    if @usages

      count_ary = @usages.map{|usage| usage.count.to_s unless usage.nil?}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @list.map{|std| std.id.to_s+"_users"}.join(',')

      duration_ary = @usages.map{|usage| usage.duration.to_s unless usage.nil?}
      @durations = duration_ary.join(',')

      #count_max = count_ary.map(&:to_i).max
      #duration_max = duration_ary.map(&:to_i).max
      #@max_Y = count_max > duration_max ? count_max : duration_max

      count_max = count_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      duration_max = duration_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      max_val = count_max > duration_max ? count_max : duration_max rescue 0

      max_YVal = 1.to_s.ljust(max_val.to_s.size+1, "0").to_i

      @max_Y = max_YVal
      @tick_Y =  (max_YVal/10)


    end

    render 'home/result'

  end

  def check_reports
    @teacher = Teacher.find(params[:id])
  end

  def teacher_groups_token_ids
    if params[:teacher][:teacher_class_rooms_attributes]
      unless params[:teacher][:teacher_class_rooms_attributes].keys.blank?
        group_ids = params[:teacher][:group_tokens].split(',')
        #params[:teacher][:group_ids] = []
        params[:teacher][:group_ids] = group_ids
        params[:teacher][:teacher_class_rooms_attributes].keys.each do |class_room|
          params[:teacher][:group_ids] << params[:teacher][:teacher_class_rooms_attributes][class_room][:group_id]
        end
      end
    end
  end


  def get_academic_classes
    teacher = Teacher.find(params[:teacher_id])

    academic_classes = teacher.groups.map{|a|  a.academic_class_id.nil? ? a.id : a.academic_class_id}
    academic_classes << teacher.academic_class_id


    @academic_class_profiles = Profile.find_all_by_user_id(academic_classes).map{|profile| Hash[value: profile.user_id,name: profile.firstname]}
    respond_to do |format|
      format.json {render json: @academic_class_profiles}
    end
  end

  # Displaying teacher contents
  def contents
    @contents = Content.where(:id=>current_user.contents.map(&:id),:type=>['Chapter','Topic','SubTopic']).page(params[:page])
  end

  # Displaying teacher classroom subjects
  def my_subjects
    @subjects = Content.where(:id=>current_user.class_contents.map(&:id)).page(params[:page])
  end

  #publishing the teacher created content to tab
  def publish_content
    @content = Content.find(params[:id])
    @message = Message.new
  end

  def send_publish_content_message
    begin
      ActiveRecord::Base.transaction do
        @content = Content.find(params[:id])
        @message = Message.new(params[:message])
        @message.body = params[:message][:body]+"$:#{@content.create_uri}"
        @message.message_type = "Content"
        @message.save
        #@message.assets.create(:attachment=>File.new(Rails.root.to_s+"/public"+@content.assets.first.attachment.url,'r'))
        asset =  (@content.type == "Assessment" or @content.type == "AssessmentHomeWork")? @content.asset : @content.assets.first
        if File.extname(asset.attachment_file_name) == ".zip"
          @message.assets.create(:attachment=>File.new(Rails.root.to_s+"/public"+asset.src,'r'))
        else
          file = process_zip(@content,asset)
          @message.assets.create(:attachment=>File.new(file,'r'))
        end
        @content.update_attribute(:status,4) #setting the status to publish
      end
    rescue Exception => e
      puts "Exception in uploading...............#{e.message}"
      logger.info "Exception in uploading...............#{e}"
      flash[:error] = "#{e.message}"
    end
    redirect_to  teacher_contents_path
  end



  def process_zip(content,asset)
    path = Rails.root.to_s+"/tmp/cache/downloads/content_#{content.id}"
    src = asset.src
    logger.info "==#{src}"
    src = src.gsub(asset.attachment_file_name,"")
    logger.info "==#{src}"
    folder_path = path+src
    file_path = Rails.root.to_s+"/public"+src
    logger.info "==#{file_path}"
    FileUtils.mkdir_p folder_path
    FileUtils.cp_r "#{file_path}/.",folder_path
    generate_ncx(content,path)
  end

  def generates_ncx(content,path)
    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum", :class=>"curriculum"){
          xml.content(:src=>"curriculum")
          xml.navPoint(:id=>"Content",:class=>"content"){
            xml.content(:src=>"content")
            xml.navPoint(:id=>content.board.name,:class=>"course"){
              xml.content(:src=>content.board.code+"_"+content.assets.first.publisher_id.to_s)
              xml.navPoint(:id=>content.content_year.name,:class=>"academic-class"){
                xml.content(:src=>content.content_year.name)
                xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                  xml.content(:src=>content.subject.code)
                  case content.type when "Chapter"
                                      xml.navPoint(:id=>content.name,:class=>"chapter",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                                        xml.content(:src=>content.assets.first.src)
                                      }
                    when "Topic"
                      xml.navPoint(:id=>content.name,:class=>"chapter",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                        xml.content(:src=>content.assets.first.src)
                        xml.navPoint(:id=>content.name, :class=>"topic",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                          xml.content(:src=>content.assets.first.src)
                        }
                      }
                    when "SubTopic"
                      xml.navPoint(:id=>content.name,:class=>"chapter",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                        xml.content(:src=>content.assets.first.src)
                        xml.navPoint(:id=>content.name, :class=>"topic",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                          xml.content(:src=>content.assets.first.src)
                          xml.navPoint(:id=>content.name, :class=>"sub-topic",:playOrder=>content.play_order.nil? ? 0 :content.play_order){
                            xml.content(:src=>content.assets.first.src)
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
    create_zip("assessment_#{content.id}",path)
  end


  def logout
    sign_out(current_user)
    redirect_to '/teacher_quizzes'
  end

end
