class BoardsController < ApplicationController
  require 'DataTable'
authorize_resource :except=>[:get_content_years,:get_content_code]
  # GET /boards
  # GET /boards.json
  def index
    if params[:q].present?
      @boards =  Board.where('name like ?',"%#{params[:q]}%")
    else
      @boards = case current_user.role.name
                when 'Edutor Admin'
                  Board.page(params[:page])
                when 'Institute Admin'
                  current_user.institution.boards.page(params[:page])
                when 'Center Representative'
                  current_user.center.boards.page(params[:page])
              end
    end
   #@users = Institution.find(1020).students.limit(10)
   if request.xhr?
      data = DataTable.new
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], Board.count)
      boards = case current_user.role.name when 'Edutor Admin'
                          Board.where("name like :search", search: "%#{searchParams}%")
                        when 'Institute Admin'
                          current_user.institution.boards.where("name like :search", search: "%#{searchParams}%")
                        when 'Center Representative'
                          current_user.center.boards.where("name like :search", search: "%#{searchParams}%")
                end
      total_boards= boards.count
      data.set_total_records(total_boards)
      #Limiting Records
      boards = boards.page(data.page).per(data.per_page)
      #sort records
      columns = ['name', 'code']
      if(params[:iSortCol_0].present?)
          column = columns[params[:iSortCol_0].to_i]
          direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
          boards = boards.order(column +" "+  direction)
      end
      #Final Records
      boards.map!.with_index do |board, index|
        # %tr{:class => cycle("tr-odd", "tr-even"),:id=>"board_#{board.id}"}
        #             %td.col= link_to board.name, board_path(board)
        #             %td.col=  board.code
        #             %td.col= display_date_time(board.created_at)
        #             %td.col
        #               = link_to_show(board_path(board))
        row_class = index%2==1 ? "tr-odd" : "tr-even"
        {
          "DT_RowId" => "board_#{board.id}",
          "DT_RowClass" => row_class,
          "0" => view_context.link_to(board.name, board_path(board)),
          "1" => board.code,
          "2" => view_context.display_date_time(board.created_at),
          "3" => view_context.link_to_show(board_path(board))
        }
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      if params[:q].present?
        format.json { render json: @boards }
      elsif request.xhr?
        format.json { render json: data.as_json(boards) }
      end
      #format.xml {render xml: @users.to_xml(:include => :assets)}
    end
  end

  # GET /boards/1
  # GET /boards/1.json
  def show
    @board = Board.find(params[:id])
    @content_years =  @board.content_years.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @board }
    end
  end

  # GET /boards/new
  # GET /boards/new.json
  def new
    @board = Board.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @board }
    end
  end

  # GET /boards/1/edit
  def edit
    @board = Board.find(params[:id])
  end

  # POST /boards
  # POST /boards.json
  def create
    @board = Board.new(params[:board])

    respond_to do |format|
      if @board.save
        format.html { redirect_to @board, notice: 'board was successfully created.' }
        format.json { render json: @board, status: :created, location: @board }
      else
        format.html { render action: "new" }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /boards/1
  # PUT /boards/1.json
  def update
    @board = Board.find(params[:id])

    respond_to do |format|
      if @board.update_attributes(params[:board])
        format.html { redirect_to @board, notice: 'board was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /boards/1
  # DELETE /boards/1.json
  def destroy
    @board = Board.find(params[:id])
    @board.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to boards_url }
      format.json { head :ok }
    end
  end
  #get the content years for the selected board by a vendor in a subject new page
  def get_content_years
    @board = Board.find(params[:id]) rescue nil
    #list = ContentYear.where(:board_id => @Board.id,:publisher_id => current_user.id).map {|u| Hash[value: u.id, name: u.name]}
    list = @board.content_years.map {|u| Hash[value: u.id, name: u.name]} rescue []
    render json: list
  end

  #get the content code for the selected content year in page
  def get_content_code
    @board = Subject.find_by_name(params[:name])
    list = Hash.new
    list = [value:@board.code,name:@board.code]
    render json: list
  end

end
