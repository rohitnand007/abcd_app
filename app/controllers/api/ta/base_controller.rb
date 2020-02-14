class Api::Ta::BaseController < ActionController::Base
  respond_to :json

  def redirect_to_auth_page
    client_id = params[:client_id]

    client_secret = params[:client_secret]

    redirect_uri = "http://localhost:5000/auth_token_setter"

    site = "http://localhost:3000"

    client = OAuth2::Client.new(client_id, client_secret, :site => site)

    @generated_url =  client.auth_code.authorize_url(:redirect_uri => redirect_uri)

    redirect_to @generated_url


  end

end
