class CentersController < ApplicationController
   authorize_resource
  # GET /centers
  # GET /centers.json
  def index
    require "DataTable"
    @centers = case current_user.rc
                 when 'EA'
                   Center.includes(:profile).order('profiles.firstname').page(params[:page])
                 when 'IA', 'EO'
                   current_user.centers.includes(:profile).order('profiles.firstname').page(params[:page])
                 when 'MOE'
                   current_user.centers.includes(:profile).order('profiles.firstname').page(params[:page])
                 when 'CR'
                   Center.includes(:profile).where(:id=>current_user.center).order('profiles.firstname').page(params[:page])
               end
    if request.xhr?
      data = DataTable.new(current_user)
      globalSearchParams = params[:search_term]
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], Center.count)
      centers = case current_user.rc
                 when 'EA'
                   Center.includes(:profile,:center_admins,:users, institution: [:profile])
                 when 'IA', 'EO'
                   current_user.centers.includes(:profile,:center_admins,:users, institution: [:profile])
                 when 'MOE'
                    current_user.centers.includes(:profile).order('profiles.firstname').page(params[:page])
                 when 'CR'
                   Center.includes(:profile,:center_admins,:users, institution: [:profile]).where(:id=>current_user.center)
               end
      if(params[:InstitutionId].present?)
        centers = centers.where(:institution_id => params[:InstitutionId])
      end
      centers = centers.joins("inner join profiles p1 on users.id = p1.user_id").joins("inner join profiles p2 on users.institution_id= p2.user_id")
      #including search
      centers = centers.where("p1.firstname like :search or p2.firstname like :search", search: "%#{searchParams}%")
      #including Global Search
      centers = centers.where("p1.firstname like :search or p1.middlename like :search or p1.surname like :search", search: "%#{globalSearchParams}%")
      total_centers= centers.count
      data.set_total_records(total_centers)
      #limiting Records
      centers = centers.page(data.page).per(data.per_page)
      #Sorting Records
      columns = ["p1.firstname", "", "p2.firstname"]
      if(params[:iSortCol_0].present?)
        column = columns[params[:iSortCol_0].to_i]
        direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
        centers = centers.order(column +" "+  direction)
      end

      centers.map!.with_index do |center, index|
        second_column = nil
        if center.est
          second_column = view_context.link_to(center.est.try(:name), user_path(center.est))
        end
        row_class = index%2==1 ? "tr-odd" : "tr-even"
        {
          "DT_RowId" => "center_#{center.id}",
          "DT_ClassId" => row_class,
          "0" => view_context.link_to(center.profile.firstname, center_path(center)),
          "1" => view_context.link_to(view_context.center_admins_with_links(center.center_admins)),
          "2" => center.institution.name,
          "3" => view_context.display_date_time(center.created_at),
          "4" => [view_context.link_to_show(center_path(center)),view_context.link_to('Download CSV',download_csv_centers_path+"?id=#{center.id}")]
        }
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      if request.xhr?
        format.json { render json: data.as_json(centers)}
      else
        format.json { render json: @centers }
      end
    end
  end

  # GET /centers/1
  # GET /centers/1.json
  def show
    @center = Center.includes(:profile,:academic_classes).find(params[:id])
    @academic_classes = @center.academic_classes.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @center }
    end
  end

  # GET /centers/new
  # GET /centers/new.json
  def new
    @center = Center.new(institution_id: params[:institution_id])
    @center.build_profile

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @center }
    end
  end

  # GET /centers/1/edit
  def edit
    @center = Center.find(params[:id])
  end

  # POST /centers
  # POST /centers.json
  def create
    @center = Center.new(params[:center])
    respond_to do |format|
      if @center.save
        format.html { redirect_to @center, notice: 'Center was successfully created.' }
        format.json { render json: @center, status: :created, location: @center }
      else
        # @center.build_profile unless @center.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @center.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /centers/1
  # PUT /centers/1.json
  def update
    @center = Center.find(params[:id])

    respond_to do |format|
      if @center.update_attributes(params[:center])
        format.html { redirect_to @center, notice: 'Center was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @center.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /centers/1
  # DELETE /centers/1.json
  def destroy
    @center = Center.find(params[:id])
    @center.is_activated? ? @center.update_attribute(:is_activated,false) : @center.update_attribute(:is_activated,true)
    flash[:notice]= 'Center was successfully updated.'
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
                                  @list =  Center.includes(:students).page(params[:page]).per(per_page)
                                  @names = Center.includes(:profile).page(params[:page]).per(per_page).map{|cent| (cent.profile.firstname.blank? ? cent.profile.surname : cent.profile.firstname)  if cent.profile}.join(',')
      when 'IA'
        @list =  current_user.centers.includes(:students).page(params[:page]).per(per_page)
        @names = current_user.centers.includes(:profile).page(params[:page]).per(per_page).map{|cent| (cent.profile.firstname.blank? ? cent.profile.surname : cent.profile.firstname)  if cent.profile}.join(',')
    end
    #@usages = @list.map{|cent| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(cent.students)}
    @usages = @list.map{|cent| cent.usages.select('sum(count) as count,sum(duration)/60 as duration')}.flatten

    if @usages

      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @list.map{|cent| cent.id.to_s+"_classes"}.join(',')

      duration_ary = @usages.map{|usage| usage.duration.to_s}
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


  def report

    @names,@counts,@durations,@max_Y = ""
    @usages = []
    per_page = 3
    center = (current_user.type.nil? or current_user.type.eql?('InstituteAdmin'))  ? Center.find(params[:id]) : CenterAdmin.find(params[:id]).center


    @list =  center.academic_classes.includes(:students).page(params[:page]).per(per_page)
    #@usages = @list.map{|cent| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(cent.students)}
    @usages = @list.map{|ac_class| ac_class.usages.select('sum(count) as count,sum(duration)/60 as duration')}.flatten


    if @usages
      @names = center.academic_classes.includes(:profile).page(params[:page]).per(per_page).map{|cent| (cent.profile.firstname.blank? ? cent.profile.surname : cent.profile.firstname)  if cent.profile}.join(',')

      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @list.map{|cent| cent.id.to_s+"_classes"}.join(',')

      duration_ary = @usages.map{|usage| usage.duration.to_s}
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



  #csv download of students
  def download_csv
   center = Center.find(params[:id])
   users = center.teachers +  center.students 
    results =  []
    users.each do |user|
      results << [user.try(:name) ,user.edutorid,user.email,user.center.try(:name),user.academic_class.try(:name),user.section.try(:name),user.devices.first.try(:deviceid),user.rollno,user.devices.first.try(:mac_id)]
    end
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,Email,Center,Class,Section,Deviceid,Rollno,Macid".split(",")
      results.each do |c|
        csv << c
      end
    end
    file_name =  (center.institution.name+"_"+center.name).gsub(" ","")+".csv".to_s
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end


  def center_report_download
    @center = Center.find(params[:id])
    users =  @center.students
    extensions = [".swf",".pdf",".elp",".mp4",".etx"]
    dates = ["2012-05-03", "2012-05-04", "2012-05-05", "2012-05-06", "2012-05-07", "2012-05-08", "2012-05-09", "2012-05-10", "2012-05-11", "2012-05-12", "2012-05-13", "2012-05-14", "2012-05-15", "2012-05-16", "2012-05-17", "2012-05-18", "2012-05-19", "2012-05-20", "2012-05-21", "2012-05-22", "2012-05-23", "2012-05-24", "2012-05-25", "2012-05-26", "2012-05-27", "2012-05-28", "2012-05-29", "2012-05-30", "2012-05-31", "2012-06-01", "2012-06-02", "2012-06-03", "2012-06-04", "2012-06-05", "2012-06-06", "2012-06-07", "2012-06-08", "2012-06-09", "2012-06-10", "2012-06-11", "2012-06-12", "2012-06-13", "2012-06-14", "2012-06-15", "2012-06-16", "2012-06-17", "2012-06-18", "2012-06-19", "2012-06-20", "2012-06-21", "2012-06-22", "2012-06-23", "2012-06-24", "2012-06-25", "2012-06-26", "2012-06-27", "2012-06-28", "2012-06-29", "2012-06-30", "2012-07-01", "2012-07-02", "2012-07-03", "2012-07-04", "2012-07-05", "2012-07-06", "2012-07-07", "2012-07-08", "2012-07-09", "2012-07-10", "2012-07-11", "2012-07-12", "2012-07-13", "2012-07-14", "2012-07-15", "2012-07-16", "2012-07-17", "2012-07-18", "2012-07-19", "2012-07-20", "2012-07-21", "2012-07-22", "2012-07-23", "2012-07-24", "2012-07-25", "2012-07-26", "2012-07-27", "2012-07-28", "2012-07-29", "2012-07-30"]
    results = []
    users.each do |user|
      dates_result = []
      dates.each do |d|
        i = 0
        user.analytics_usages.each do |a|
          if d == Time.at(a.created_at).to_date.to_s
            dates_result << a.today_usage/60
            i = 1
            break
          end
        end
        if i != 1
         dates_result << 0
        end
      end
      results << [user.try(:name)] + dates_result
    end

    #test_count = []
    #test_count_header = ["User","Test Count"]


    usage_count = []
    usage_header = ["user","Usage count"]


    users.each do |u|
     # test_count << [u.name,u.test_results.count]
      usage_count << [u.name,u.usages.sum(:duration)/60]
    end
    #
    conetnt_type_header = ["user","pdf","swf","elp","mp4","etx"]
    content_type_count = []
    #
    #users.each do |u|
    #  uris = u.usages.map(&:uri)
    #  cids = Content.where(:uri=>uris).map(&:id)
    #  srcs = Asset.where(:archive_id=>cids).select(:src)
    #  pdf_count = srcs.where("src like?","%.pdf%").count
    #  swf_count = srcs.where("src like?","%.swf%").count
    #  elp_count = srcs.where("src like?","%.elp%").count
    #  mp4_count = srcs.where("src like?","%.mp4%").count
    #  etx_count = srcs.where("src like?","%.etx%").count
    #  content_type_count << [u.name,pdf_count,swf_count,elp_count,mp4_count,etx_count]
    #end


    csv_data = FasterCSV.generate do |csv|
      csv << ["user"]+dates

      results.each do |c|
        csv << c
      end
      #
      #csv << [""]
      #csv << [""]
      #csv << [""]
      #csv << [""]
      #
      #csv << ["Total users checked in 174"]
      #
      #csv << [""]
      #csv << [""]
      #csv << [""]
      #
      #csv << ["Test Result count per person"]
      #
      #csv << [""]
      #
      #csv << test_count_header
      #test_count.each do |t|
      #  csv << t
      #end
      #
      #csv << [""]
      #csv << [""]
      #csv << [""]


      #csv << usage_header
      #usage_count.each do |usage|
      #  csv << usage
      #end
      #
      #csv << conetnt_type_header
      #content_type_count.each do |ct|
      #  csv << ct
      #end


    end
    filename =  (@center.name+"_content_type_consume"+".csv").gsub(" ","").to_s
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{filename}"
  end


end
