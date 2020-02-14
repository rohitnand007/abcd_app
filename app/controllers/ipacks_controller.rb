class IpacksController < ApplicationController
  authorize_resource #:only=>[:edit, :index, :new, :show]
  # GET /ipacks
  # GET /ipacks.json
  def index
    @ipacks = current_user.ipacks

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ipacks }
    end
  end

  # GET /ipacks/1
  # GET /ipacks/1.json
  def show
    @ipack = Ipack.find(params[:id])
    @slices = 3
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ipack }
      format.js { render "show_ipack_book_list"
      }
    end
  end

  # GET /ipacks/new
  # GET /ipacks/new.json
  def new
    @ipack = Ipack.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ipack }
    end
  end

  # GET /ipacks/1/edit
  def edit
    @ipack = Ipack.find(params[:id])
  end

  # POST /ipacks
  # POST /ipacks.json
  def create
    @ipack = Ipack.new(params[:ipack])

    respond_to do |format|
      if @ipack.save
        format.html { redirect_to ipacks_url, notice: 'Collection successfully created.' }
        format.json { render json: @ipack, status: :created, location: @ipack }
      else
        format.html { render action: "new" }
        format.json { render json: @ipack.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ipacks/1
  # PUT /ipacks/1.json
  def update
    @ipack = Ipack.find(params[:id])

    respond_to do |format|
      if @ipack.update_attributes(params[:ipack])
        format.html { redirect_to ipacks_url, notice: 'Collection successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @ipack.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ipacks/1
  # DELETE /ipacks/1.json
  def destroy
    @ipack = Ipack.find(params[:id])
    @ipack.destroy

    respond_to do |format|
      format.html { redirect_to ipacks_url }
      format.json { head :ok }
    end
  end

  def update_ipacks
    @ibooks = Ibook.where(:id => params[:ibook_ids].split(","))
    new_ipack_name = params[:newIpack]
    create_new_ipack = params[:create_new]
    if create_new_ipack
      @ipack = Ipack.new(name: new_ipack_name, publisher_id: current_user.id)
      if @ipack.save
        @ipack.ibooks=@ibooks # Adds books in a single step
        message = "New collection '#{@ipack.name}' was created with the books."
      else
        message = "No new collection created : #{@ipack.errors.full_messages}"
      end
    elsif !create_new_ipack
      message = ""
    end
    @ipacks = Ipack.where(:id => params[:ipacks])
    if create_new_ipack
      ipacks_list = @ipack.name
    else
      ipacks_list = @ipacks.empty? ? "no existing collections" : @ipacks.map(&:name).join(",")
      message = "Kindly select an existing collection or create a new collection." if @ipacks.empty?
    end
    @ipacks.each { |ipack| @ibooks.each { |ibook| ipack.ibooks+=@ibooks } }
    redirect_to :back, notice: "Books added to #{ipacks_list}. #{message}"
  end
end
