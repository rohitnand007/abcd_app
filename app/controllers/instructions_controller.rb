class InstructionsController < ApplicationController
  # GET /instructions
  # GET /instructions.json
  def index
    @instructions = Instruction.where(user_id:current_user.id)
    @instruction = Instruction.where(user_id:current_user.id,is_live:true).first

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @instructions }
    end
  end

  # GET /instructions/1
  # GET /instructions/1.json
  def show
    @instruction = Instruction.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @instruction }
    end
  end

  # GET /instructions/new
  # GET /instructions/new.json
  def new
    @instruction = Instruction.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @instruction }
    end
  end

  # GET /instructions/1/edit
  def edit
    @instruction = Instruction.find(params[:id])
  end

  # POST /instructions
  # POST /instructions.json
  def create
    @instruction = Instruction.new(params[:instruction])
    reset_live = Instruction.where(user_id:current_user.id).update_all(is_live:false)
    @instruction.user_id = current_user.id
    @instruction.template_name = params[:template_name]
    @instruction.is_live = true
    @instruction.content = params[:content]
    respond_to do |format|
      if @instruction.save
        format.html { redirect_to @instruction, notice: 'Instruction was successfully created.' }
        format.json { render json: @instruction, status: :created, location: @instruction }
      else
        format.html { render action: "new" }
        format.json { render json: @instruction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /instructions/1
  # PUT /instructions/1.json
  def update
    @instruction = Instruction.last

    respond_to do |format|
      if @instruction.update_attributes(params[:instruction])
        format.html { redirect_to @instruction, notice: 'Instruction was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @instruction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /instructions/1
  # DELETE /instructions/1.json
  def destroy
    @instruction = Instruction.find(params[:id])
    @instruction.destroy

    respond_to do |format|
      format.html { redirect_to instructions_url }
      format.json { head :no_content }
    end
  end
  def instruction_select
    @instructions = Instruction.where(user_id:current_user.id)
    @instruction = Instruction.where(user_id:current_user.id,is_live:true).first
    @selector = params[:selector]
    @instructions.update_all(is_live:false)
    Instruction.where(id:@selector).first.update_attribute(:is_live,true)

    respond_to do |format|
      format.html {redirect_to :back, notice:"Template Selection Successful"}
    end
  end
end
