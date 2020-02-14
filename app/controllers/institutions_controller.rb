class InstitutionsController < ApplicationController
  authorize_resource
  #caches_action :index

  # GET /institutions
  # GET /institutions.json
  def index
    require "DataTable"
    @institutions = case current_user.rc
                      when 'EA'
                        Institution.includes(:profile).order('profiles.firstname').page(params[:page])
                      when 'IA'
                        Institution.includes(:profile).where(:id=>current_user.institution).order('profiles.firstname').page(params[:page])
                    end

    if request.xhr?
      institutions = case current_user.rc
                          when 'EA'
                            Institution.includes(:profile)
                          when 'IA'
                            Institution.includes(:profile).where(:id => current_user.institution)
                      end
      dataTable = DataTable.new(current_user)
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      globalSearchParams = params[:search_term]
      dataTable.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], Institution.count)
      dataTable.set_total_records(institutions.count)
      #Including Search
      institutions = institutions.where("profiles.firstname like :search", search: "%#{searchParams}%")
      #Including Global Search
      institutions = institutions.where("profiles.firstname like :search or profiles.middlename like :search or profiles.surname like :search", search: "%#{globalSearchParams}%")
      #Sorting records
      columns=["profiles.firstname"]
      if(params[:iSortCol_0].present?)
        column = columns[params[:iSortCol_0].to_i]
        direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
        institutions = institutions.order(column +" "+  direction)
      end
      #Fetch Records for page
      institutions = institutions.page(dataTable.page).per(dataTable.per_page)      
      institutions.map!.with_index do |institution, index|
        if institution.profile
        zeroth_column = view_context.link_to(institution.profile.firstname, institution_path(institution))
        third_column = institution.profile.website
        else
          zeroth_column = nil
          third_column = nil
        end
        row_class = index%2==1 ? "tr-odd" : "tr-even"
        {
          "DT_RowId" => "institution_#{institution.id}",
          "DT_RowClass" => row_class,
          "0" => zeroth_column,
          '1' => view_context.institute_admins_with_links(institution.institute_admins),
          '2' => third_column ,
          '3' => view_context.display_date_time(institution.created_at),
          '4' => institution.students.size,
          '5' => view_context.link_to_show(institution_path(institution))
        }
      end

    end

    respond_to do |format|
      format.html # index.html.erb
      if request.xhr?
        format.json { render json: dataTable.as_json(institutions)}
      else
        format.json { render json: @institutions }
      end
    end
  end

  # GET /institutions/1
  # GET /institutions/1.json
  def show
    @institution = Institution.includes(:profile,:centers).find(params[:id])
    @centers =  @institution.centers.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @institution }
    end
  end

  # GET /institutions/new
  # GET /institutions/new.json
  def new
    @institution = Institution.new
    @institution.build_profile
    @institution.build_user_configuration

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @institution }
    end
  end

  # GET /institutions/1/edit
  def edit
    @institution = Institution.find(params[:id])
    if @institution.user_configuration.nil?
      @institution.build_user_configuration
    end
  end

  #GET /institutions/get_centers/1
  def get_centers
    centers = Center.includes(:profile).find_all_by_institution_id(params[:id]) unless params[:id].blank?
    if params[:build_info].present? && params[:build_info] == "true"
    list = centers.map {|u| Hash[value: "#{u.id}|#{u.profile.build_info}", name: u.name]}
    else
      list = centers.map {|u| Hash[value: "#{u.id}", name: u.name]}
      end
    render json: list
  end

  def get_academic_classes
    academic_classes = AcademicClass.includes(:profile).find_all_by_institution_id_and_center_id(params[:institution_id],params[:center_id]) unless params[:institution_id].blank? and params[:center_id].blank?
    if params[:build_info].present? && params[:build_info] == "true"
    list = academic_classes.map {|u| Hash[value: "#{u.id}|#{u.profile.build_info}", name: u.name]}
    else
      list = academic_classes.map {|u| Hash[value: "#{u.id}", name: u.name]}
      end
    render json: list
  end

  def get_sections
    sections = Section.includes(:profile).find_all_by_institution_id_and_center_id_and_academic_class_id(params[:institution_id],params[:center_id],params[:academic_class_id]) unless params[:institution_id].blank? and params[:center_id].blank? and params[:academic_class_id].blank?
    sections = Section.includes(:profile).find_all_by_institution_id_and_center_id(params[:institution_id],params[:center_id]) if params[:academic_class_id].eql?'classes'
    if params[:build_info].present? && params[:build_info] == "true"
    list = sections.map {|u| Hash[value: "#{u.id}|#{u.profile.build_info}", name: u.name]}
    else
      list = sections.map {|u| Hash[value: "#{u.id}", name: u.name]}
      end
    render json: list
  end

  # POST /institutions
  # POST /institutions.json
  def create
    user_groups_token_ids
    @institution = Institution.new(params[:institution])

    respond_to do |format|
      if @institution.save
        #createuser @institution
        #creategroupuser @institution
        format.html { redirect_to @institution, notice: 'Institution was successfully created.' }
        format.json { render json: @institution, status: :created, location: @institution }
      else
        # @institution.build_profile unless @institution.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /institutions/1
  # PUT /institutions/1.json
  def update
    @institution = Institution.find(params[:id])
    user_groups_token_ids
    respond_to do |format|
      if @institution.update_attributes(params[:institution])
        format.html { redirect_to @institution, notice: 'Institution was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /institutions/1
  # DELETE /institutions/1.json
  def destroy
    @institution = Institution.find(params[:id])
    @institution.is_activated? ? @institution.update_attribute(:is_activated,false) : @institution.update_attribute(:is_activated,true)
    flash[:notice]= 'Institution was successfully updated.'
    respond_to do |format|
      format.js {render :nothing => true}
      format.html {  redirect_to :back }
      format.json { head :ok }
    end
  end

  def usage_reports

    @names,@counts,@durations,@max_Y = ""
    @usages = []
    per_page = 3
    case current_user.rc when 'EA'
                                  @list =  Institution.includes(:students).page(params[:page]).per(per_page)
                                  #@usages = @list.map{|inst| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(inst.students)}
                                  @usages = @list.map{|inst| inst.usages.select('sum(count) as count,sum(duration)/60 as duration')}.flatten
    end


    if @usages
      @names = Institution.includes(:profile).page(params[:page]).per(per_page).map{|inst| (inst.profile.firstname.blank? ? inst.profile.surname : inst.profile.firstname)  if inst.profile}.join(',')

      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @list.map{|inst| inst.id.to_s+"_institutions"}.join(',')

      duration_ary = @usages.map{|usage| usage.duration.to_s}
      @durations = duration_ary.join(',')

      #count_max = count_ary.map(&:to_i).max
      #duration_max = duration_ary.map(&:to_i).max
      #@max_Y = count_max > duration_max ? count_max : duration_max

      count_max = count_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      duration_max = duration_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      max_val = count_max > duration_max ? count_max : duration_max  rescue 0

      max_YVal = 1.to_s.ljust(max_val.to_s.size+1, "0").to_i

      @max_Y = max_YVal
      @tick_Y =  (max_YVal/10)


    end

    render 'home/result'

  end

  def report

    @names,@counts,@durations,@max_Y = ""
    @usages = []
    per_page = 3
    model_name = current_user.type.nil?  ? Institution : current_user.type.constantize
    @list =  model_name.find(params[:id]).centers.includes(:students).page(params[:page]).per(per_page)
    #@usages = @list.map{|cent| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(cent.students)}
    @usages = @list.map{|cent| cent.usages.select('sum(count) as count,sum(duration)/60 as duration')}.flatten


    if @usages
      @names = model_name.find(params[:id]).centers.includes(:profile).page(params[:page]).per(per_page).map{|cent| (cent.profile.firstname.blank? ? cent.profile.surname : cent.profile.firstname)  if cent.profile}.join(',')

      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @list.map{|cent| cent.id.to_s+"_centers"}.join(',')

      duration_ary = @usages.map{|usage| usage.duration.to_s}
      @durations = duration_ary.join(',')

      #count_max = count_ary.map(&:to_i).max
      #duration_max = duration_ary.map(&:to_i).max
      #@max_Y = count_max > duration_max ? count_max : duration_max

      count_max = count_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      duration_max = duration_ary.select{|val| val.to_i < 1000000 }.map(&:to_i).max
      max_val = count_max > duration_max ? count_max : duration_max  rescue 0

      max_YVal = 1.to_s.ljust(max_val.to_s.size+1, "0").to_i

      @max_Y = max_YVal
      @tick_Y =  (max_YVal/10)


    end

    render 'home/result'
  end

  def institute_usages
    institution = Institution.includes(:centers=>{:academic_classes=>:sections}).find(params[:id])
  end

  def usage_report
    @institute_id = params[:id]
    @report_start_date = (Date.today-7.days).to_s(:db)
    @report_end_date = Date.today.to_s(:db)
  end

  def usages
    #institution = Institution.find(1020)
    institution = Institution.includes(:centers=>{:academic_classes=>:sections}).find(params[:institute])
    start_date = params[:report_start_date]
    end_date = params[:report_end_date]
    results = []
    #institution.centers.each do  |center|
    #  center.academic_classes.each do |academic_class|
    #    academic_class.sections.each do |section|
    #      total_users = section.students.count
    #      total_users_of_usages = Usage.joins(:user).where("users.center_id=? && users.section_id=? && users.institution_id=? && users.academic_class_id=? && duration > ? ",center.id,section.id,institution.id,academic_class.id,0).map(&:user_id).uniq.count
    #      usages_in_minutes = Usage.joins(:user).where("users.center_id=? && users.section_id=? && users.institution_id=? && users.academic_class_id=? && duration > ? ",center.id,section.id,institution.id,academic_class.id,0).sum(:duration)
    #      results << [center.name,academic_class.name,section.name,total_users,total_users_of_usages,usages_in_minutes/60]
    #    end
    #  end
    #end
    institution.students.each do |user|
      user_weekly_usages = user.analytics_usages.where(:usage_date=>(start_date.to_time.to_i)..(end_date.to_time.to_i)).sum(:today_usage)/60 rescue 0
   #  user_weekly_usages = NewUserUsage.select('sum(end_time - start_time) as duration').where("user_id = #{user.id} ) and uri is not NULL and (end_time BETWEEN #{start_date.to_time.to_i} and #{end_date.to_time.to_i}").first.duration.to_i/60 rescue 0
      results << [user.try(:name) ,user.edutorid,user.center.try(:name),user.academic_class.try(:name),user.section.try(:name),user_weekly_usages]
    end
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,Center,Class,Section,total-usage-in-minutes".split(",")
      results.each do |c|
        csv << c
      end
    end
    file_name =  (institution.name+"_"+start_date.to_s+"to"+end_date.to_s+".csv").gsub(" ","").to_s
    logger.info "=-========================filename:#{file_name}"
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
end


def user_groups_token_ids
  unless params[:institution][:group_ids].blank?
    params[:institution][:group_ids]= params[:institution][:group_ids].split(',')
  end
end

end
