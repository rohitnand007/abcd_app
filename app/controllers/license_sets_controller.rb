class LicenseSetsController < ApplicationController
  load_and_authorize_resource
  # GET /license_sets
  # GET /license_sets.json
  def index
    case current_user.rc
      when "EA"
        @license_sets = LicenseSet.all.select { |l| (l.ends > Time.now.to_i && l.starts < Time.now.to_i) }.sort_by(&:created_at).reverse
        @future_license_sets = LicenseSet.all.select { |l| (l.starts > Time.now.to_i) }.sort_by(&:created_at).reverse
        @past_license_sets = LicenseSet.all.select { |l| (l.ends < Time.now.to_i) }
      when "IA"
        @license_sets = current_user.institution.license_sets.select { |l| (l.ends > Time.now.to_i && l.starts < Time.now.to_i) }.sort_by(&:created_at).reverse
        @future_license_sets = current_user.institution.license_sets.select { |l| (l.starts > Time.now.to_i) }.sort_by(&:created_at).reverse
        @past_license_sets = current_user.institution.license_sets.select { |l| (l.ends < Time.now.to_i) }
      when "CR"
        @license_sets = current_user.institution.license_sets.select { |l| (l.ends > Time.now.to_i && l.starts < Time.now.to_i) }.sort_by(&:created_at).reverse
        @future_license_sets = current_user.institution.license_sets.select { |l| (l.starts > Time.now.to_i) }.sort_by(&:created_at).reverse
        @past_license_sets = current_user.institution.license_sets.select { |l| (l.ends < Time.now.to_i) }
        # @license_sets = current_user.center.license_sets.select { |l| (l.ends > Time.now.to_i && l.starts < Time.now.to_i) }.sort_by(&:created_at).reverse
        # @future_license_sets = current_user.center.license_sets.select { |l| (l.starts > Time.now.to_i) }.sort_by(&:created_at).reverse
        # @past_license_sets = current_user.center.license_sets.select { |l| (l.ends < Time.now.to_i) }
      when "ECP"
        @license_sets = current_user.license_sets.sort_by(&:created_at).reverse
      else
        @license_sets =[]
        @future_license_sets = []
        @past_license_sets = []
    end
    @license_set = @license_sets.first
    respond_to do |format|
      if current_user.rc == "ECP"
        format.html { render "publisher_license_set_index" }
      else
        # @users = User.order(:name).page params[:page]
        @license_sets = Kaminari.paginate_array(@license_sets).page(params[:page]).per(10)
        format.html # index.html.erb
      end

      format.json { render json: @license_sets }
    end
  end

  # GET /license_sets/1
  # GET /license_sets/1.json
  def show
    @license_set = LicenseSet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @license_set }
    end
  end

  # GET /license_sets/new
  # GET /license_sets/new.json
  def new
    @license_set = LicenseSet.new
    unless params[:ipackId].nil?
      @ipack = Ipack.find(params[:ipackId])
      @license_set.ipack_id = @ipack.id
    end
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @license_set }
      format.js
    end
  end

  # GET /license_sets/1/edit
  def edit
    @license_set = LicenseSet.find(params[:id])
  end

  # POST /license_sets
  # POST /license_sets.json
  def create
    @license_set = LicenseSet.new(params[:license_set])
    @license_set.publisher_id = current_user.id

    respond_to do |format|
      if @license_set.save
        format.html { redirect_to :back, notice: "A license set with #{@license_set.licences} license(s) was successfully created and assigned to the school." }
        format.json { render json: @license_set, status: :created, location: @license_set }
      else
        format.html { redirect_to :back, notice: "#{@license_set.errors.full_messages}" }
        format.json { render json: @license_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /license_sets/1
  # PUT /license_sets/1.json
  def update
    @license_set = LicenseSet.find(params[:id])

    respond_to do |format|
      if @license_set.update_attributes(params[:license_set])
        format.html { redirect_to @license_set, notice: 'License set was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @license_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /license_sets/1
  # DELETE /license_sets/1.json
  def destroy
    @license_set = LicenseSet.find(params[:id])
    @license_set.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :ok }
    end
  end

  # fetch students
  def fetch_students
    @license_set = LicenseSet.find params[:id]
    @target_action = "add_new"
    @centers = []
    if params[:user] # This means we are intending to assign licenses to new students
      @no_students = false
      if params[:user][:section_id].present?
        @students = Section.find(params[:user][:section_id]).students
        @no_students = true if @students.empty?
      elsif !(params[:user][:academic_class_id]=="")
        @students = AcademicClass.find(params[:user][:academic_class_id]).students
        @no_students = true if @students.empty?
      else
        # intentionally returning empty list to avoid cluttering
        @students =[]
      end
      if params[:user][:center_id]
        @teachers = Teacher.where(center_id: (params[:user][:center_id]))
      else
        @teachers =[]
      end
    else
      @no_students = false
      @teachers = @license_set.users.select { |user| user.type=="Teacher" }
      @students = @license_set.users.sort_by { |student| student.center_id } - @teachers
      @target_action = "update_old"
      if current_user.rc == "CR"
        @centers = Center.where(id:current_user.center_id)
      else
        @centers = Center.where(:id => @students.map(&:center_id).uniq) + Center.where(id:10)
      end
    end

    respond_to do |format|
      format.js
    end
  end

  # Assign licenses to students
  def assign
    @license_set = LicenseSet.find(params[:id])
    success = false

    if params[:commit]=="Update" # In case the CR/IA is attempting to revoke licenses to students
      # Don't even bother to validate. Just update
      users = params[:license_set] ? User.where(id: params[:license_set][:user_ids]) : [] # If there are no user_ids in the params, then revoke the licenses for all students by setting license = 0
      all_users_of_this_license_set = @license_set.user_ids
      user_ids_int = params[:license_set].present? ? params[:license_set][:user_ids].collect { |id_int| id_int.to_i } : []
      revoked_users = all_users_of_this_license_set - user_ids_int
      @license_set.update_attribute :users, users
      if users == []
        all_users_of_this_license_set.each do |user_id|
          User.find(user_id).update_attribute(:last_content_purchased,Time.now)
        end
      else
        revoked_users.each do |user_id|
          User.find(user_id).update_attribute(:last_content_purchased,Time.now)
        end
      end
      success = true
    else # IA/CR is attempting to assign licenses to new students
      message = "Please select at least one student"
      if params[:license_set] # If users are there in the params list
        users = User.where(id: params[:license_set][:user_ids])
        if @license_set.available >= (users.map(&:id)-@license_set.user_ids).size #Availablilty of licenses is greater than the new users who want licenses
          @license_set.users+=users # This also covers the case where the student is already there in the system because the duplicate will not be allowed by rails by default.
          success = true
        else
          message = "Lesser no. of licenses are available than requested"
        end
        message = "All the licenses are consumed" if @license_set.available==0
      end
    end
    @license_set.reevaluate_license_set
    if success
      respond_to do |format|
        format.js { render "list_all_students" }
      end
    else
      respond_to do |format|
        format.js { render :js => "$('<div>#{message}</div>').dialog({buttons : {
                Ok: function() {$(this).dialog('close');}}})" }
      end
    end

  end

  def clean_list
    @license_set = LicenseSet.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def revoke
    license_set = LicenseSet.find(params[:id])
    File.open(Rails.root.to_s+"/public/revoke.txt", "a+", 0644) do |f|
      f.puts license_set.to_json
    end
    license_set.reevaluate_license_set
    license_set.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: "License Successfully Revoked #{license_set.ipack.name}" }
    end
  end

  def bulk_assign_interface

  end

  def bulk_assign
    # This method bulk assigns license sets to specific students uploaded in csv
    license_sets_list = Array.new
    if current_user.is?("EA")
      rejected = []
      if params[:csv_file]
        entries = CsvMapper.import(params[:csv_file].tempfile) do
          start_at_row 1
          # Expects entries in this order
          [edutorid, rollno, license_set_id]
        end
        entries.each do |entry|
          if entry.edutorid.present? && entry.license_set_id.present?
            license_set = LicenseSet.find(entry.license_set_id)
            license_sets_list << license_set if !(license_sets_list.include? license_set)
            user = User.find_by_edutorid(entry.edutorid)
            if license_set.available > 0
              license_set.users << user unless license_set.users.include?(user)
            else
              rejected << [entry.edutorid, entry.license_set_id, "License Quota exceeded"]
            end
          end
        end
      end
      license_sets_list.each {|l| l.set_content_access_permission}
      if rejected.any?
        rejectedFile ="Rejects_#{Date.today.strftime('%d%b%y')}.csv"
        header = ["Edutor ID", "License ID", "Remarks"]
        rejected.insert(0, header)
        rejectedCSV = CSV.generate do |csv|
          rejected.each { |row| csv << row }
        end
        send_data rejectedCSV,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=#{rejectedFile}.csv"
      else
        flash[:notice] = 'Bulk assigned successfully'
        redirect_to :back
      end
    else
      flash[:notice] = 'Permission denied'
      redirect_to :back
    end
  end

  def bulk_unassign_interface

  end

  def bulk_unassign #method to bulk unassign licenses using a csv
    license_sets_list = Array.new
    if current_user.is?("EA")
      rejected = []
      if params[:csv_file]
        entries = CsvMapper.import(params[:csv_file].tempfile) do
          start_at_row 1
          #Expects entries in the form of
          [edutorid, rollno, license_set_id]
        end
        entries.each do |entry|
          if entry.edutorid.present? && entry.license_set_id.present?
            license_set = LicenseSet.find(entry.license_set_id)
            user = license_set.users.find_by_edutorid(entry.edutorid)
            if user
              license_set.users.delete(user)
              user.update_attribute("last_content_purchased",Time.now)
              license_sets_list << license_set
            else
              rejected << [entry.edutorid, entry.license_set_id, "Not Processed"]
            end
          end
        end
      end
      license_sets_list.each {|l| l.reevaluate_license_set}
      if rejected.any?
        rejectedFile ="Rejects_#{Date.today.strftime('%d%b%y')}.csv"
        header = ["Edutor ID", "License ID", "Remarks"]
        rejected.insert(0, header)
        rejectedCSV = CSV.generate do |csv|
          rejected.each { |row| csv << row }
        end
        send_data rejectedCSV,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=#{rejectedFile}.csv"
      else
        flash[:notice] = 'Bulk unassigned successfully'
        redirect_to :back
      end
    else
      flash[:notice] = 'Permission denied'
      redirect_to :back
    end

  end
end
