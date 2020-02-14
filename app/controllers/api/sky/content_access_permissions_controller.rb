class Api::Sky::ContentAccessPermissionsController < Api::Sky::BaseController
  before_filter :find_content_access_permission, only: [:show, :update, :destroy]
  # authorize_resource
  def index
    where_params = params.slice(*ContentAccessPermission.column_names) # removes key and gets only those params which can act as query filters    
    if where_params.present?
      @content_access_permissions = ContentAccessPermission.where(where_params)
    else
      @content_access_permissions = ContentAccessPermission.all
    end    
    render json: @content_access_permissions
  end

  def show
    render json: @content_access_permission
  end

  def create
    @content_access_permission = ContentAccessPermission.new(params[:content_access_permission])
    if @content_access_permission.save
      render json: @content_access_permission, status: :created, location: @content_access_permission
    else
      render json: @content_access_permission.errors, status: :unprocessable_entity
    end
  end

  def update
    if @content_access_permission.update_attributes(params[:content_access_permission])
      render json: @content_access_permission
    else
      render json: @content_access_permission.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @content_access_permission.destroy
    render json: :ok
  end

  def find_content_access_permission
    @content_access_permission = ContentAccessPermission.find(params[:id])
  end
end

