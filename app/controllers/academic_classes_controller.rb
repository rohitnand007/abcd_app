class AcademicClassesController < ApplicationController
  authorize_resource
  # GET /academic_classes
  # GET /academic_classes.json
  def index
    @academic_classes = case current_user.rc
                          when 'EA'
                            AcademicClass.includes(:profile).order('profiles.firstname').page(params[:page])
                          when 'IA','EO'
                            current_user.academic_classes.includes(:profile).order('profiles.firstname').page(params[:page])
                          when 'MOE'
                            current_user.academic_classes.includes(:profile).order('profiles.firstname').page(params[:page])
                          when 'CR'
                            current_user.academic_classes.includes(:profile).order('profiles.firstname').page(params[:page])
                        end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @academic_classes }
    end
  end

  # GET /academic_classes/1
  # GET /academic_classes/1.json
  def show
    @academic_class = AcademicClass.includes(:profile,:sections).find(params[:id])
    @sections = @academic_class.sections.page(params[:page])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @academic_class }
    end
  end

  # GET /academic_classes/new
  # GET /academic_classes/new.json
  def new
    @academic_class = AcademicClass.new(
        institution_id: params[:institution_id],center_id: params[:center_id]
    )

    @academic_class.build_profile
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @academic_class }
    end
  end

  # GET /academic_classes/1/edit
  def edit
    @academic_class = AcademicClass.find(params[:id])
  end

  # POST /academic_classes
  # POST /academic_classes.json
  def create
   # params[:academic_class][:email]='rotude@edutor.com' if params[:academic_class][:email].blank?
    #params[:academic_class][:password] = 'edutor'
    @academic_class = AcademicClass.new(params[:academic_class])
    respond_to do |format|
      if @academic_class.save
        format.html { redirect_to @academic_class, notice: 'Form was successfully created.' }
        format.json { render json: @academic_class, status: :created, location: @academic_class }
      else
        # @academic_class.build_profile unless @academic_class.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @academic_class.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /academic_classes/1
  # PUT /academic_classes/1.json
  def update
    @academic_class = AcademicClass.find(params[:id])

    respond_to do |format|
      if @academic_class.update_attributes(params[:academic_class])
        format.html { redirect_to @academic_class, notice: 'Form was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @academic_class.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /academic_classes/1
  # DELETE /academic_classes/1.json
  def destroy
    @academic_class = AcademicClass.find(params[:id])
    @academic_class.is_activated? ? @academic_class.update_attribute(:is_activated,false) : @academic_class.update_attribute(:is_activated,true)
    flash[:notice]= 'Form was successfully updated.'
    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to :back }
      format.json { head :ok }
    end

  end

  def usage_reports

    @names,@counts,@durations,@max_Y = ""
    @usages = []
    per_page = 3
    case current_user.rc when 'EA'
                                  @academic_classes =  AcademicClass.includes(:students).page(params[:page]).per(per_page)
                                  #@usages = @academic_classes.map{|ac_class| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(ac_class.students)}
                                  @usages = @academic_classes.map{|ac_class| ac_class.usages.select('sum(count) as count,sum(duration)/60 as duration')}.flatten
    end


    if @usages
      @names = AcademicClass.includes(:profile).page(params[:page]).per(per_page).map{|ac_class| (ac_class.profile.firstname.blank? ? ac_class.profile.surname : ac_class.profile.firstname)  if ac_class.profile}.join(',')

      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @academic_classes.map{|cent| cent.id.to_s}.join(',')

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
    @list =  AcademicClass.find(params[:id]).sections.includes(:students).page(params[:page]).per(per_page)
    #@usages = @list.map{|ac_class| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(ac_class.students)}
    @usages = @list.map{|sec| sec.usages.select('sum(count) as count,sum(duration)/60 as duration')}.flatten


    if @usages
      @names = AcademicClass.find(params[:id]).sections.includes(:profile).page(params[:page]).per(per_page).map{|sec| (sec.profile.firstname.blank? ? sec.profile.surname : sec.profile.firstname)  if sec.profile}.join(',')

      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @list.map{|sec| sec.id.to_s+"_sections"}.join(',')

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

  # Get populating the academic subjects for a class
  def get_subjects
    @academic_class = AcademicClass.find(params[:id]) unless params[:id].blank?
    list = @academic_class.subjects.map {|u| Hash[value: u.id, name: u.name]}
    render json: list
  end


  # Get populating the sections for a academic_class
  def get_sections
    @academic_class = AcademicClass.find(params[:id]) unless params[:id].blank?
    list = @academic_class.sections.includes(:profile).map {|u| Hash[value: u.id, name: u.profile.firstname]}
    render json: list
  end



  def download_csv
    academic_class = AcademicClass.find(params[:id])
    users = academic_class.students
    results =  []
    users.each do |user|
      results << [user.try(:name) ,user.edutorid,user.email,user.center.try(:name),user.academic_class.try(:name),user.section.try(:name),user.devices.first.try(:deviceid),user.rollno,user.devices.first.try(:mac_id)]
    end
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,Email,Center,Form,Section,Deviceid,Rollno,Macid".split(",")
      results.each do |c|
        csv << c
      end
    end
    file_name =  (academic_class.institution.name+"_"+academic_class.name).gsub(" ","")+".csv".to_s
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end


end
