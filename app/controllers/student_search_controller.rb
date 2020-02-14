class StudentSearchController < ApplicationController
  # authorize_resource :class=>User
  def index

  end

  def list_students
    if  params[:section_id].present?
      puts "##################  Sections"
      @users = User.students.search_includes.where(institution_id: params[:institution_id],
                                                   center_id: params[:center_id],
                                                   academic_class_id: params[:academic_class_id],
                                                   section_id: params[:section_id]).page(params[:page])
    elsif params[:academic_class_id].present?
      puts "##############  Academic Class"
      @users = User.students.search_includes.where(institution_id: params[:institution_id],
                                                   center_id: params[:center_id],
                                                   academic_class_id: params[:academic_class_id]).page(params[:page])
    elsif params[:center_id].present?
      puts "########## Center"
      @users = User.students.search_includes.where(:institution_id=>params[:institution_id],
                                                   :center_id=>params[:center_id]).page(params[:page])

    elsif params[:institution_id].present?
      puts "#######  Institution"
      @users = User.students.search_includes.where(:institution_id=>params[:institution_id]).page(params[:page])
    end
  end
end
