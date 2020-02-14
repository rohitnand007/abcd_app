class AssessmentsController < ApplicationController
  authorize_resource
  # GET /assessments
  # GET /assessments.json
  def index
    per_page=10
    if current_user.is?"EA"
      @assessments =  Content.assessment_types.default_order.page(params[:page]).per(per_page)
    else
      #@assessments = current_user.assessments.page(params[:page]).per(per_page)

      #commented above line due to new func implementation of publish now and publish later
      #need to get the assessments based on publisher_id of asset table and also assessments through test configurations groups
      all_assessment_ids = (current_user.assessments.map(&:id) + Asset.get_assessments_by_publisher_id(current_user.id).map(&:archive_id)).uniq
      @assessments =  Content.where(:id=>all_assessment_ids).default_order.page(params[:page]).per(per_page)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @assessments }
    end
  end

  # GET /assessments/1
  # GET /assessments/1.json
  def show
    @assessment = Content.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @assessment }
    end
  end

  # GET /assessments/new
  # GET /assessments/new.json
  def new
    @assessment = Assessment.new
    @assessment.build_asset
    @assessment.test_configurations.build
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @assessment }
    end
  end

  # GET /assessments/1/edit
  def edit
    @assessment = Content.find(params[:id])
  end

  # POST /assessments
  # POST /assessments.json
  def create
    @assessment = Assessment.new(params[:assessment])
    subject = Subject.find(params[:assessment][:subject_id]) rescue nil
    @assessment.board_id = subject.try(:board).try(:id)
    @assessment.content_year_id = subject.try(:content_year).try(:id)
    respond_to do |format|
      if @assessment.save
        @assessment.test_configurations.first.update_attribute(:uri,@assessment.uri)  if !@assessment.test_configurations.empty?
        #if @assessment.status == 1
        est = current_user.center.est
        Content.send_message_to_est(est,current_user,@assessment)
        #end
        format.html { redirect_to @assessment, notice: 'Assessment was successfully created.' }
        format.json { render json: @assessment, status: :created, location: @assessment }
      else
        format.html { render action: "new" }
        format.json { render json: @assessment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /assessments/1
  # PUT /assessments/1.json
  def update
    @assessment = Content.find(params[:id])
    if current_user.role.id == 7
      params[:assessment][:status] = 6
    end
    respond_to do |format|
      if @assessment.update_attributes(params[:assessment])
        if @assessment.status == 6
          Content.send_message_to_est(current_user.center.est,current_user,@assessment)
        end
        format.html { redirect_to @assessment, notice: 'Assessment was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @assessment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /assessments/1
  # DELETE /assessments/1.json
  def destroy
    @assessment = Content.find(params[:id])
    @assessment.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessments_url }
      format.json { head :ok }
    end
  end

  #Assessments templates
  def assessment_templates
    @iit = File.open("#{Rails.root}/public/assessment-templates/iit.doc","rb")
    @mock = File.open("#{Rails.root}/public/assessment-templates/mock.doc","rb")
    @olimpaid = File.open("#{Rails.root}/public/assessment-templates/olimpaid.doc","rb")
    @quiz = File.open("#{Rails.root}/public/assessment-templates/quiz.doc","rb")
  end

  #get /assessments/testconfigurations/1
  def test_configurations
    @assessment = Content.find(params[:id])
    #students = current_user.type.eql?('Teacher') ? current_user.my_students  : (current_ea ? User.students : current_user.students)
    #@test_configurations = @assessment.test_configurations.where('group_id IN(?) or group_id IN(?)',current_user.get_groups,students)
    @test_configurations = current_user.test_configurations_by_assessments([@assessment.try(:id)]).default_order
    if !@test_configurations.empty?
      @test_configurations.each do |test_configuration|
         test_configuration.evaluate if test_configuration.can_evaluate? # if published or evaluated
      end
    end
    respond_to do |format|
      format.js {}
    end
  end

  def load_test_configuration
    @assessment = Assessment.new
    respond_to do |format|
      format.js {}
    end
  end

  #download the file with folders structure and ncx
  def download
    @assessment = Assessment.find(params[:id])
    if current_user.role.name.eql?('Support Team')
      @assessment.update_attribute(:status,5)
    end
    send_file process_zip(@assessment,@assessment.asset)
  end

  def process_zip(content,asset)
    path = Rails.root.to_s+"/tmp/cache/downloads/assessment_#{content.id}"
    src = asset.src
    src = src.gsub(asset.attachment_file_name,"")
    folder_path = path+src
    file_path = Rails.root.to_s+"/public"+src
    FileUtils.mkdir_p folder_path
    FileUtils.cp_r "#{file_path}/.",folder_path
    generate_ncx(content,path)
  end

  def generates_ncx(content,path)
    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum", :class=>"curriculum"){
          xml.content(:src=>"curriculum")
          xml.navPoint(:id=>"Assessment",:class=>"assessment"){
            xml.content(:src=>"assessments")
            xml.navPoint(:id=>content.subject.board.name,:class=>"course"){
              xml.content(:src=>content.subject.board.code+"_"+content.asset.publisher_id.to_s)
              xml.navPoint(:id=>content.subject.content_year.name,:class=>"academic-class"){
                xml.content(:src=>content.subject.content_year.name)
                xml.navPoint(:id=>content.assessment_type,:class=>"assessment-category"){
                  xml.content(:src=>"practice")
                xml.navPoint(:id=>content.subject.name,:class=>"subject"){
                  xml.content(:src=>content.subject.code)
                  xml.navPoint(:id=>content.name, :class=>"assessment-"+content.assessment_type){
                      xml.content(:src=>content.asset.url.split("?").first)
                  }
                }
              }
            }
          }
        }
      }
     }
    end
    xml_string =  @builder.to_xml.to_s
    file = File.new(path+"/"+"index.ncx", "w+")
    File.open(file,'w') do |f|
      f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
    end
    create_zip("assessment_#{content.id}",path)
  end


  def published_assessments
    per_page=10
    @assessments = Assessment.where(:id=> Asset.where(:publisher_id=>current_user.id,:archive_type=>"Assessment").where("attachment_file_name!=?",'nil').map(&:archive_id)).default_order.page(params[:page]).per(per_page)
    respond_to do |format|
      format.html
    end
  end


end
