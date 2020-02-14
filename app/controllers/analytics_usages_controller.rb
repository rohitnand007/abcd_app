class AnalyticsUsagesController < ApplicationController
  authorize_resource
  # GET /analytics_usages
  # GET /analytics_usages.json
  def index
    @analytics_usages = AnalyticsUsage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @analytics_usages }
    end
  end

  # GET /analytics_usages/1
  # GET /analytics_usages/1.json
  def show
    @analytics_usage = AnalyticsUsage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @analytics_usage }
    end
  end

  # GET /analytics_usages/new
  # GET /analytics_usages/new.json
  def new
    @analytics_usage = AnalyticsUsage.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @analytics_usage }
    end
  end

  # GET /analytics_usages/1/edit
  def edit
    @analytics_usage = AnalyticsUsage.find(params[:id])
  end

  # POST /analytics_usages
  # POST /analytics_usages.json
  def create
    @analytics_usage = AnalyticsUsage.new(params[:analytics_usage])

    respond_to do |format|
      if @analytics_usage.save
        format.html { redirect_to @analytics_usage, notice: 'Analytics usage was successfully created.' }
        format.json { render json: @analytics_usage, status: :created, location: @analytics_usage }
      else
        format.html { render action: "new" }
        format.json { render json: @analytics_usage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /analytics_usages/1
  # PUT /analytics_usages/1.json
  def update
    @analytics_usage = AnalyticsUsage.find(params[:id])

    respond_to do |format|
      if @analytics_usage.update_attributes(params[:analytics_usage])
        format.html { redirect_to @analytics_usage, notice: 'Analytics usage was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @analytics_usage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /analytics_usages/1
  # DELETE /analytics_usages/1.json
  def destroy
    @analytics_usage = AnalyticsUsage.find(params[:id])
    @analytics_usage.destroy

    respond_to do |format|
      format.html { redirect_to analytics_usages_url }
      format.json { head :ok }
    end
  end
end
