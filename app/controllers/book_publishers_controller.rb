class BookPublishersController < ApplicationController
  authorize_resource :only => [:edit, :index,:new, :show]
  # GET /book_publishers
  # GET /book_publishers.json
  def index
    @book_publishers = BookPublisher.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @book_publishers }
    end
  end

  # GET /book_publishers/1
  # GET /book_publishers/1.json
  def show
    @book_publisher = BookPublisher.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @book_publisher }
    end
  end

  # GET /book_publishers/new
  # GET /book_publishers/new.json
  def new
    @book_publisher = BookPublisher.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @book_publisher }
    end
  end

  # GET /book_publishers/1/edit
  def edit
    @book_publisher = BookPublisher.find(params[:id])
  end

  # POST /book_publishers
  # POST /book_publishers.json
  def create
    @book_publisher = BookPublisher.new(params[:book_publisher])

    respond_to do |format|
      if @book_publisher.save
        format.html { redirect_to @book_publisher, notice: 'Book publisher was successfully created.' }
        format.json { render json: @book_publisher, status: :created, location: @book_publisher }
      else
        format.html { render action: "new" }
        format.json { render json: @book_publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /book_publishers/1
  # PUT /book_publishers/1.json
  def update
    @book_publisher = BookPublisher.find(params[:id])

    respond_to do |format|
      if @book_publisher.update_attributes(params[:book_publisher])
        format.html { redirect_to @book_publisher, notice: 'Book publisher was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @book_publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /book_publishers/1
  # DELETE /book_publishers/1.json
  def destroy
    @book_publisher = BookPublisher.find(params[:id])
    @book_publisher.destroy

    respond_to do |format|
      format.html { redirect_to book_publishers_url }
      format.json { head :ok }
    end
  end
end
