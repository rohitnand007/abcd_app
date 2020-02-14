class TspsController < ApplicationController
  authorize_resource
  # GET /Tsps
  # GET /Tsps.json
  def index
   @tsps =  Tsp.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@tsps }
    end
  end

  # GET /Tsps/1
  # GET /Tsps/1.json
  def show
   @tsp = Tsp.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@tsp }
    end
  end

  # GET /Tsps/new
  # GET /Tsps/new.json
  def new
   @tsp = Tsp.new
   @tsp.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@tsp }
    end
  end

  # GET /Tsps/1/edit
  def edit
   @tsp = Tsp.find(params[:id])
  end

  # POST /Tsps
  # POST /Tsps.json
  def create
   @tsp = Tsp.new(params[:tsp])
    respond_to do |format|
      if@tsp.save
        #if@tsp.rb.status == 1
          Content.send_message_to_est(false,current_user,@tsp)
        #end
        format.html { redirect_to @tsp, notice: 'Tsp was successfully created.' }
        format.json { render json: @tsp, status: :created, location: @tsp }
      else
        format.html { render action: "new" }
        format.json { render json: @tsp.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /Tsps/1
  # PUT /Tsps/1.json
  def update
   @tsp = Tsp.find(params[:id])
    if current_user.role.id == 7
     params[:tsp][:status] = 6
    end
    respond_to do |format|
      if @tsp.update_attributes(params[:tsp])
        format.html { redirect_to@tsp, notice: 'Tsp was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@tsp.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /Tsps/1
  # DELETE /Tsps/1.json
  def destroy
   @tsp = Tsp.find(params[:id])
   @tsp.destroy

    respond_to do |format|
      format.html { redirect_to tsps_url }
      format.json { head :ok }
    end
  end
  

end
