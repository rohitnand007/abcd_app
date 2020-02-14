class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    # The permissions for the Student
    if user.nil?
      can :manage,:all
      cannot :read, LoggedException
    elsif user.is? :ES
      cannot :manage,:all
      cannot :read, LoggedException
      cannot :manage, Tag
      cannot :manage, MetaTag
      #can [:users, :sent, :show,:acknowledgements,], Message,:sender_id=>user.id  # The message related permissions for the student
      can [:show], Message, :message_type=>'Report'
      can [:users,:acknowledgements,:get_user_messages,:user_messages_status,:assessment_conceptmap_messages], Message,:sender_id=>user.id
      can [:show, :edit, :update], Profile, :user_id => user.id # The profile related permissions for the student
      can [:start_assessment,:student_attempted_assessments,
           :student_not_attempted_assessments,:show_student_attempts,
           :download_catchall,:show_student_question_attempts,
           :pause_assessment_state,:save_assessment_state,:restart_assessment,
           :resume_assessment,:ask_to_resume_assessment,:submit_normal_assessment,
           :pause_normal_assessment_state,:save_normal_assessment_state,:online_show_question,
           :submit_assessment,:submit_catchall_questions, :submit_method,:online_next_question,:online_previous_question,:get_quiz_message, :quiz_js] ,Quiz
      can [:create,:user_usage,:user_activity], Usage
      can [:update,:user_get_quote,:user_get_tip,:user_ack_tip,:get_firewall_list,:get_workspace_apps,:post_user_config,:user_details,:user_device_info,:get_signup_status], User
      can [:user_ibooks, :get_ibook], Ibook
      can [:start_assessment], QuizTargetedGroup do |q|
        q.accessible(user.id)
      end
      can [:get_user_status], User
      can :manage, :UserDeviceInfo
      # The permissions for the Teacher
    elsif user.is? :ET
      cannot :manage,:all
      cannot :read, LoggedException
      cannot :manage, Tag
      cannot :manage, MetaTag
      can [:users,:acknowledgements,:get_user_messages,:user_messages_status,:assessment_conceptmap_messages], Message,:sender_id=>user.id
      can :manage, UserAsset
      can :manage, ContentDelivery, :user_id => user.id
      can [:show, :edit, :update], Profile, :user_id => user.id # The profile related permissions for the teacher
      can :manage, [Content,Subject,Chapter,Topic,SubTopic,Assessment,AssessmentHomeWork,Quiz,Question,QuestionAnswer,QuestionMatchSub,QuestionParajumble,QuizAttempt,QuizQuestionAttempt,QuizQuestionInstance,QuizTargetedGroup]
      can :manage, [Teacher,Student],:center_id=>user.center_id
      can [:show], Student, :section_id=>user.section_id
      cannot [:new,:create],[Teacher, Student,Center,Section,InstituteAdmin,Institution,CenterAdmin]
      cannot :manage, [Board,ContentYear]
      cannot :manage, [AcademicClass]
      cannot :edit, [Student]
      can [:new, :users, :sent, :show,:create,:profile_users], Message,:sender_id=>user.id
      can :manage, Concept, :user_id => user.id
      can [:create,:user_usage,:user_activity], Usage
      can [:update,:user_get_quote,:user_get_tip,:user_ack_tip,:get_firewall_list,:get_workspace_apps,:post_user_config,:user_details,:user_device_info,:get_signup_status], User
      can [:user_ibooks, :get_ibook], Ibook
      can [:start_assessment], QuizTargetedGroup do |q|
        q.accessible(user.id)
      end
      can [:get_user_status], User
      can :manage, :UserDeviceInfo
      can [:index,:show], Section,:center_id=>user.center_id
      cannot [:edit,:new], Section
      can [:index,:show], User,:center_id=>user.center_id
      cannot [:edit,:new], User
      can :manage, StudentGroup
      can [:get_academic_classes,:get_sections], Institution
      #can :manage, ZipUpload
      # The permissions for the Center Representative
    elsif user.is? :CR
      cannot :manage,:all
      cannot :read, LoggedException
      cannot :manage, Tag
      cannot :manage, MetaTag
      can :manage, [AcademicClass, Section], :center_id => user.center_id # The permissions for managing the Center
      can :manage, [CenterAdmin, Teacher, Student, Device], :center_id =>user.center_id # The permissions for managing the center users
      can :manage, [Content,ContentYear,Subject,Chapter,Topic,SubTopic,Assessment,AssessmentHomeWork,Quiz,Question,QuestionAnswer,QuestionMatchSub,QuestionParajumble,QuizAttempt,QuizQuestionAttempt,QuizQuestionInstance,QuizTargetedGroup]
      can :read, [Usage]
      cannot :manage, [Institution, InstituteAdmin]
      can [:get_academic_classes,:get_sections], Institution
      cannot [:new,:edit,:update],Board
      cannot [:new,:create],Center
      can [:download_csv], Usage
      can [:show, :edit, :update], Profile, :user_id => user.id
      can [:new, :users, :sent, :show,:create,:profile_users], Message,:sender_id=>user.id
      can :manage, BookPublisher
      can :manage, Book
      can :manage, Collection
      can :manage, Concept
      can :manage, DeviceProperty
      can :manage, DeviceRequest
      can :manage, DeviceResponse
      can :manage, IpAddress
      can :manage, IpTableOverride
      can :manage, IpTable
      can :manage, MessageAcknowledg
      can :manage, Powerchip
      can :manage, Quote
      can :manage, TestConfiguration
      can :manage, TestResult
      can :manage, TinymceAsset
      can :manage, Tip
      can :manage, UsbChip
      can :manage, UserBookCollection
      can :manage, UserBook
      can :manage, UserDeviceConfiguration
      can :manage, WebLink
      can :manage, WorkSpaceApp
      can :manage, ZipUpload
      can [:assign, :fetch_students, :show, :index, :clean_list], LicenseSet, :institution_id => user.institution_id
      can [:assign, :fetch_students, :index, :show], LicenseSet, :institution_id => user.institution_id
      # The permissions for the Institute Admin
    elsif user.is? :IA or user.is? :MOE or user.is? :EO
      cannot :manage,:all
      can :manage, UserAsset #for managing user_asssets
      can :manage, ContentDelivery, :user_id => user.id #for managing asset publish
      can :manage, StudentGroup
      cannot :read, LoggedException
      can :manage, Tag
      cannot [:new, :create], Tag
      cannot :manage, MetaTag
      can :manage, [User]
      can :manage, [AcademicClass, Section, StudentGroup, Student, Teacher], :institution_id => user.institution_id # The permissions for managing the Center
      can :manage, [Center,CenterAdmin,InstituteAdmin, EducationOfficer ,Teacher, Student, Device], :institution_id =>user.institution_id # The permissions for managing the center users
      can :manage, [Content,ContentYear,Subject,Chapter,Topic,SubTopic,Assessment,AssessmentHomeWork,Quiz,Question,QuestionAnswer,QuestionMatchSub,QuestionParajumble,QuizAttempt,QuizQuestionAttempt,QuizQuestionInstance,QuizTargetedGroup]
      can :read, [Usage]
      cannot :manage, [Institution]
      cannot [:new,:edit,:update],Board
      #cannot [:new,:create],Center
      can [:get_academic_classes,:get_sections], Institution
      can [:get_centers],Institution
      can [:download_csv], Usage
      can [:show, :edit, :update], Profile, :user_id => user.id
      can [:new, :users, :sent, :show,:create,:profile_users], Message,:sender_id=>user.id
      can :manage, BookPublisher
      can :manage, Book
      can :manage, Collection
      can :manage, Concept, :institution_id => user.institution_id
      can :manage, DeviceProperty
      can :manage, DeviceRequest
      can :manage, DeviceResponse
      can :manage, IpAddress
      can :manage, IpTableOverride
      can :manage, IpTable
      can :manage, MessageAcknowledg
      can :manage, Powerchip
      can :manage, Quote
      can :manage, TestConfiguration
      can :manage, TestResult
      can :manage, TinymceAsset
      can :manage, Tip
      can :manage, UsbChip
      can :manage, UserBookCollection
      can :manage, UserBook
      can :manage, UserDeviceConfiguration
      can :manage, WebLink
      can :manage, WorkSpaceApp
      can :manage, ZipUpload
      can [:assign, :fetch_students, :show, :index, :clean_list], LicenseSet, :institution_id => user.institution_id
      can :show, Ipack
      # The permissions for the Edutor Content Publisher
    elsif user.is? :ECP
      cannot :manage,:all
      cannot :read, LoggedException
      can :manage, Tag
      cannot [:new, :create], Tag
      cannot :manage, MetaTag
      can [:get_tags_lpc, :my_tags, :my_class_subject_tags], MetaTag
      can :manage, Ibook, :publisher_id => user.id
      can :get_csv_book_list, Ibook, :publisher_id => user.id
      can :book_extended_details, Ibook
      can :manage, Ipack, :publisher_id => user.id
      can [:dashboard, :schools], Publisher
      can :manage, [Question, Board, ContentYear, Subject, Chapter, Topic, SubTopic] # The permissions for managing the Content
      can [:show, :edit, :update], Profile, :user_id => user.id # The profile related permissions for the Content Publishers
      can :manage, LicenseSet, :publisher_id => user.id
      can :manage, ZipUpload
      can :manage, UserAsset
      can [:new, :create, :show, :slice_qb, :add_questions_to_qb, :list], PublisherQuestionBank,:publisher_id => user.id
      # The permissions for the Edutor Admin
    elsif user.is? :EA
      can :manage, :all  # The super admin can manage anything
      can :read, LoggedException
    elsif user.is? :CDN
      can :manage, CdnCacheStatus
      can :manage, CdnMetadata
      can :manage, CdnCenter
      can :manage, CdnLog
      can :manage, CdnUser
      can :manage, CdnPing
      can :manage, Profile
    end
  end
end
