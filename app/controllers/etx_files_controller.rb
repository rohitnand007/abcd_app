class EtxFilesController < ApplicationController
  # GET /etx_files
  # GET /etx_files.json
  authorize_resource
  def index
    # @etx_files = EtxFile.order('created_at DESC')
    # respond_to do |format|
    #   format.html # index.html.erb
    #   format.json { render json: @etx_files }
    # end
    require "DataTable"
    @etx_files = EtxFile.order('created_at DESC')
    if request.xhr?
      data = DataTable.new()
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      globalsearchParams = params[:search_term]
      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], EtxFile.count)
      if globalsearchParams == "false"
      etx_files = EtxFile.where("ques_no IS NOT NULL").where('ques_no like :search', search: "%#{searchParams}%").order("created_at desc")
      else
        etx_files = EtxFile.where("ques_no IS NOT NULL").where('zip_upload_id like :search', search: "%#{searchParams}%").order("created_at desc")
      end
      total_etx_files= etx_files.count
      etx_files = etx_files.page(data.page).per(data.per_page)
      data.set_total_records(total_etx_files)
      #Sorting Records
      etx_files.map!.with_index do |etx_file, index|
        row_class = index%2==1 ? "tr-odd" : "tr-even"
        {
            "DT_RowId" => "etx_file_#{etx_file.id}",
            "DT_ClassId" => row_class,
            "0" => view_context.link_to(etx_file.zip_upload_id , "/zip/#{etx_file.zip_upload_id.to_s}/etx_list"),
            "1" => etx_file.filename.split('/').last,
            "2" => etx_file.ques_no.split(",").each_slice(10).to_a.map{|p| p.to_s.gsub("[","").gsub("]","") + "<br>"},
            "3" => etx_file.status? ? "Deleted" : "Available",
            "4" => etx_file.status? ? "" : view_context.link_to('Destroy', etx_file, :confirm => 'Are you sure?', :method => :delete)
        }
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      if request.xhr?
        format.json { render json: data.as_json(etx_files)}
      else
        format.json { render json: @etx_files }
      end
      format.json { render json: @etx_files }
    end
  end

  # DELETE /etx_files/1
  # DELETE /etx_files/1.json
  def destroy
    @etx_file = EtxFile.find(params[:id])
    
    arr = @etx_file.ques_no.split(",")
    Question.destroy(arr)
    @etx_file.update_attributes(status: true)
    #@etx_file.destroy

    respond_to do |format|
      format.html { redirect_to etx_files_url }
      format.json { head :ok }
    end
  end
end
