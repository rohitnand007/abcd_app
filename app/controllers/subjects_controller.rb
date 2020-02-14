class SubjectsController < ApplicationController
  authorize_resource
  # GET /subjects
  # GET /subjects.json
  def index
    # @subjects = Subject.page(params[:page])
    @subjects = case current_user.role.name
                  when 'Edutor Admin'
                    Subject.page(params[:page])
                  when 'Institute Admin'
                    #Subject.by_boards_and_published_by(current_user.institution.board_ids,current_user.institution.publisher_ids).page(params[:page])
                    Subject.where(:board_id=>current_user.institution.board_ids).page(params[:page])
                  when 'Center Representative'
                    #Subject.by_boards_and_published_by(current_user.center.board_ids,current_user.institution.publisher_ids).page(params[:page])
                    Subject.where(:board_id=>current_user.center.board_ids).page(params[:page])
                end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @subjects.map{|u| Hash[id: u.id, name: u.name]} }
    end
  end

  # GET /subjects/1
  # GET /subjects/1.json
  def show
    @subject = Subject.find(params[:id])
    @chapters = @subject.chapters.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @subject }
    end
  end

  # GET /subjects/new
  # GET /subjects/new.json
  def new
    params_hash = {board_id: params[:board_id],content_year_id: params[:content_year_id]}
    @subject = Subject.new(params_hash)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @subject }
    end
  end

  # GET /subjects/1/edit
  def edit
    @subject = Subject.find(params[:id])
  end

  # POST /subjects
  # POST /subjects.json
  def create
    @subject = Subject.new(params[:subject])
=begin
    @subject.build_asset
    @subject.asset.attachment =  File.open("#{Rails.root}/readme.doc","rb")
    @subject.asset.publisher_id = current_user.id
=end
    respond_to do |format|
      if @subject.save
        format.html { redirect_to @subject, notice: 'Subject was successfully created.' }
        format.json { render json: @subject, status: :created, location: @subject }
      else
        format.html { render action: "new" }
        format.json { render json: @subject.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /subjects/1
  # PUT /subjects/1.json
  def update
    @subject = Subject.find(params[:id])

    respond_to do |format|
      if @subject.update_attributes(params[:subject])
        format.html { redirect_to @subject, notice: 'Subject was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @subject.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subjects/1
  # DELETE /subjects/1.json
  def destroy
    @subject = Subject.find(params[:id])
    @subject.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to subjects_url ,:notice=>'Subject has been deleted.'}
      format.json { head :ok }
    end
  end

  # Get populating the chapters for a subject
  def get_chapters
    @subject = Subject.find(params[:id]) unless params[:id].blank?
    if current_user.is?("EA")  or current_user.is?("IA")
      list = @subject.chapters.map {|u| Hash[value: u.id, name: u.name]}
    else
      chapter_ids = ContentUserLayout.get_unlocked_chapters(@subject,current_user)
      if !chapter_ids.nil?
        list = @subject.chapters.where(:id=>chapter_ids).map {|u| Hash[value: u.id, name: u.name]}
      else
        list = @subject.chapters.map {|u| Hash[value: u.id, name: u.name]}
      end
    end
    render json: list
  end

  # Get populating the chapters for a subject
  def get_chapters_values
    @subject = Subject.find(params[:id]) unless params[:id].blank?
    if current_user.is?("EA")  or current_user.is?("IA")
      list = @subject.chapters.map {|u| Hash[value: (u.id.to_s+'|'+get_params(u.params.to_s)), name: u.name]}
    else
      chapter_ids = ContentUserLayout.get_unlocked_chapters(@subject,current_user)
      if !chapter_ids.nil?
        list = @subject.chapters.where(:id=>chapter_ids).map {|u| Hash[value: (u.id.to_s+'|'+get_params(u.params.to_s)), name: u.name]}
      else
        list = @subject.chapters.map {|u| Hash[value: (u.id.to_s+'|'+get_params(u.params.to_s)), name: u.name]}
      end
    end
    render json: list
  end

  def get_params(u)
    unless u.nil?
      a = {}
      u.split(',').each do |i|
        a = a.merge({i.split(':')[0].to_s=>i.split(':')[1].to_s})
      end
      a = a['page_start'].to_s+','+a['page_end'].to_s
    else
      a = ''
    end
    return a
  end

end
