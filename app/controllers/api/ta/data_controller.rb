class Api::Ta::DataController < ActionController::Base
  respond_to :json
  # doorkeeper_for :all

  def get_users_ids
  a = User.last(100).map(&:edutorid)
  render json: a
  end

end
