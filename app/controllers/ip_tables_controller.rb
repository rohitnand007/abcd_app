# For access to everything enter '*' in domain column
# For access to full domain enter '*.google.com' in domain column
class IpTablesController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show]
#authorize_resource
  # GET /ip_tables
  # GET /ip_tables.json
  
  def index
    @ip_tables = IpTable.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ip_tables }
    end
  end

  # GET /ip_tables/1
  # GET /ip_tables/1.json
  def show
    @ip_table = IpTable.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ip_table }
    end
  end

  # GET /ip_tables/new
  # GET /ip_tables/new.json
  def new
    @ip_table = IpTable.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ip_table }
    end
  end

  # GET /ip_tables/1/edit
  def edit
    @ip_table = IpTable.find(params[:id])
  end

  # POST /ip_tables
  # POST /ip_tables.json
  def create
    @ip_table = IpTable.new(params[:ip_table])

    respond_to do |format|
      if @ip_table.save
        format.html { redirect_to @ip_table, notice: 'Ip table was successfully created.' }
        format.json { render json: @ip_table, status: :created, location: @ip_table }
      else
        format.html { render action: "new" }
        format.json { render json: @ip_table.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ip_tables/1
  # PUT /ip_tables/1.json
  def update
    @ip_table = IpTable.find(params[:id])

    respond_to do |format|
      if @ip_table.update_attributes(params[:ip_table])
        format.html { redirect_to @ip_table, notice: 'Ip table was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @ip_table.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_tables/1
  # DELETE /ip_tables/1.json
  def destroy
    @ip_table = IpTable.find(params[:id])
    @ip_table.destroy

    respond_to do |format|
      format.html { redirect_to ip_tables_url }
      format.json { head :ok }
    end
  end
end
