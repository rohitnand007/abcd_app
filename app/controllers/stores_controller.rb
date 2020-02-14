class StoresController < ApplicationController
    def index
      @stores = Store.all
      @publishers = Publisher.all
    end

    def new
      @store = Store.new
    end
    def create
      @store = Store.new(params[:store])
      if @store.save
        redirect_to @store, notice: "Store Created Successfully."
      else
        render new_store_path, notice: "Error While Creating."
      end
    end
    def show
      @store = Store.find(params[:id])
      @associated_institutions = @store.institutions
      @associated_publishers = @store.publishers
    end
    def edit
      # Assigns tags and questions to question bank
      @store = Store.find(params[:id])
    end

    def update
      @store = Store.find(params[:id])
      respond_to do |format|
        if @store.update_attributes(params[:store])
          format.html { redirect_to @store, notice: 'Store successfully updated.' }
          format.json { head :ok }
        else
          format.html { render action: "edit" }
          format.json { render json: @store.errors, status: "Something went wrong !!" }
        end
      end
    end
    def destroy
      @store = Store.find(params[:id])
      @store.destroy

      respond_to do |format|
        format.html { redirect_to stores_url }
        format.json { head :ok }
      end
    end
    def select_ecps
      @store = Store.find(params[:id])
      @publishers = Publisher.all
      @publisher_stores = @store.publishers

    end
    def add_ecps
      @store = Store.find(params[:id])
      @publisher_stores = []
      @publisher_ids = []
      @ecp_ids = params[:ecp_ids]
      PublisherStore.where(store_id:@store.id).destroy_all
      @ecp_ids.each do |k|
        @publisher_stores  << PublisherStore.create(publisher_id:k,store_id:@store.id)
      end
      @publisher_stores = @publisher_stores.uniq
      redirect_to :action=>'show', :id=> @store.id , :notice => "ECPS added to store successfully"
    end
    def select_institutions
      @store = Store.find(params[:id])
      @institutions = Institution.all
      @institution_stores = @store.institutions
    end
    def add_institutions
      @store = Store.find(params[:id])
      @existing_institutions = @store.institutions
      @store_institutions = []
      @institute_ids = params[:institute_ids]
      @store.institutions.delete(@existing_institutions)
      @institute_ids.each do |k|
        @store.institutions << Institution.where(id:k)
      end
      redirect_to  :action=>'show', :id=>@store.id, :notice=> "Institutions_added_to_store_successfully"
    # def show_institution_stores
    #   @store = Store.find(params[:id])
    #   @associated_institutions = @store.institutions
    # end


    end
    # def show_ecpstore_publishers
    #   @store = Store.find(params[:id])
    #   @associated_publishers = @store.publishers
    # end
    def store_books
      @store = Store.find(params[:id])
      @associated_publishers = @store.publishers.flatten.uniq
      @storebooks = []
      @associated_publishers.each{|p| @storebooks << p.ibooks}
      @storebooks = @storebooks.flatten.uniq

    end
  end


