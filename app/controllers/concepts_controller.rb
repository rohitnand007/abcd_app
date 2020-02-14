class ConceptsController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show, :publish, :new_concept, :new_concept_map, :data, :save_element, :add_new_element, :delete_elements, :show_concept_map]
#  layout :get_layout

# GET /concepts
# GET /concepts.json
  def index
    #@concepts = Concept.all#order('updated_at DESC')

    #Displaying institute specific concepts
    @concepts = case current_user.role.name when 'Edutor Admin'
                                                  Concept.all
                                            when 'Institute Admin'
                                                  Concept.where(:institution_id=>current_user.institution_id)
                                            when 'Teacher'
                                                  Concept.where(:user_id => current_user.id)
                                            else
                                                  Concept.where(:user_id => current_user.id)
                end

    #TO Differentiate new and old concept maps
    @new_concepts = ConceptElement.where("x IS NOT NULL").where(:parent_id => nil)
    @new_ids = Array.new
    @new_concepts.each do |e|
      @new_ids << e.concept_id
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @concepts }
    end
  end

  # GET /concepts/1
  # GET /concepts/1.json
  def show
    @concept = Concept.find(params[:id])
    #@concept_element=ConceptElement.find_all_by_concept_id(@concept.id, :order => "id")
    @root = @concept.concept_elements.roots
    print (@root.first())
    @val=@root.first().id
    @val=@val-1
    #    builder = Nokogiri::XML::Builder.new do |xml|
    #      xml.cmap_file {
    #
    #        xml.cmap(:id => @root.first().id-@val, :parent_id => @root.first().id-@val) {
    #          if @root.first().name!=nil
    #            xml.name { xml.cdata @root.first().name }
    #          else
    #            xml.name { xml.cdata "" }
    #          end
    #          if @root.first().description!= nil
    #            xml.detail { xml.cdata @root.first().description }
    #          else
    #            xml.detail { xml.cdata "" }
    #          end
    #        }
    #        #buildChild((@root.first()), xml)
    #      }
    #    end
    #    puts builder.to_xml
    #    @file=File.new("conceptMap.xml", "w")
    #    @file.puts(builder.to_xml)
    #    #loadurl("file:///C:/Users/Suresh/Desktop/Edutor/latest/conceptmap/conceptmap/ConceptMap.html?file_path=conceptMap.xml")
    #
    #    @file.close
    #    Launchy.open ("C:/ConceptMap.html");
    #    #:file => Rails.root.to_s+"/public/conceptmap/ConceptMap.html?file_path=conceptMap.xml"
    #=begin

    #@elements = {}
    #parent_ids = []
    #@elements = @concept.concept_elements
    #@p = get_json_elements(@elements)
    #logger.info"=============#{p}"
    #logger.info"=============#{@elements}"
    @elements =  @concept.concept_elements
    #render :layout=>'conceptmap',:action=>'new'
    respond_to do |format|
      format.html { render :layout=>'conceptmap'}
      #format.json { render :text=>@concept.to_s }
      format.xml
    end

  end

  def get_json_elements(elements)
    elements.each do |e|
      @ele = {:name=>e.name,:detail=>e.description,:parent_id=>e.parent_id,:childs=>get_json_elements(e.children)}
    end
    @elements = @ele
  end

  def buildJsonObject(jsonObject, concept_element)
    unless concept_element.children.empty?
      @childCnt=concept_element.children.length;
      @i=0
      for child in concept_element.children
        #jsonObject=Hash.new
        jsonObject["id"] = child.id-@val
        jsonObject["parent_id"] = child.parent_id-@val
        if child.name!=nil
          jsonObject["name"]= child.name
        else
          jsonObject["name"]= ""
        end
        if child.description!= nil
          jsonObject["detail"]= child.description
        else
          jsonObject["detail"]= ""
        end
        jsonObject["child"]=Hash.new
        jsonObject["child"][@i]=Hash.new
        buildJsonObject(jsonObject["child"][@i], child)
        @i=@i+1
      end
    end
  end


  def buildChild(concept_element, xml)
    unless concept_element.children.empty?
      for child in concept_element.children
        xml.cmap(:id => child.id-@val, :parent_id => child.parent_id-@val) {
          if child.name!=nil
            xml.name { xml.cdata child.name }
          else
            xml.name { xml.cdata "" }
          end
          if child.description!= nil
            xml.detail { xml.cdata child.description }
            #unless child.description.match("data:image/")
              @images = @images+extract_images(child.description)
            #end
          else
            xml.detail { xml.cdata "" }
          end
        }
        buildChild(child, xml)
      end
    end
  end

  # GET /concepts/new
  # GET /concepts/new.json
  #def new
  #  @concept = Concept.new
  #  @quizes=Quiz.all
  #  respond_to do |format|
  #    format.html # new.html.erb
  #    format.json { render json: @concept, @quizes => quizes_path }
  #  end
  #end

  # GET /concepts/1/edit
  def edit
    @concept = Concept.find(params[:id])
  end

  # POST /concepts
  # POST /concepts.json
  def create
    string = request.body.read
    @parseConceptJson =  ActiveSupport::JSON.decode(string)
    logger.info"ConceptJson=========#{@parseConceptJson}"
    if @parseConceptJson['conceptmap_id'] == 'null'
      @concept = Concept.new
      #@conceptJson["id"]["name"]["details"]["parentId"]=@concept.concept
      #@parseConceptJson=JSON.load(@concept.concept)
      #print @parseConceptJson["id"]
      @concept.name=@parseConceptJson["conceptmap_name"]
      @concept.board_id=@parseConceptJson["board_id"]
      @concept.content_year_id=@parseConceptJson["class_id"]
      @concept.subject_id=@parseConceptJson["subject_id"]
      @concept.chapter_id=@parseConceptJson["chpater_id"]
      @elements = @parseConceptJson["cmap"]
      respond_to do |format|
        if @concept.save
          @concept_element=ConceptElement.create("name" => @elements["name"], "description" => @elements["detail"], "concept_id" => @concept.id)
          insertConceptElement(@elements, @concept, @concept_element)
          format.html { redirect_to @concept, notice: 'Concept was successfully created.' }
          format.json { render json: 200, status: :created, location: @concept }
        else
          format.html { render action: "new" }
          format.json { render json: 404, status: :unprocessable_entity }
        end
      end

    else
      @concept = Concept.find(@parseConceptJson['conceptmap_id'])
      @elements = @parseConceptJson["cmap"]
      respond_to do |format|
        if @concept
          @concept.concept_elements.destroy_all
          @concept_element=ConceptElement.create("name" => @elements["name"], "description" => @elements["detail"], "concept_id" => @concept.id)
          insertConceptElement(@elements, @concept, @concept_element)
          format.html { redirect_to @concept, notice: 'Concept was successfully created.' }
          format.json { render json: 200, status: :created, location: @concept }
        else
          format.html { render action: "new" }
          format.json { render json: 404, status: :unprocessable_entity }
        end
      end
    end


  end

  def insertConceptElement(jsonString, concept, concept_element)

    if jsonString["childs"]!= nil
      logger.info "=======#{jsonString["childs"]}"
      for childs in jsonString["childs"]
        logger.info "===child====#{childs}"
        @concept_element_child=concept_element.children.create("name" => childs["name"], "description" => childs["detail"], "concept_id" => concept.id)
        if childs
          insertConceptElement(childs, concept, @concept_element_child)
        end
      end
    end
  end

  # PUT /concepts/1
  # PUT /concepts/1.json
  def update
    @concept = Concept.find(params[:id])

    respond_to do |format|
      if @concept.update_attributes(params[:concept])
        format.html { redirect_to @concept, notice: 'Concept was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @concept.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /concepts/1
  # DELETE /concepts/1.json
  def destroy
    @concept = Concept.find(params[:id])
    @concept.destroy

    respond_to do |format|
      format.html { redirect_to concepts_url }
      format.json { head :no_content }
    end
  end


  def publish
    @concept = Concept.find(params[:id])
    @message = Message.new

  end


  def publish_save
    require 'archive/zip'
    @concept = Concept.find(params[:id])
    @root = @concept.concept_elements.roots
    print (@root.first())
    @val=@root.first().id
    @val=@val-1
    @images = []
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.cmap_file {
        xml.cmap(:id => @root.first().id-@val, :parent_id => @root.first().id-@val) {
          if @root.first().name!=nil
            xml.name { xml.cdata @root.first().name }
          else
            xml.name { xml.cdata "" }
          end
          if @root.first().description!= nil
            xml.detail { xml.cdata @root.first().description }
            #unless @root.first().description.match("data:image")
              @images = @images+extract_images(@root.first().description)
            #end
          else
            xml.detail { xml.cdata "" }
          end
        }
        buildChild((@root.first()), xml)

      }
    end
    #puts builder.to_xml
    path = Rails.root.to_s+"/public/concept_maps/"+Time.now.to_i.to_s
    FileUtils.mkdir_p path+'/concept_images'
    unless File.exist?(Rails.root.to_s+'/public/concept_maps')
      FileUtils.mkdir Rails.root.to_s+'/public/concept_maps'
    end
    @file_name = "concept_map#{Time.now.to_i.to_s}"

    file=File.new(path+"/#{@file_name}.ecm", "w")
    File.open(path+"/#{@file_name}.ecm",  "w+b", 0644) do |f|
      f.write(builder.to_xml.to_s)
    end
    concept_xml = Nokogiri::XML::Builder.new do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
          xml.content(:src=>"curriculum")
          xml.navPoint(:id=>"Content",:class=>"content"){
            xml.content(:src=>"content")
            xml.navPoint(:id=>@concept.board.name.to_s,:class=>"course"){
              xml.content(:src=>"cb_02")
              xml.navPoint(:id=>@concept.content_year.name.to_s,:class=>"academic-class"){
                xml.content(:src=>@concept.content_year.name.to_s)
                xml.navPoint(:id=>@concept.subject.name.to_s,:class=>"subject"){
                  xml.content(:src=>@concept.subject.code)
                  if @concept.chapter_id.nil? and @concept.topic_id.nil?
                    xml.navPoint(:id=>@concept.id,:class=>"concept-map",:displayName=>@concept.name){
                      xml.content(:src=>"/#{@file_name}.ecm")
                    }
                  end
                  if @concept.chapter_id
                    xml.navPoint(:id=>@concept.chapter.name,:class=>"chapter",:playOrder=>@concept.chapter.play_order){
                      xml.content(:src=>@concept.chapter.try(:assets).last.try(:src), :params=>@concept.chapter.params)
                      xml.navPoint(:id=>@concept.id,:class=>"concept-map",:displayName=>@concept.name){
                        xml.content(:src=>"/#{@file_name}.ecm")
                      }
                    }
                  end
                  if @concept.chapter_id  and @concept.topic_id
                    xml.navPoint(:id=>@concept.chapter.name,:class=>"chapter",:playOrder=>@concept.chapter.play_order){
                      xml.content(:src=>@concept.chapter.assets.last.try(:src), :params=>@concept.chapter.params)
                      xml.navPoint(:id=>@concept.topic.name,:class=>"topic",:playOrder=>@concept.topic.play_order){
                        xml.content(:src=>@concept.topic.try(:assets).last.try(:src), :params=>@concept.topic.params)
                        xml.navPoint(:id=>@concept.id,:class=>"concept-map",:displayName=>@concept.name){
                          xml.content(:src=>"/#{@file_name}.ecm")
                        }
                      }

                    }
                  end

                }
              }
            }
          }
        }
      }
    end

    index_file=File.new(path+"/index.ncx", "w")
    File.open(path+"/index.ncx",  "w+b", 0644) do |f|
      f.write(concept_xml.to_xml.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><') )
    end

    @images.each do |i|
      i = i.gsub("../",'')
      FileUtils.cp_r Rails.root.to_s+"/public/"+i, path+"/concept_images/"
    end
    Archive::Zip.archive("#{Rails.root.to_s}/public/concept_maps/#{@file_name}.zip", "#{path}/.")
    attachment = File.new("#{Rails.root.to_s}/public/concept_maps/#{@file_name}.zip",'r')


    @multiple_receiver_ids = params[:message][:multiple_recipient_ids].split(',')
    unless @multiple_receiver_ids.empty?
      @multiple_receiver_ids.each do |i|
        @message = Message.new(params[:message])
        @message.recipient_id =  i.to_i #params[:quiz_targeted_group][:group_id]
        @message.sender_id = current_user.id
        #@message.body = "/Curriculum/#{@concept.id}"
        @message.body = "$:/Curriculum/Content/#{@concept.board.name}/#{@concept.content_year.name}/#{@concept.subject.name}/#{@concept.chapter.name}/#{@concept.id}"
        @message.message_type = 'Content'
        @message.subject = "#{@concept.name}"
        @asset = @message.assets.build
        @asset.attachment = attachment
        @message.save
      end
    else
      @message = Message.new(params[:message])
      @message.group_id =  params[:quiz_targeted_group][:group_id]
      @message.sender_id = current_user.id
      #@message.body = "/Curriculum/#{@concept.id}"
      @message.body = "$:/Curriculum/Content/#{@concept.board.name}/#{@concept.content_year.name}/#{@concept.subject.name}/#{@concept.chapter.name}/#{@concept.id}"
      @message.message_type = 'Content'
      @message.subject = "#{@concept.name}"
      @asset = @message.assets.build
      @asset.attachment = attachment
      @message.save
    end
    respond_to do |format|
      format.html { redirect_to concepts_url }
    end

  end

  def extract_images(string)
    string = string.gsub('src="./','src="')
    string = string.gsub("src='./","src='")
    string = string.gsub("<image","<img")
    string = string.gsub("</image","</img")
    #string = string.gsub('src="','src="/question_images/')
    #string = string.gsub("src='./","src='/question_images/")
    doc = Nokogiri::HTML(string)
    img_srcs = doc.css('img').map{ |i| i['src'] } # Array of strings
    #img_srcs1 = doc.css('image').map{ |i| i['src'] }
    #return img_srcs+img_srcs1
    return img_srcs
  end
  #
  #  def get_layout
  #    if ['new','show'].include? action_name
  #      'conceptmap'
  #    else
  #      'application'
  #    end
  #  end
  #

  def new
    render :layout=>'conceptmap'
  end


  def new_concept
    @concept = Concept.new
    @concept.name = params[:name]
    @concept.board_id = params[:board_id].to_i
    @concept.content_year_id = params[:content_year_id].to_i
    @concept.subject_id = params[:subject_id].to_i
    @concept.chapter_id = params[:chapter_id].to_i

    @concept.institution_id = case current_user.role.name when "Edutor Admin" 
                                                  current_user.id
                              else
                                    current_user.institution_id
                              end
    @concept.user_id = current_user.id
    respond_to do |format|
      if @concept.save
        puts @concept.save
        format.json { render json: {status: 200,created: true, concept_id: @concept.id} }
      else
        format.json { render json: {status: 407,created: false, notice: 'Please check the details entered'} }
      end
    end

  end

  def new_concept_map
    
    @concept_id = params[:id]
    if(ConceptElement.where(:concept_id => @concept_id).count > 0)
      redirect_to :action => "show_concept_map", :id => @concept_id
      return
    end
    render :layout => false
  end

  def data
    #Used to get all elements of concept map
    concept_id = params[:concept_id].to_i
    allElements = ConceptElement.where(:concept_id => concept_id)
    data = allElements.to_json
    render json: data ;
  end

  def save_element
    #get the concept_map id
    #concept_id = params[:concept]
    #get the json object of the element
     id = params[:id].to_i
     element = ConceptElement.find(id) ;
     puts "Parent is"
     puts params[:parent]
     element.name = params[:name];
     element.description = params[:text];
     if(params[:parent].to_i == -1)
      parent = nil
    else
      parent = params[:parent].to_i
    end
    element.parent_id = parent;
    element.concept_id = params[:concept_id].to_i;
    element.x = params[:x].to_f;
    element.y = params[:y].to_f;
    element.save;
    puts "Element is: "
    puts element;
    #render json: {success: true} ;
  end

  def add_new_element
    element = ConceptElement.new
    element.x=params[:x].to_f
    element.y=params[:y].to_f
    element.save
    render json: {id: element.id}
  end
  def delete_elements
    # concept_element = ConceptElement.find(params[:id].to_i)
    # concept_element.destroy
    ids = params[:ids]
    ids.map! {|id| id = id.to_i}
    ConceptElement.where(:id => ids).destroy_all

    render json: {destroyed: true}
  end

  def show_concept_map
    
    #Get concept_map id
    @concept_id = params[:id].to_i
    @concept = Concept.find(@concept_id)
    authorize! :show_concept_map, @concept
    render :layout => false
  end
end
