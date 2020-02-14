class Api::Panacea::GateForumController < Api::Panacea::BaseController
  require 'net/http'
  respond_to :json

  # API method for creating the users for GateForum
  # Paramteres provide Request JSON
  # {"name":"Lakshmi valli","rollno":"23510125","pwd":"laks0103","city":"Hyderabad","stream":"CS","key":"gateforumapikey"}
  def create_gate_forum_user
    unless params["data"].present?
      render status:500,:json => { :message => "Invalid data #{params["json"]}"}
      return
    else
      begin
        ActiveRecord::Base.transaction do
          @data = JSON.load(params["data"])
          @institution_id = current_user.institution_id
          @user  = User.find_by_institution_id_and_rollno(@institution_id,'GF-'+@data["rollno"])
          if @user.nil?
            @user = User.new
            @user_profile = @user.build_profile
            @user.rollno = "GF-"+@data["rollno"]
            @user.institution_id = @institution_id
            @user.center_id = get_center_id
            @user.academic_class_id = get_academic_class_id
            @user.section_id = get_section_id
            @user.extras = @data["city"]
            @user.email = @data["email"].present? ? @data["email"] : @data["rollno"].to_s+"@myedutor.com"
            @user.password = @data["pwd"]
            @user.role_id = 4
            @user_profile.firstname = @data["name"]
            unless @user.save
              result =  Net::HTTP.get(URI.parse("http://gis16.gateforum.com/updategtabdetails.php?rollno=#{@data["rollno"]}&status=F"))
              render :status => 200,
                     :json => {:success => false}
              return
            else
              result = Net::HTTP.get(URI.parse("http://gis16.gateforum.com/updategtabdetails.php?rollno=#{@data["rollno"]}&status=T"))
              render :status => 200,
                     :json => {:success => true}
              return
            end
          else
            result = Net::HTTP.get(URI.parse("http://gis16.gateforum.com/updategtabdetails.php?rollno=#{@data["rollno"]}&status=T"))
            render :status => 200,
                   :json => {:success => true}
          end
        end
      rescue
        result =  Net::HTTP.get(URI.parse("http://gis16.gateforum.com/updategtabdetails.php?rollno=#{@data["rollno"]}&status=F"))
        render :status => 200,
               :json => {:success => false}
        return
      end
    end

  end
=begin
 def get_center_id
    @center = Center.includes(:profile).where("institution_id=? and profiles.firstname=?",@institution_id,@data["city"])
    if @center.empty?
     center = Center.new
     center.build_profile
     center.institution_id = @institution_id
     center.email = @data['city']+"@gateforum.com"
     center.password = "edutor"
     center.profile.firstname = @data['city']
     center.save
     return center.id
    else
     @center.first.id
    end    

  end

  def get_academic_class_id
     @academic = AcademicClass.includes(:profile).where("institution_id=? and center_id=? and profiles.firstname=?",@institution_id,@user.center_id,@data["stream"])
    if @academic.empty?
      academic = AcademicClass.new
      academic.build_profile
      academic.institution_id=@institution_id
      academic.center_id= @user.center_id
      academic.email = @data['city']+@data['stream']+"@gateforum.com"
      academic.password  = "edutor"
      academic.profile.firstname = @data['city']+"_"+@data['stream']
      academic.save
      return academic.id
    else
      @academic.first.id
    end    
  end  
=end
  def get_center_id
    @email = @data['stream']+"_"+current_user.id.to_s+"@"+current_user.email.split("@").last
    @center = Center.includes(:profile).where("institution_id=? and profiles.firstname=? and email=?",current_user.institution_id,@data['stream'],@email)
    if @center.empty?
      center = Center.new
      center.build_profile
      center.institution_id = @institution_id
      center.email = @email
      center.password = "edutor"
      center.profile.firstname = @data['stream']
      center.save
      return center.id
    else
      @center.first.id
    end

  end

  def get_academic_class_id
    @name = @data['city']+"_"+@data['stream']
    @email = @data["city"]+"_"+@data["stream"]+"_"+current_user.id.to_s+"@"+current_user.email.split("@").last
    @academic = AcademicClass.includes(:profile).where("institution_id=? and center_id=? and profiles.firstname=? and email=?",current_user.institution_id,@user.center_id,@name,@email)
    if @academic.empty?
      academic = AcademicClass.new
      academic.build_profile
      academic.institution_id= @institution_id
      academic.center_id= @user.center_id
      academic.email = @email
      academic.password  = "edutor"
      academic.profile.firstname = @name
      academic.save
      return academic.id
    else
      @academic.first.id
    end
  end

  def get_section_id
    @name = @data['city']+"_"+@data['stream']+"default_section"
    @email = @data['city']+"_"+@data['stream']+"_"+current_user.id.to_s+"_"+@user.academic_class_id.to_s+"@"+current_user.email.split("@").last
    @section = Section.where("academic_class_id=?",@user.academic_class_id)
    if @section.empty?
      section = Section.new
      section.build_profile
      section.institution_id= current_user.institution_id
      section.center_id= @user.center_id
      section.academic_class_id= @user.academic_class_id
      section.email = @email
      section.password  = "edutor"
      section.profile.firstname = @name
      section.save
      return section.id
    else
      @section.first.id
    end
  end

end
