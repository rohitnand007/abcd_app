class ConceptMapsController < ApplicationController
  authorize_resource
  # GET /ConceptMaps
  # GET /ConceptMaps.json
  def index
   @concept_maps =  ConceptMap.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@concept_maps }
    end
  end

  # GET /ConceptMaps/1
  # GET /ConceptMaps/1.json
  def show
   @concept_map = ConceptMap.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@concept_map }
    end
  end

  # GET /ConceptMaps/new
  # GET /ConceptMaps/new.json
  def new
   @concept_map = ConceptMap.new
   @concept_map.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@concept_map }
    end
  end

  # GET /ConceptMaps/1/edit
  def edit
   @concept_map = ConceptMap.find(params[:id])
  end

  # POST /ConceptMaps
  # POST /ConceptMaps.json
  def create
   @concept_map = ConceptMap.new(params[:concept_map])
    respond_to do |format|
      if@concept_map.save
        #if@concept_map.rb.status == 1
          Content.send_message_to_est(false,current_user,@concept_map)
        #end
        format.html { redirect_to@concept_map, notice: 'ConceptMap was successfully created.' }
        format.json { render json:@concept_map, status: :created, location:@concept_map }
      else
        format.html { render action: "new" }
        format.json { render json:@concept_map.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ConceptMaps/1
  # PUT /ConceptMaps/1.json
  def update
   @concept_map = ConceptMap.find(params[:id])
    if current_user.role.id == 7
     params[:concept_map][:status] = 6
    end
    respond_to do |format|
      if @concept_map.update_attributes(params[:concept_map])
        format.html { redirect_to@concept_map, notice: 'ConceptMap was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@concept_map.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ConceptMaps/1
  # DELETE /ConceptMaps/1.json
  def destroy
   @concept_map = ConceptMap.find(params[:id])
   @concept_map.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to conecpt_maps_url }
      format.json { head :ok }
    end
  end
  

end
