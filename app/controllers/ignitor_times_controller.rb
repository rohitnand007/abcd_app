class IgnitorTimesController < ApplicationController
  # GET /ignitor_times
  # GET /ignitor_times.json
  def index
    @ignitor_times = IgnitorTime.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ignitor_times }
    end
  end

  # GET /ignitor_times/1
  # GET /ignitor_times/1.json
  def show
    @ignitor_time = IgnitorTime.find(params[:id])
    @associated_institutions = @ignitor_time.institutions

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ignitor_time }
    end
  end

  # GET /ignitor_times/new
  # GET /ignitor_times/new.json
  def new
    @ignitor_time = IgnitorTime.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ignitor_time }
    end
  end

  # GET /ignitor_times/1/edit
  def edit
    @ignitor_time = IgnitorTime.find(params[:id])
  end

  # POST /ignitor_times
  # POST /ignitor_times.json
  def create
    @ignitor_time = IgnitorTime.new(params[:ignitor_time])

    respond_to do |format|
      if @ignitor_time.save
        format.html { redirect_to @ignitor_time, notice: 'Ignitor time was successfully created.' }
        format.json { render json: @ignitor_time, status: :created, location: @ignitor_time }
      else
        format.html { render action: "new" }
        format.json { render json: @ignitor_time.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ignitor_times/1
  # PUT /ignitor_times/1.json
  def update
    @ignitor_time = IgnitorTime.find(params[:id])

    respond_to do |format|
      if @ignitor_time.update_attributes(params[:ignitor_time])
        format.html { redirect_to @ignitor_time, notice: 'Ignitor time was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @ignitor_time.errors, status: :unprocessable_entity }
      end
    end
  end
  def select_institutions
    @ignitor_time = IgnitorTime.find(params[:id])
    @institutions = Institution.all
    @institution_ignitor_times = @ignitor_time.institutions
  end
  def add_institutions
    @ignitor_time = IgnitorTime.find(params[:id])
    @existing_institutions = @ignitor_time.institutions
    @ignitor_time_institutions = []
    @institute_ids = params[:institute_ids]
    @ignitor_time.institutions.delete(@existing_institutions)
    @institute_ids.each do |k|
      @ignitor_time.institutions << Institution.where(id:k)
    end
    redirect_to  :action=>'show', :id=>@ignitor_time.id, :notice=> "Institutions_added_to_Ignitor_Time_successfully"
    end

  # DELETE /ignitor_times/1
  # DELETE /ignitor_times/1.json
  def destroy
    @ignitor_time = IgnitorTime.find(params[:id])
    @ignitor_time.destroy

    respond_to do |format|
      format.html { redirect_to ignitor_times_url }
      format.json { head :no_content }
    end
  end
end
