class DeviceDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view, current_user={})
    @view = view
    @current_user = current_user
    puts "Current User --------------"
    puts current_user.role.name
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Device.count,
      iTotalDisplayRecords: devices.total_count,
      aaData: data
    }
  end

private

  def data
    devices.map do |device|
      [
        # link_to(product.name, product),
        # h(product.category),
        # h(product.released_on.strftime("%B %e, %Y")),
        # number_to_currency(product.price)
        device.deviceid,
        device.mac_id,
        device.device_type
      ]
    end
  end

  def devices
    #devices = @devices
    devices ||= fetch_products
  end

  def fetch_products
     devices = case @current_user.role.name when 'Edutor Admin'
                                             Device.page(page).per(per_page)
                                           when 'Center Representative'
                                             @current_user.center.center_devices.page(page).per(per_page)
                                           when 'Institute Admin'
                                             @current_user.institution.institution_devices.page(page).per(per_page)
                                           else
                                             @current_user.center.center_devices.page(params[:page])
               end


    #devices = Device.page(page1).per(per_page)
    if params[:sSearch].present?
      devices = devices.where("deviceid like :search or mac_id like :search", search: "%#{params[:sSearch]}%")
    end
    devices
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 25
  end

  def sort_column
    columns = %w[deviceid mac_id device_type]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
