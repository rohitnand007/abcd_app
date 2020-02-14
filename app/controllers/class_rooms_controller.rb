class ClassRoomsController < ApplicationController
  authorize_resource
   # GET /class_rooms
  # GET /class_rooms.json
  def index
    if current_user.role_id.eql?(3)
    @class_rooms = ClassRoom.page(params[:page])
    else  
    @class_rooms = ClassRoom.page(params[:page])
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @class_rooms }
    end
  end

  # GET /class_rooms/1
  # GET /class_rooms/1.json
  def show
    @class_room = ClassRoom.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @class_room }
    end
  end

  # GET /class_rooms/new
  # GET /class_rooms/new.json
  def new
    @class_room = ClassRoom.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @class_room }
    end
  end

  # GET /class_rooms/1/edit
  def edit
    @class_room = ClassRoom.find(params[:id])
  end

  # POST /class_rooms
  # POST /class_rooms.json
  def create
    @class_room = ClassRoom.new(params[:class_room])
    respond_to do |format|
      if @class_room.save
        format.html { redirect_to @class_room, notice: 'Academic class was successfully created.' }
        format.json { render json: @class_room, status: :created, location: @class_room }
      else
        format.html { render action: "new" }
        format.json { render json: @class_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /class_rooms/1
  # PUT /class_rooms/1.json
  def update
    @class_room = ClassRoom.find(params[:id])

    respond_to do |format|
      if @class_room.update_attributes(params[:class_room])
        format.html { redirect_to @class_room, notice: 'Academic class was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @class_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /class_rooms/1
  # DELETE /class_rooms/1.json
  def destroy
    @class_room = ClassRoom.find(params[:id])
    @class_room.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to class_rooms_url }
      format.json { head :ok }
    end
  end
  
end
