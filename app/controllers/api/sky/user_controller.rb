class Api::Sky::UserController < Api::Sky::BaseController
  before_filter :check_login

  def check_login
    unless user_signed_in?
      render :status => 401,
             :json => {:success => false,
                       :info => "Login Failed"}
      return
    end
  end
  
  def last_content_purchased
    current_user.last_content_purchased = 1446280033
    render :json => {user_id: current_user.id, last_content_purchased: current_user.last_content_purchased}
  end

  def accessible_content
    render :json => {"courses" => [{"id" => "acb4df1f-7ba0-41cc-b8dc-eeeed22673f0", "name" => "GRE", "starts" => 363464646, "ends" => 567567576, "books" => [{"id" => "77847faa-40b1-4f3a-a929-f76a84ff821c", "infoUrl" => ""}, {"id" => "83368d7f-8b51-450a-96aa-ddda9bda48a2", "infoUrl" => ""}]}, {"id" => "30b4df1f-7ba0-41cc-b8dc-eeeed22673f0", "name" => "IIT", "starts" => 363464646, "ends" => 567567576, "books" => [{"id" => "77847faa-40b1-4f3a-a929-f76a84ff821c", "infoUrl" => ""}, {"id" => "5874dcdd-57ef-4663-92c0-e92e0e406d78", "infoUrl" => ""}]}], "books" => [{"id" => "77847faa-40b1-4f3a-a929-f76a84ff821c", "starts" => -1, "ends" => -1, "infoUrl" => "", "items" => [{"id" => "acb4df1f-7ba0-41cc-b8dc-eeeed22673f0", "start_date" => 1442041500, "end_date" => 1473836640, "start_position" => 0, "end_position" => 0, "number_of_times" => -1, "type" => "chapter"}, {"id" => "xy4df1f-7ba0-41cc-b8dc-eeeed22673f0", "start_date" => 1442041500, "end_date" => 1473836640, "start_position" => 0, "end_position" => 0, "number_of_times" => -1, "type" => "chapter"}]}, {"id" => "ad3c4dd2-baeb-499a-bc2c-161194425601", "starts" => 363464646, "ends" => 567567576, "infoUrl" => ""}, {"id" => "999508b7-a9d9-4042-a8ce-17bfa8c6e0a0", "starts" => 363464646, "ends" => 5675675794, "infoUrl" => "", "items" => [{"id" => "3454df1f-7ba0-41cc-b8dc-yuyfd22673f0", "start_date" => 1442041500, "end_date" => 1473836640, "start_position" => 0, "end_position" => 0, "number_of_times" => -1, "type" => "chapter"}]}]}
  end
end