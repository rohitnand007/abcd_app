class UserBooksController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show, :device_info]
  def index
    @UserBooks = UserBook.group(:user_id).page(params[:page])
  end

  def show
    @UserBooks = UserBook.where(:user_id => UserBook.find(params[:id]).user_id)
    @User = User.find(UserBook.find(params[:id]).user_id).name

  end

  def device_info
    @DeviceInfo = DeviceInfo.all
  end

end
