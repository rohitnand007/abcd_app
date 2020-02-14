class OnlineAssessmentsController < ApplicationController
  # authorize_resource :only =>:start_assessment
  def start_assessment
    @quiz = Quiz.find(params[:quiz], :select => [:id, :name, :intro, :timelimit])
    @publish = QuizTargetedGroup.find(params[:publish],:select => [:id,:quiz_id, :pause ])
    @quiz_targeted_group = QuizTargetedGroup.find(params[:publish])
    authorize! :start_assessment, @quiz_targeted_group
    respond_to do |format|
      format.html {render "assessment_new"}
    end
  end

  def get_data
    @quiz = Quiz.find(params[:quiz], :select => [:id, :name, :intro, :timelimit])
    @publish = QuizTargetedGroup.find(params[:publish],:select => [:id,:quiz_id,:shufflequestions,:shuffleoptions ])
    @alpha = ("A".."Z").to_a
    @result = {}
    @q_count = 0
    @q_count1 = 0
    @shuffle_questions = @publish.shufflequestions
    @shuffle_options = @publish.shuffleoptions
    inter = quiz_sections_obj(@quiz)
    section_count = @quiz.quiz_sections.count - @quiz.quiz_sections.where(:parent_id => nil).select { |q_s| q_s.quiz_question_instances.count== 0 }.count
    section_count = 1 if section_count==0
    @result = @result.merge(quiz: {id: @quiz.id,
                                   name: @quiz.name,
                                   intro: @quiz.intro,
                                   timelimit: @quiz.timelimit,
                                   q_count: @quiz.questions.count - (@quiz.questions.where(:qtype => "passage").count),
                                   qs_count: section_count,
                                   quiz_sections: inter[0]},
                            state: {publish: @publish,
                                    usr: current_user.id,
                                    submit: 0,
                                    timestart: 0,
                                    timefinish: 0,
                                    atmpt: 1,
                                    allowed: 1,
                                    quiz:{quiz_sections: inter[1]}})
    respond_to do |format|
      format.html {render text: @result.to_json}
    end
  end

  def quiz_js
    quiz = params[:quiz]
    begin
      ActiveRecord::Base.transaction do
        attempt_number = QuizAttempt.where(:publish_id => quiz["publish"]["id"], :quiz_id => quiz["publish"]["quiz_id"], :user_id => quiz["usr"]).count + 1
        qa = QuizAttempt.create(:publish_id => quiz["publish"]["id"],
                                :quiz_id => quiz["publish"]["quiz_id"],
                                :user_id => quiz["usr"],
                                :attempt => attempt_number,
                                :timestart => quiz["timestart"],
                                :timefinish => quiz["timefinish"])
        quiz["quiz"]["quiz_sections"].each do |qs|
          qs["questions"].each do |ques|
            if ["multichoice", "truefalse"].include? ques["qtype"]
              qqa = qa.quiz_question_attempts.create(:quiz_id => quiz["publish"]["quiz_id"],
                                                     :question_id => ques["id"],
                                                     :user_id => quiz["usr"],
                                                     :attempt_number => 0,
                                                     :time_taken => ques["time"]/ 1000)

              ques["options"].each do |opt|
                selected = opt["opt"]==true ? true : false
                if selected
                  mcq_qqa = qqa.mcq_question_attempts.build(:question_answer_id => opt["id"],
                                                          :selected => selected,
                                                          :marks => 0)
                  if(QuestionAnswer.find(opt["id"]).fraction.to_i==1 && mcq_qqa.selected)
                    mcq_qqa.correct = true
                    mcq_qqa.marks = ques["marks"]
                  elsif(QuestionAnswer.find(opt["id"]).fraction.to_i==0 && !mcq_qqa.selected)
                    mcq_qqa.correct = true
                    mcq_qqa.marks = ques["marks"]
                  else
                    mcq_qqa.correct = false
                    mcq_qqa.marks = 0
                  end
                  mcq_qqa.save
                end
              end
              correct = false
              marks = 0
              if !qqa.mcq_question_attempts.where(:selected => true).empty?
                correct_options = Question.find(ques["id"]).question_answers.where(fraction: 1.0).map(&:id)
                attempted_options = qqa.mcq_question_attempts.map(&:question_answer_id)
                if correct_options.sort != attempted_options.sort #qqa.mcq_question_attempts.map(&:correct).include? false
                  marks = -1 * ques["nmarks"].to_f
                  correct = false
                else
                  marks = ques["marks"].to_f
                  correct = true
                end
              end
              qqa.update_attributes(:qtype => ques["qtype"], :correct => correct, :marks => marks)

            end
            if ["fib"].include? ques["qtype"]
              qqa = qa.quiz_question_attempts.create(:quiz_id => quiz["publish"]["quiz_id"],
                                                     :question_id => ques["id"],
                                                     :user_id => quiz["usr"],
                                                     :attempt_number => 0,
                                                     :time_taken => ques["time"]/ 1000)
              i = 0
              ques["options"].each do |opt|
                selected = ques["options"][i].length>0 ? true : false;
                fib_qqa = qqa.fib_question_attempts.build(:selected => selected,
                                                          :correct => "NA",
                                                          :marks => 0,
                                                          :fib_question_answer => ques["options"][i].empty? ? 0 : ques["options"][i])
                possible_answers = Question.find(ques["id"]).question_fill_blanks[i].answer.squeeze(" ").strip.split(',')
                case_sensitive = Question.find(ques["id"]).question_fill_blanks[i].case_sensitive
                if case_sensitive
                  if possible_answers.include? ques["options"][i]
                    fib_qqa.marks = ques["marks"].to_f
                    fib_qqa.correct = true
                  else
                    fib_qqa.marks = -1 * ques["nmarks"].to_f
                    fib_qqa.correct = false
                  end
                else
                  possible_answers = possible_answers.map {|answer| answer.downcase}
                  if possible_answers.include? ques["options"][i].downcase
                    fib_qqa.marks = ques["marks"].to_f
                    fib_qqa.correct = true
                  else
                    fib_qqa.marks = -1 * ques["nmarks"].to_f
                    fib_qqa.correct = false
                  end
                end
                fib_qqa.save
                i = i + 1
              end
              correct = false
              marks = 0
              if !qqa.fib_question_attempts.where(:selected => true).empty?
                if qqa.fib_question_attempts.map(&:correct).include? false
                  marks = -1 * ques["nmarks"].to_f
                  correct = false
                else
                  marks = ques["marks"].to_f
                  correct = true
                end
              end
              qqa.update_attributes(:qtype => ques["qtype"], :correct => correct, :marks => marks)

            end
            if ["vsaq", "saq", "laq", "project"].include? ques["qtype"]
              qqa = qa.quiz_question_attempts.create(:quiz_id => quiz["publish"]["quiz_id"],
                                                     :question_id => ques["id"],
                                                     :user_id => quiz["usr"],
                                                     :attempt_number => 0,
                                                     :time_taken => ques["time"]/ 1000)
              ques["options"].first do |opt|
                fib_qqa = qqa.match_question_attempts.build(:selected => true,
                                                            :correct => "NA",
                                                            :marks => 0,
                                                            :fib_question_answer => ques["options"][0])
                fib_qqa.save
              end
              qqa.update_attributes(:qtype => ques["qtype"], :correct => false, :marks => 0)
            end
          end
        end
        qa.update_attribute(:sumgrades, qa.quiz_question_attempts.sum(:marks))
      end
    rescue Exception => e
      logger.info "Exception in posting data--- #{e.message} \n #{e.backtrace.pretty_inspect}"
    end

    respond_to do |format|
      format.html { render text: ({:save => "ok"}).to_json }
    end
  end

  private
  def quiz_sections_obj(quiz)
    result1 = []
    state = []
    @quiz = quiz
    count = 1
    @quiz.quiz_sections.map do |q_s|
      if (!q_s.parent_id.nil?) 
        #sub section
        f_s = q_s
        p_s =  QuizSection.find(f_s.parent_id)
        s_name = p_s.name + ' : ' + f_s.name
        s_intro = p_s.name + " :<br>" + p_s.intro + "<br>" + f_s.name + " :<br>" + f_s.intro
        inter1 = quiz_sec_questions(f_s)
        result1 << {id: f_s.id, name: s_name,
                    intro: s_intro,
                    section_type: "sub_section",
                    section_name: p_s.name,
                    section_instructions: p_s.intro,
                    sub_section_name: f_s.name,
                    sub_section_instructions: f_s.intro,
                    q_count: f_s.questions.count - (f_s.questions.where(:qtype => "passage").count),
                    questions: inter1[0]}
        state << {scr: getScroller(inter1[2]),
                  atmpt: 0,
                  questions: inter1[1]}
        count = count+1
      elsif q_s.quiz_question_instances.count > 0
        #section
        f_s = q_s
        p_s =  ""
        s_name =  f_s.name
        s_intro = f_s.name + " :<br>" + f_s.intro
        inter1 = quiz_sec_questions(f_s)
        result1 << {id: f_s.id, name: s_name,
                    intro: s_intro,
                    section_type: "section",
                    section_name: f_s.name,
                    section_instructions: f_s.intro,
                    q_count: f_s.questions.count - (f_s.questions.where(:qtype => "passage").count),
                    questions: inter1[0]}
        state << {scr: getScroller(inter1[2]),
                  atmpt: 0,
                  questions: inter1[1]}
        count = count+1
      end
    end
    if @quiz.quiz_sections.empty?
      #quiz without section
      inter1 = quiz_sec_questions(@quiz)
      result1 << {id: -1,
                  name: @quiz.name,
                  section_type: "none",
                  q_count: @quiz.questions.count - (@quiz.questions.where(:qtype => "passage").count),
                  questions: inter1[0]}
      state << {scr: getScroller(inter1[2]),
                atmpt: 0,
                questions: inter1[1]}
    end
    return [result1, state]
  end

  def quiz_sec_questions(sec)
    result2 = []
    state1 = []
    arr = []
    @i = 0
    questions_ins = sec.quiz_question_instances.map do |qi|
      if qi.question.qtype != "passage"
        qi
      end
    end.compact
    questions_ins = shuffle_question_instances(sec)
    questions_ins.each do |q|
      src = []
      inter2 = q_sec_question_options(q.question)
      #!passage_questions(q.question).nil? ? passage_questions(q.question) : [0, 0]
      #passage_question_id: Id of parent question
      #question_id: Id of child question
      if PassageQuestion.where(:question_id => q.question.id).empty?
        # question is not a child question of any passage question
        @q_count= @q_count + 1
        inter3 = [0, 0]
        result2 << {id: q.question.id,
                    qtext: q.question.questiontext_format,
                    qtype: q.question.qtype,
                    qmulti: q.question.multiple_answer?,
                    qNo: @q_count,
                    qQIns: {id: q.id,
                            grade: q.grade,
                            penalty: q.penalty,
                            question_id: q.question_id},
                    opt_count: q.question.question_answers.count,
                    options: inter2[0],
                    questions: inter3[0]}
        state1 << {id: q.question.id,
                   marks: q.grade,
                   nmarks: q.penalty,
                   qtype: q.question.qtype,
                   answer: 0,
                   atmpt: 0,
                   time: 0,
                   order: 0,
                   options: inter2[1],
                   scr: [], #scr,
                   questions: inter3[1]}

      elsif arr.include? PassageQuestion.where(:question_id => q.question.id).first.passage_question_id
        result2 << {id: q.question.id,
                    qtext: q.question.questiontext_format,
                    qtype: q.question.qtype,
                    qmulti: q.question.multiple_answer?,
                    qNo: @q_count.to_s + @alpha[@i],
                    qQIns: {id: q.id,
                            grade: q.grade,
                            penalty: q.penalty,
                            question_id: q.question_id},
                    opt_count: q.question.question_answers.count,
                    options: inter2[0],
                    questions: passage_question(q.question)}
        state1 << {id: q.question.id,
                   marks: q.grade,
                   nmarks: q.penalty,
                   qtype: q.question.qtype,
                   answer: 0,
                   atmpt: 0,
                   time: 0,
                   order: 0,
                   options: inter2[1],
                   scr: []} #scr,
        #questions: inter3[1]}
        @i = @i + 1
      elsif !arr.include? PassageQuestion.where(:question_id => q.question.id).first.passage_question_id
        # this question is a child question of passage question and this passage is not added yet.
        @q_count= @q_count + 1
        arr << PassageQuestion.where(:question_id => q.question.id).first.passage_question_id
        @i = 0
        result2 << {id: q.question.id,
                    qtext: q.question.questiontext_format,
                    qtype: q.question.qtype,
                    qmulti: q.question.multiple_answer?,
                    qNo: @q_count.to_s + @alpha[@i],
                    qQIns: {id: q.id,
                            grade: q.grade,
                            penalty: q.penalty,
                            question_id: q.question_id},
                    opt_count: q.question.question_answers.count,
                    options: inter2[0],
                    questions: passage_question(q.question)}
        state1 << {id: q.question.id,
                   marks: q.grade,
                   nmarks: q.penalty,
                   qtype: q.question.qtype,
                   answer: 0,
                   atmpt: 0,
                   time: 0,
                   order: 0,
                   options: inter2[1],
                   scr: []} #scr,
        #questions: inter3[1]}
        @i = @i + 1
      end
    end

    return [result2, state1, questions_ins]
  end

  def q_sec_question_options(q)
    count = 1
    result3 = []
    state2 = []
    options = q.question_answers
    descriptive_qtypes = ["vsaq", "saq", "laq", "project", "fib"]
    options.shuffle! if @shuffle_options
    options.each do |option|
      result3 << {id: option.id,
                  answer: option.answer_format}
      state2 << {
          id: option.id,
          opt: "",
          qtype: q.qtype}
      count = count + 1
    end
    if descriptive_qtypes.include? q.qtype
      result3 << ""
      state2 << ""
    end
    return [result3, state2]
  end

  def getScroller(questions_ins)
    scr = []
    arr = []
    i = 0
    index = 0
    questions_ins.each do |q|
      if PassageQuestion.where(:question_id => q.question.id).empty?
        @q_count1= @q_count1 + 1
        scr << {bl: q.question.id,
                fl: [0, 0, 0],
                vl: @q_count1}
      elsif arr.include? PassageQuestion.where(:question_id => q.question.id).first.passage_question_id
        scr << {bl: q.question.id,
                fl: [0, 0, 0],
                vl: @q_count1.to_s + @alpha[i]}
        i = i + 1
      elsif !arr.include? PassageQuestion.where(:question_id => q.question.id).first.passage_question_id
        @q_count1= @q_count1 + 1
        arr << PassageQuestion.where(:question_id => q.question.id).first.passage_question_id
        i = 0
        scr << {bl: q.question.id,
                fl: [0, 0, 0],
                vl: @q_count1.to_s + @alpha[i]}
        i = i + 1
      end
      scr[-1][:question_index] = index
      index += 1
    end
    return scr
  end

  def passage_question(q)
    pq = q.passage_question
    return {id: pq.id,
            qtext: pq.questiontext_format,
            qtype: pq.qtype,
            qNo: @q_count.to_s + @alpha[@i],
            qQIns: {id: 0,
                    grade: 0,
                    penalty: 0,
                    question_id: 0},
            opt_count: 0}
  end

  def shuffle_question_instances(sec)
    #returs with question instances shuffled
    #passage_parent_questions are removed
    actual_question_instances = [] #removed passage child questions but not passage parent question
    passage_question_ids = []
    passage_parent_question_instances = []
    all_child_passage_question_instances = []
    all_child_passage_question_instance_ids = []
    shuffled_question_instances = []
    sec.quiz_question_instances.each do |q|
      if q.question.qtype=='passage'
        actual_question_instances << q
        passage_question_ids << q.question.id
      elsif(PassageQuestion.where(:question_id => q.question_id).empty?)
        actual_question_instances << q
      else
        all_child_passage_question_instance_ids << q.question_id
        all_child_passage_question_instances << q
      end
    end
    actual_question_instances.shuffle! if @shuffle_questions
    actual_question_instances.each do |q|
      if q.question.qtype=='passage'
        child_passage_question_ids = PassageQuestion.where(:passage_question_id => q.question_id, :question_id => all_child_passage_question_instance_ids).map(&:question_id)
        child_passage_questions = all_child_passage_question_instances.select do |c_q|
          child_passage_question_ids.include? c_q.question_id
        end
        child_passage_questions.each {|c_q| shuffled_question_instances << c_q}
      else
        shuffled_question_instances << q
      end
    end
    shuffled_question_instances
  end
end
