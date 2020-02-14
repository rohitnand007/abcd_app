class SystemMessagesController < ApplicationController

  def index
    result = {};
    result['response'] = false;
    result['message'] = 'Not valid request format.';
    if(params[:device_id].nil? || params[:password].nil?)
      respond_to do |format|
        format.html { render json: result }
        format.json { render json: result }
      end
      return
    end
    salt = Edutor::Application.config.device_id_hash_salt
    hash ='1'
    if(hash != params[:password])
      result['message'] = 'Authorization failed.';
      respond_to do |format|
        format.html { render json: result }
        format.json { render json: result }
      end
      return
    end
    user = User.find(params[:user_id])
    if !user
      result['message'] = 'Authorization failed.';
      respond_to do |format|
        format.html { render json: result }
        format.json { render json: result }
      end
      return
    end
    @ctrl_message = {}
    @ctrl_message = user.individual_inbox_control_messages.last
    respond_to do |format|
      format.json { render json: @ctrl_message,:layout=>false }
    end
  end

  def get_authorized_messages
    
  end
end