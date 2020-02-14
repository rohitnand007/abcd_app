class PublishersController < ApplicationController
   authorize_resource
  # GET /publishers
  # GET /publishers.json
  def index
    @publishers = Publisher.order("id DESC").page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @publishers }
    end
  end

  # GET /publishers/1
  # GET /publishers/1.json
  def show
    @publisher = Publisher.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @publisher }
    end
  end

  # GET /publishers/new
  # GET /publishers/new.json
  def new
    @publisher = Publisher.new
    @publisher.build_profile
    @centers = Center.all
    @institutions= Institution.all
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @publisher }
    end
  end

  # GET /publishers/1/edit
  def edit
    @publisher = Publisher.find(params[:id])
    @centers = Center.all
    @institutions= Institution.all
  end

  # POST /publishers
  # POST /publishers.json
  def create
    @white_institution_ids = params[:publisher][:white_institution_ids].present? ? params[:publisher][:white_institution_ids] : []
    @white_center_ids = params[:publisher][:white_center_ids].present? ? params[:publisher][:white_center_ids] : []
    publisher_params = params[:publisher].except(:white_institution_ids,:white_center_ids)
    @publisher = Publisher.new(publisher_params)
     puts @publisher.inspect

    respond_to do |format|
      if @publisher.save
        @publisher.white_institution_ids = @white_institution_ids
        @publisher.white_center_ids = @white_center_ids
        format.html { redirect_to @publisher, notice: 'Publisher was successfully created.' }
        format.json { render json: @publisher, status: :created, location: @publisher }
      else
        # @publisher.build_profile unless @publisher.profile_loaded?
        @centers = Center.all
        @institutions= Institution.all
        format.html { render action: "new", notice: "#{@publisher.errors.full_messages}" }
        format.json { render json: @publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /publishers/1
  # PUT /publishers/1.json
  def update
    @publisher = Publisher.find(params[:id])

    respond_to do |format|
      if @publisher.update_attributes(params[:publisher])
        format.html { redirect_to @publisher, notice: 'Publisher was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /publishers/1
  # DELETE /publishers/1.json
  def destroy
    @publisher = Publisher.find(params[:id])
    @publisher.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to publishers_url }
      format.json { head :ok }
    end
  end

  # Getting the licenses of the publisher
  def licenses
    publisher_id = current_user.id
    @licenses = PowerChip.where(:publisher_id=>publisher_id)
    respond_to do |format|
      format.html # licenses.html.erb
      format.json { render json: @licenses }
    end
  end

  # This is the method for editing the license of the publisher
  def edit_license
    publisher_id = current_user.id
    @license = PowerChip.where(:id=>params[:id], :publisher_id=>publisher_id).first
    @license.start_date = @license.start_date*1000
    @license.end_date = @license.end_date*1000
  end

  # This is the method for saving the license of the publisher
  def save_license
    @power_chip = PowerChip.find(params[:id])
    respond_to do |format|
      params[:power_chip]["start_date"] = params[:power_chip]["start_date"].to_i/1000
      params[:power_chip]["end_date"] = params[:power_chip]["end_date"].to_i/1000
      if @power_chip.update_attributes(params[:power_chip])
        format.html { redirect_to publisher_licenses_path, notice: 'License was successfully updated.' }
      else
        format.html { render action: "edit_license" }
        format.json { render json: @power_chip.errors, status: :unprocessable_entity }
      end
    end
  end

  # This is the method for uploading the publisher licenses
  def upload_licenses
    
  end

  # This method is for processing the uploaded csv licenses
  # TODO: The CSV Upload is pending
  def process_licenses_csv_upload
    publisherId = current_user.id
    if params[:csv_file]
        begin
          n = 0
          CSV.parse(params[:csv_file].read) do |row|
            n += 1
            next if n == 1 or row.join.blank?
            power_chip = PowerChip.build_from_csv(row)
            power_chip.publisher_id = publisherId
            power_chip.status = 'added'
            power_chip.save
          end
          respond_to do |format|
            format.html { redirect_to publisher_licenses_path, notice: "License Keys Uploaded Successfully" }
          end
        rescue Exception => e
          logger.debug(e.message)
          flash[:error] = "Something went wrong.Please check the CSV file."
          redirect_to :back
        end
    end
  end

  def dashboard

  end

   def schools
     @institutions = current_user.white_institutions
     @centers = current_user.white_centers
   end
  def monthly_publisher_status
    a = []
    b = []
    # all_ids = [84812,120602,168160,162283,88574,134555,83942,70316,168892,81165,82460,82832,82962,88508,88559,107251,100011,132890,147360,150342,150748,151215,135705]
    all_ids = Publisher.all.map(&:id)
    Publisher.where(id: all_ids).each do |publisher|
      if publisher.present?
      # a << {publisher.edutorid => {"april"=>[[],[]],"may"=>[[],[]],"june"=>[[],[]],"july"=>[[],[]],"august"=>[[],[]],"september"=>[[],[]]}}
      if publisher.license_sets.present?
      publisher.license_sets.each do |k|
        if (k.starts >= 5.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 4.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"April", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["april"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["april"][1] << k.utilized

        elsif (k.starts >= 4.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 3.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"May", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["may"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["may"][1] << k.utilized

        elsif (k.starts >= 3.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 2.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"June", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end

          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["june"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["june"][1] << k.utilized

        elsif (k.starts >= 2.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 1.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [publisher.name, publisher.id,"July",  l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["july"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["july"][1] << k.utilized

        elsif (k.starts >= 1.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 0.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"August", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["august"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["august"][1] << k.utilized

        elsif (k.starts >= 0.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 0.months.ago.to_date.at_end_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"September", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["september"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["september"][1] << k.utilized

        end
      end
      end
     end
    end
    # a.each do |k|
    #
    #   b << [k.first[0],k.first[1]["april"][0].inject(0, :+), k.first[1]["april"][1].inject(0, :+),k.first[1]["may"][0].inject(0, :+), k.first[1]["may"][1].inject(0, :+),k.first[1]["june"][0].inject(0, :+), k.first[1]["june"][1].inject(0, :+),k.first[1]["july"][0].inject(0, :+), k.first[1]["july"][1].inject(0, :+),k.first[1]["august"][0].inject(0, :+), k.first[1]["august"][1].inject(0, :+),k.first[1]["september"][0].inject(0, :+), k.first[1]["september"][1].inject(0, :+)]
    #   puts k
    # end
    # csv_header1 = "ECP ID,Book_id,Book_name,Apr-16,Apr-16,May-16,May-16 ,June-16,June-16,July-16,July-16,Aug-16,Aug-16,Sep-16,Sep-16".split(",")
    csv_header1 = "Publisher Name,ECP ID,Month  ,Book ID, Book Name,Licenses Issued, Licenses Consumed ".split(",")
    file_name1 = Time.now.to_i.to_s+ "_" + ".csv"
    # CSV.open(file_name1,'w', :write_headers=>true,:headers=>csv_header1) do |hdr|
    #   b.each do |k|
    #     hdr << [k[0],k[1],k[2],k[3],k[4],k[5],k[6],k[7],k[8],k[9],k[10],k[11],k[12]]
    #   end
    # end
    csv_data1 = FasterCSV.generate do |csv|
      csv << csv_header1
      a.each do |row|
        csv << [row[0], row[1], row[2], row[3], row[4], row[5], row[6]]
      end
    end
    send_data csv_data1, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name1}"
  end
  def monthly_institution_wise_status
    a = []
    all_ids = Institution.all.map(&:id)
    Institution.where(id: all_ids).each do |publisher|
      publisher.license_sets.each do |k|
        if publisher.license_sets.present?
        if (k.starts >= 25.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 4.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"April", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["april"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["april"][1] << k.utilized

        elsif (k.starts >= 4.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 3.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"May", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["may"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["may"][1] << k.utilized

        elsif (k.starts >= 3.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 2.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"June", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end

          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["june"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["june"][1] << k.utilized

        elsif (k.starts >= 2.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 1.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [publisher.name, publisher.id,"July",  l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["july"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["july"][1] << k.utilized

        elsif (k.starts >= 1.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 0.months.ago.to_date.at_beginning_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"August", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["august"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["august"][1] << k.utilized

        elsif (k.starts >= 0.months.ago.to_date.at_beginning_of_month.to_time.to_i  and k.starts < 0.months.ago.to_date.at_end_of_month.to_time.to_i)
          Ipack.find(k.ipack_id).ibooks.each do |l|
            a << [ publisher.name, publisher.id,"September", l.ibook_id, l.get_title, k.licenses, k.utilized ]
          end
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["september"][0] << k.licenses
          # a.find{|j| j[publisher.edutorid]}[publisher.edutorid]["september"][1] << k.utilized
        end
        end
      end
    end
    csv_header1 = "Institution Name,Institute ID,Month  ,Book ID, Book Name,Licenses Issued, Licenses Consumed ".split(",")
    file_name1 = Time.now.to_i.to_s+ "_" + ".csv"
    # CSV.open(file_name1,'w', :write_headers=>true,:headers=>csv_header1) do |hdr|
    #   b.each do |k|
    #     hdr << [k[0],k[1],k[2],k[3],k[4],k[5],k[6],k[7],k[8],k[9],k[10],k[11],k[12]]
    #   end
    # end
    csv_data1 = FasterCSV.generate do |csv|
      csv << csv_header1
      a.each do |row|
        csv << [row[0], row[1], row[2], row[3], row[4], row[5], row[6]]
      end
    end
    send_data csv_data1, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name1}"

  end
  
end
