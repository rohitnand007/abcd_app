class MessageAcknowledgsController < ApplicationController
  authorize_resource :only=>[:index]
  def index
    acks = current_user.sent_messages.select('id')
    @messageAcks = MessageAcknowledg.page(params[:page]).find_all_by_message_id(acks)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @messageAcks }
    end
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
    @messageAck = MessageAcknowledg.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @messageAck }
    end
  end

  # GET /messages/new
  # GET /messages/new.json
  def new
    @messageAck = MessageAcknowledg.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @messageAck }
    end
  end

  # GET /messages/1/edit
  def edit
    @messageAck = MessageAcknowledg.find(params[:id])
  end

  # POST /messages
  # POST /messages.json
  def create
    ack_string = request.body.read
    logger.info"===============#{ack_string}"
    acks =  ActiveSupport::JSON.decode(ack_string)
    logger.info"===============#{acks}"
    acks.each do |ack|
      message_id = ack["message_id"].to_s.gsub(".","_")
      #@messageAck = MessageAcknowledg.find_by_user_id_and_message_id_and_status(ack['user_id'],message_id,false)
      @messageAck = MessageAcknowledg.new(:user_id=>ack['user_id'],:message_id=>message_id,:status=>"")
      @messageAck.save
    end
    respond_to do |format|
      format.json { head :ok }
    end
  end

  # PUT /messages/1
  # PUT /messages/1.json
  def update
    @messageAck = MessageAcknowledg.find(params[:id])

    respond_to do |format|
      if @messageAck.update_attributes(params[:message])
        format.html { redirect_to @messageAck, notice: 'MessageAcknowledg was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @messageAck.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    @messageAck = MessageAcknowledg.find(params[:id])
    @messageAck.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to institutions_url }
      format.json { head :ok }
    end
  end

end
