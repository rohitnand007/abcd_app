class ContentYearsController < ApplicationController
  authorize_resource :except=>[:get_subjects]
  # GET /academic_classes
  # GET /academic_classes.json
  def index
    @content_years = case current_user.role.name
                       when 'Edutor Admin'
                         ContentYear.page(params[:page])
                       when 'Institute Admin'
                         #ContentYear.by_boards_and_published_by(current_user.institution.board_ids,current_user.institution.publisher_ids).page(params[:page])
                         ContentYear.where(:board_id=>current_user.institution.board_ids).page(params[:page])
                       when 'Center Representative'
                         #ContentYear.by_boards_and_published_by(current_user.center.board_ids,current_user.institution.publisher_ids).page(params[:page])
                         ContentYear.where(:board_id=>current_user.center.board_ids).page(params[:page])
                     end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @content_years }
    end
  end

  # GET /academic_classes/1
  # GET /academic_classes/1.json
  def show
    @content_year = ContentYear.find(params[:id])
    @subjects = @content_year.subjects.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @content_year }
    end
  end

  # GET /academic_classes/new
  # GET /academic_classes/new.json
  def new
    @content_year = ContentYear.new(board_id: params[:board_id])
    @content_year.build_asset

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @content_year }
    end
  end

  # GET /academic_classes/1/edit
  def edit
    @content_year = ContentYear.find(params[:id])
  end

  # POST /academic_classes
  # POST /academic_classes.json
  def create
    @content_year = ContentYear.new(params[:content_year])
    @content_year.asset.attachment =  File.open("#{Rails.root}/readme.doc","rb")
    respond_to do |format|
      if @content_year.save
        format.html { redirect_to @content_year, notice: 'Academic class was successfully created.' }
        format.json { render json: @content_year, status: :created, location: @content_year }
      else
        format.html { render action: "new" }
        format.json { render json: @content_year.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /academic_classes/1
  # PUT /academic_classes/1.json
  def update
    @content_year = ContentYear.find(params[:id])

    respond_to do |format|
      if @content_year.update_attributes(params[:content_year])
        format.html { redirect_to @content_year, notice: 'Academic class was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @content_year.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /academic_classes/1
  # DELETE /academic_classes/1.json
  def destroy
    @content_year = ContentYear.find(params[:id])
    @content_year.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to content_years_url }
      format.json { head :ok }
    end
  end

  # Get populating the academic subjects for a class
  def get_subjects
    @content_year = ContentYear.find(params[:id]) unless params[:id].blank? rescue nil
    list = @content_year.subjects.map {|u| Hash[value: u.id, name: u.name]} rescue []
    render json: list
  end

end
