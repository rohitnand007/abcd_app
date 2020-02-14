class SectionsController < ApplicationController
   authorize_resource
  # GET /sections
  # GET /sections.json
  def index
    @sections = case current_user.rc
                  when 'EA'
                    Section.includes(:profile).order('profiles.firstname').page(params[:page])
                  when 'IA','EO'
                    current_user.sections.includes(:profile).order('profiles.firstname').page(params[:page])
                  when 'MOE'
                    current_user.sections.includes(:profile).order('profiles.firstname').page(params[:page])
                  when 'CR'
                    current_user.sections.includes(:profile).order('profiles.firstname').page(params[:page])
                  when 'ET'
                    current_user.center.sections.includes(:profile).order('profiles.firstname').page(params[:page])
                end


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sections }
    end
  end

  # GET /sections/1
  # GET /sections/1.json
  def show
    @section = Section.includes(:profile).find(params[:id])
    # @teachers = @section.teachers.page(params[:page])
    @users = @section.students.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @section }
    end
  end

  # GET /sections/new
  # GET /sections/new.json
  def new
    params_hash = {institution_id: params[:institution_id],
                   center_id: params[:center_id],
                   academic_class_id: params[:academic_class_id]}
    @section = Section.new(params_hash)
    @section.build_profile
    @section.build_build_info
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @section }
    end
  end

  # GET /sections/1/edit
  def edit
    @section = Section.find(params[:id])
  end

  # POST /sections
  # POST /sections.json
  def create
    params[:section][:email]='rotude@edutor.com' if params[:section][:email].blank?
    params[:section][:password] = 'edutor'
    # @build_number = params[:section][:build_info_attributes][:build_number]
    @section = Section.new(params[:section])

    respond_to do |format|
      if @section.save
        # @section.build_info.update_attribute(:build_number, @build_number)
        format.html { redirect_to @section, notice: 'Section was successfully created.' }
        format.json { render json: @section, status: :created, location: @section }
      else
        # @section.build_profile unless @section.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @section.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sections/1
  # PUT /sections/1.json
  def update
    @section = Section.find(params[:id])

    respond_to do |format|
      if @section.update_attributes(params[:section])
        format.html { redirect_to @section, notice: 'Section was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @section.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sections/1
  # DELETE /sections/1.json
  def destroy
    @section = Section.find(params[:id])
    @section.is_activated? ? @section.update_attribute(:is_activated,false) : @section.update_attribute(:is_activated,true)
    flash[:notice]= 'Section was successfully updated.'
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
                                  @usages = @academic_classes.map{|ac_class| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(ac_class.students)}
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
    @list =  Section.find(params[:id]).students.page(params[:page]).per(per_page)
    #@usages = @list.map{|sec| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(sec.students)}
    @usages = @list.map{|std| Usage.select('sum(count) as count,sum(duration)/60 as duration').find_by_user_id(std.id)}


    if @usages
      @names = Section.find(params[:id]).students.includes(:profile).page(params[:page]).per(per_page).map{|std| (std.profile.firstname.blank? ? std.profile.surname : std.profile.firstname)  if std.profile}.join(',')

      count_ary = @usages.map{|usage| usage.count.to_s}
      @counts = count_ary.join(',')

      # for institution scope it is institution_id and for centers it is center_id
      @url_append_ids = @list.map{|std| std.id.to_s+"_users"}.join(',')

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


end
