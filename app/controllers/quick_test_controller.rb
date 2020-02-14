class QuickTestController < ApplicationController
  include QuicktestHelper
  def new
    @quiz= Quiz.new
  end

  def edit
    @quiz= Quiz.find(params[:id])
  end

  def get_user_group_rank
    publish_id = params[:quick_test][:publish_id]
    student_id = params[:quick_test][:user_id]
    real_hash = {:published=>get_no_of_students_published(publish_id),
                 :taken=>get_no_of_students_taken_test(publish_id),
                 :rank=>get_rank(student_id,publish_id)}
    respond_to do|format|
      format.json { render json: real_hash}
    end
  end


  def save
    @quiz= Quiz.find(params[:id])
    @quiz.modifiedby = current_user.id
    @quiz.timemodified = Time.now
    Quiz.skip_callback(:create,:before,:set_defaults)
    @quiz.attributes=params[:quiz]
    if @quiz.save(:validate=>false)
      if(params[:commit]=="publish")
        redirect_to quick_test_publish_page_path(@quiz)
      else
        redirect_to quick_test_manage_path
      end
      return
    end
    redirect_to quick_test_new_path
  end
  def create
    @quiz= Quiz.new(params[:quiz])
    @quiz.createdby = current_user.id
    @quiz.modifiedby = current_user.id
    @quiz.timecreated = Time.now
    @quiz.timemodified = Time.now
    Quiz.skip_callback(:create,:before,:set_defaults)
    if @quiz.save(:validate => false)
      if(params[:commit]=="publish")
        redirect_to quick_test_publish_page_path(@quiz)
      else
        redirect_to quick_test_manage_path
      end
      return
    end
    redirect_to quick_test_new_path
  end

  def publish_page
    @quiz=Quiz.find(params[:quiz])
  end

  def update_quick_test_info
    @quiz=Quiz.find(params[:quiz])
    respond_to  do |format|
      format.js
    end
  end

  def publish
    @quiz=Quiz.find(params[:quiz])
    @groups = []
    if (params[:user][:section_id]).blank?
      @groups << params[:user][:academic_class_id].split("|").first
      @build_info = params[:user][:academic_class_id].split("|").last
    else
      @groups << params[:user][:section_id].split("|").first
      @build_info = params[:user][:section_id].split("|").last
    end
    logger.info "================groups===#{@groups}"
    @publish  = QuizTargetedGroup.new(:quiz_id=>@quiz.id,:published_by=>current_user.id,:subject=>params[:publish][:subject],:body=>params[:publish][:message], :group_id => @groups.first, :assessment_type => 2)
    @publish.save(:validate=>false)
    @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.testpaper(:id=>@quiz.id.to_s,:version=>"2.0",:publish_id=>@publish.id.to_s){
        xml.test_password(:value=>"")
        xml.show_solutions_after(:value=>"0")
        xml.show_score_after(:value=>"0")
        xml.pause(:value=>'0')
        xml.shuffleoptions(:value=>"0")
        xml.shufflequestions(:value=>"0")
        xml.start_time(:value=>"#{43.years.ago.to_i}")
        xml.end_time(:value=>"#{30.days.from_now.to_i}")
        xml.guidelines(:value=>"")
        xml.requisites(:value=>"")
        xml.time(:value=>"-1")
        xml.level(:value=>"1")
        @quiz.questions.each do |q|
          quiz_questions(xml,q)
        end
      }
    end
      @ncx = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.navMap{
          xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
            xml.content(:src=>"curriculum")
            xml.navPoint(:id=>"Assessment",:class=>"assessment"){
              xml.content(:src=>"assessments")
              xml.navPoint(:id=>"QT",:class=>"course"){
                xml.content(:src=>"qt")
                xml.navPoint(:id=>"test",:class=>"academic-class"){
                  xml.content(:src=>"test")
                  xml.navPoint(:id=>"practice-tests",:class=>"assessment-category"){
                    xml.content(:src=>"practice")
                    xml.navPoint(:id=>"test",:class=>"subject"){
                      xml.content(:src=>"test")
                      xml.navPoint(:id=>@quiz.name ,:class=>"assessment-practice-tests"){
                        xml.content(:src=>"/assessment_#{@publish.id}.etx")
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end
      ncx_string =  @ncx.to_xml.to_s

      xml_string =  @builder.to_xml.to_s

      temp_path = Rails.root.to_s+"/public/quick_test/"+current_user.id.to_s+"/#{@quiz.id.to_s}/#{Time.now.to_i.to_s}/assessment_#{@publish.id}"
      FileUtils.mkdir_p temp_path
      File.open(temp_path+"/assessment_#{@publish.id}.etx",  "w+b", 0644) do |f|
        f.write(xml_string.to_s)
      end

      begin

        File.open(temp_path+"/index.ncx",  "w+b", 0644) do |f|
          f.write(ncx_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
        end
        images = []
        already_folders = []
        already_images = []
        Zip::ZipFile.open("#{temp_path}.zip", Zip::ZipFile::CREATE) {
            |zipfile|
          zipfile.add("assessment_#{@publish.id}.etx",temp_path+"/assessment_#{@publish.id}.etx")
          zipfile.add("index.ncx",temp_path+"/index.ncx")

          @quiz.questions.each do |q|
            q.question_images.each do |img|
              images << img.picture.url.split("?")[0].gsub("/system",'system')
            end
          end
          images = images - [""]
          images.each do |x|
            n = x.split('/').last
            x = x.gsub(n,'')
            if x != ""
              if !already_folders.include? x
                zipfile.mkdir(x)
                already_folders << x
              end
            end
          end
          images.each do |i|
            f = Rails.root.to_s+"/public/"+i
            if File.exist?(f)
              if !already_images.include? i
                zipfile.add(i,f)
                already_images << i
              end
            end
          end
        }
      end
    # @publish.build_quiz_ibook_location
    @ibooks = current_user.ignitor_books
    @groups.each do |g|
      if @build_info == "4.0"
          @message = Message.new
          @asset = @message.assets.build
          @asset.attachment = File.open("#{temp_path}.zip")
          @message.sender_id = current_user.id
          @message.group_id = g
          @message.subject = @publish.subject
          @message.body = @publish.body+"$:/Curriculum/Assessment/QT/test/practice-tests/test/#{@quiz.name}"
          @message.message_type = "Assessment"
          @message.severity = 1
          @message.label = @publish.subject
          @message.save
          QuizPublish.create(:message_id=>@message.id,:publish_id=>@publish.id,:user_id=>g,:quiz_id=>@quiz.id)
      elsif @build_info == "5.0"

        ContentDelivery.encrypt_assessment_message(current_user,@publish,"#{temp_path}.zip")
      end
    end
   redirect_to '/quick_test/manage'
  end

  def quiz_questions(xml,q)
    @question = Question.find(q)
    xml.question_set(:id=>@question.id.to_s){
      xml.course(:value=>'')
      xml.board(:value=>'')
      xml.class_(:value=>'')
      xml.subject(:value=>'')
      xml.chapter(:value=>'')
      xml.time(:value=>"1")
      xml.score(:value=>@question.defaultmark.to_s)
      xml.comment_{
        xml.cdata @question.generalfeedback
      }
      xml.negativescore(:value=>0)
      xml.prob_skill(:value=> '0')
      xml.data_skill(:value=>'0')
      xml.useofit_skill(:value=> '0')
      xml.creativity_skill(:value=> '0')
      xml.listening_skill(:value=> '0')
      xml.speaking_skill(:value=>'0')
      xml.grammar_skill(:value=>'0')
      xml.vocab_skill(:value=>'0')
      xml.formulae_skill(:value=>'0')
      xml.comprehension_skill(:value=>'0')
      xml.knowledge_skill(:value=>'0')
      xml.application_skill(:value=>'0')
      xml.difficulty(:value=>'1')
      if @question.qtype =="multichoice"
        xml.qtype(:value=>"MCQ")
      elsif @question.qtype =="truefalse"
        xml.qtype(:value=>"TOF")
      elsif @question.qtype == "fib"
        xml.qtype(:value=>"FIB")
      end
      xml.question{
        if @question.qtype =="multichoice" || @question.qtype =="truefalse"
          xml.question_text{
            image_text = ''
            @question.question_images.each do |i|
              image_text = image_text+"<img src='#{i.picture.url.split('?')[0].gsub("/system","system")}'>"
            end
            xml.cdata @question.questiontext+image_text
          }
          @options = QuestionAnswer.where("question=?",@question.id)
          i = 0
          options = ("a".."z").to_a
          @options.each do |o|
            tag =options[i]
            xml.option(:id=>o.id.to_s,:tag=>tag,:answer=>((o.fraction==1)? "true" : "false")){
              xml.option_text{
                xml.cdata o.answer
              }
              xml.feedback{
                xml.cdata o.feedback
              }
            }
            i = i+1
          end
        elsif @question.qtype == "fib"
          xml.question_text{
            image_text = ''
            @question.question_images.each do |i|
              image_text = image_text+"<img src='#{i.picture.url.split('?')[0].gsub("/system","system")}'>"
            end
            xml.cdata @question.questiontext+"#DASH#"+image_text
          }
          @options =  @question.question_fill_blanks

          @options.each do |o|
            xml.options_fib(:ignore_case=>o.case_sensitive ? 0 :1) {
              if o.case_sensitive
                o.answer.split(',').each do |i|
                  xml.option_blank{
                    xml.text i
                  }
                end
              else
                o.answer.split(',').each do |i|
                  xml.option_blank{
                    xml.text i.upcase
                  }
                end
                o.answer.split(',').each do |i|
                  xml.option_blank{
                    xml.text i.downcase
                  }
                end
              end
            }
          end
        end
      }
    }
  end

  def manage
    @quick_tests = Quiz.where(format_type:7,createdby:current_user.id).order("timemodified desc").page(params[:page]).per(4)
  end

end

private

=begin
def quiz_params
  params.require(:quiz).permit(:id, :name, questions_attributes: [ :id, :questiontext , :qtype, question_fill_blanks_attributes: [:id, :answer, :fraction]])

end
=end
