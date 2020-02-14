class UsagesController < ApplicationController
  authorize_resource
  #before_filter :must_be_admin
  # GET /usages
  # GET /usages.json
  def index
    @usages = get_usages
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @usages }
    end
  end

  def get_usages
    case current_user.role.name
      when 'Edutor Admin'
        @usages = Usage.page(params[:page])
      when 'Institute Admin'
        @usages = current_user.usages.page(params[:page])
      when 'Center Representative'
        @usages = current_user.usages.page(params[:page])
      when 'Teacher'
        class_contents = current_user.class_contents
        section_students = current_user.sections.map{|section| section.students.select('id')}.flatten
        student_group_students = current_user.sections.map{|section| section.student_groups.select('id')}.flatten
        total_students = (section_students + student_group_students).uniq
        usages_ids = class_contents.map(&:uri).map{|uri|
          Usage.where('uri like ?',"%#{uri}%").where(:user_id=>total_students).map(&:id)
        }
        Usage.where(:id=>usages_ids).page(params[:page])
    end
  end

  # GET /usages/1
  # GET /usages/1.json
  def show
    @usage = Usage.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @usage }
    end
  end

  # GET /usages/new
  # GET /usages/new.json
  def new
    @usage = Usage.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @usage }
    end
  end

  # POST /usage  
  # POST /usages.json
  def create
    record_users("#{Date.today}"+":"+"#{current_user.id}") if current_user
    message_ids = []
    string = request.body.read
    device_id = request.headers['device_id']
    usages = ActiveSupport::JSON.decode(string)
    if !usages.empty?
      begin
        usages.each do |usage|
          if usage['user_id'].nil?
            usage['deviceid'] = device_id
          end
          id = usage['_id']
          usage.delete('_id')
          @usage = Usage.new(usage)
          @find_usage = Usage.find_by_uri_and_user_id(usage['uri'],usage['user_id'])
          if @find_usage
            @find_usage.update_attributes(usage.delete('_id'))
            message_ids << id
          else
            if @usage.save
              message_ids << id
            else
              logger.info "---- usage-token failed to save"
            end
          end
          #respond_to do |format|
          #  if @find_usage
          #    if @find_usage.update_attributes(usage)
          #      format.html { redirect_to @find_usage, notice: 'usage was successfully updated.' }
          #      format.json { head :ok }
          #    else
          #      format.html { render action: "new" }
          #      format.json { render json: @find_usage.errors, status: :unprocessable_entity }
          #    end
          #  else
          #    if @usage.save
          #      format.html { redirect_to @usage, notice: 'usage was successfully created.' }
          #      format.json { head :ok }
          #    else
          #      format.html { render action: "new" }
          #      format.json { render json: @usage.errors, status: :unprocessable_entity }
          #    end
          #  end
          #end
        end
      rescue Exception => e
        logger.info "Exception in creating usage #{e}"
        @error = "#{e.message} "#for #{e.try(:record).try(:class).try(:name)}"
        record_errors(@errors)
      end
    end
    respond_to do |format|
      format.json {render json: message_ids}
    end
  end

  # PUT /usages/1
  # PUT /usages/1.json
  def update
    @usage = Usage.find(params[:id])

    respond_to do |format|
      if @usage.update_attributes(params[:usage])
        format.html { redirect_to @usage, notice: 'usage was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @usage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /usages/1
  # DELETE /usages/1.json
  def destroy
    @usage = Usage.find(params[:id])
    @usage.destroy

    respond_to do |format|
      format.html { redirect_to usages_url }
      format.json { head :ok }
    end
  end


  #export the usages as csv
  def download_csv
    case current_user.role.name
      when 'Edutor Admin'
        usages = Usage
      when 'Institute Admin'
        usages = current_user.usages
      when 'Center Representative'
        usages = current_user.usages
      when 'Teacher'
        class_contents = current_user.class_contents
        section_students = current_user.sections.map{|section| section.students.select('id')}.flatten
        student_group_students = current_user.sections.map{|section| section.student_groups.select('id')}.flatten
        total_students = (section_students + student_group_students).uniq
        usages_ids = class_contents.map(&:uri).map{|uri|
          Usage.where('uri like ?',"%#{uri}%").where(:user_id=>total_students).map(&:id)
        }
        usages = Usage.where(:id=>usages_ids)
    end
    filename ="usages_#{Date.today.strftime('%d%b%y')}"
    csv_data = FasterCSV.generate do |csv|
      csv << Usage.csv_header
      usages.each do |c|
        csv << c.to_csv
      end
    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{filename}.csv"
  end

  #daily usage of the users
  def student_usages_per_day
    results = []
    AnalyticsUsage.where("user_id is NOT NULL").each do |usage|
      results << [usage.user.try(:name),(usage.user.edutorid rescue ""),(usage.user.center.try(:name) if usage.user.center rescue ""),(usage.user.academic_class.try(:name) if usage.user.academic_class rescue ""),(usage.user.section.try(:name) rescue ""),(usage.today_usage/60 rescue 0),Time.at(usage.usage_date).to_datetime.strftime("%d-%b-%Y")]
    end
    filename = "Total_usage"
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,Center,Class,Section,total-usage-in-minutes,date".split(",")
      results.each do |c|
        csv << c
      end
    end
    #path = Rails.root.to_s+"/tmp/cache"
    #file = File.new(path+"/"+"#{Time.now.to_i}"+"_usage.csv", "w+")
    #File.open(file,'w') do |f|
    #  f.write(csv_data)
    #end

    #Usermailer.send_csv(csv)
    #attachment =
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{filename}.csv"
  end

  #usage for given interval view
  def  usage_interval

  end

  #usage report for given time period per institution
  def usage_per_interval
    #end_date = AnalyticsUsage.last.created_at
    #start_date = AnalyticsUsage.first.created_at
    start_date = params[:report_start_date].to_time.to_i
    end_date = params[:report_end_date].to_time.to_i
    interval = params[:interval].to_i
    type= params[:submit]
    institution_ids = params[:institution]
    institution_names = []
    results = []
    institution_ids.each do |id|
      institution = Institution.find_by_id(id)
      name = institution.name.gsub(" ","").to_s
      institution_names << name
      users =   Institution.find_by_id(id).students.map(&:id)
      s = start_date
      e = Time.at(start_date).to_date.plus_with_duration(interval).to_time.to_i
      i = true
      while i
        if s < end_date
          if e > end_date
            e = end_date
          end
          if type=="Get Report"
            duration = AnalyticsUsage.where(:user_id=>users,:created_at=>s..e).sum(:today_usage)
            user_count = AnalyticsUsage.select(:user_id).where(:user_id=>users,:created_at=>s..e).map(&:user_id).uniq.count
            results << [Time.at(s).to_date,Time.at(e).to_date,user_count,duration/60,name]
          elsif type == "User Report"
            AnalyticsUsage.where(:user_id=>users,:created_at=>s..e).each do |u|
              user = User.includes(:institution=>(:profile),:center=>(:profile),:academic_class=>(:profile),:section=>(:profile)).find_by_id_and_institution_id(u.id,id)
              if user
                results <<  [Time.at(s).to_date,Time.at(e).to_date,user.try(:name),(user.edutorid rescue ""),(user.institution.try(:name) if user.institution rescue ""),(user.center.try(:name) if user.center rescue ""),(user.academic_class.try(:name) if user.academic_class rescue ""),(user.section.try(:name)  if user.section rescue ""),(u.today_usage/60 rescue 0),Time.at(u.created_at).to_date]
              end
            end
          end
          s = e
          e = Time.at(s).to_date.plus_with_duration(interval).to_time.to_i
        else
          i = false
        end
      end
    end
    if type == "Get Report"
      header =  "Start date,End date,Users,Total Duration,Institution".split(",")
    elsif type == "User Report"
      header =  "Start date,End Date,Name,EdutorID,Institution,Center,Class,Section,Duration,Date".split(",")
    end


    csv_data = FasterCSV.generate do |csv|
      csv <<  header
      results.each do |c|
        csv << c
      end
    end
    filename = "Usage-Report"
    institution_names.collect{|i| filename = filename+"-"+i}
    logger.info"======#{filename}"
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{filename}.csv"
  end


  def user_usage
    device_id = request.headers['device_id']
    string = request.body.read
   # logger.info"=============#{string}"
    record_users("#{Date.today}"+":"+"#{current_user.id}") if current_user
    usages = ActiveSupport::JSON.decode(string)
    usage_ids = []
    if !usages.empty?
      begin
        usages.each do |usage|
            if usage['user_id'].nil? or usage['user_id'] == 0
              usage['device_id'] = device_id
            end
            if usage.has_key?('uri')
              uri = usage['uri'].split('$$')
              usage['file_path'] = uri[1] != usage['uri'] ? uri[1] : usage['uri']
              usage['uri']   =   uri[0] != usage['uri'] ?  uri[0] : usage['uri']
            end
            id = usage['_id']
            usage.delete('_id')
            if UserUsage.create(usage)
              usage_ids << id
            else
              logger.info "------ usage-detailed-usage"
            end
          end
      rescue Exception => e
        logger.info "==============Exception in creating usage #{e}"
        @error = "#{e.message} "
      end
      respond_to do |format|
        format.json { render json: usage_ids  }
      end
    end
  end

  # TODO cron job for removing duplicates
  def user_activity
    device_id = request.headers['device_id']
    string = request.body.read
    activity = ActiveSupport::JSON.decode(string)
    a_ids = []
    if !activity.empty?
      begin
        activity.each do |a|
          if a['user_id'].nil?
            a['device_id'] = device_id
          end
          id = a['event_id']
          a.delete('event_id')
          logger.info"=====#{a}"
          UserActivity.create(a)
          a_ids << id
        end
      rescue Exception => e
        logger.info "===Exception in creating usage #{e}"
       # @error = "#{e.message} for #{e.try(:record).try(:class).try(:name)}"
      end
      respond_to do |format|
        format.json { render json: a_ids  }
      end
    end

end

end
