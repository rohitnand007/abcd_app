module QuicktestHelper

  def total_question_no(quicktest)
    Quiz.find(quicktest).questions.count
  end

  def  summary_message(quicktest)
    if published?(quicktest)
      "Your quicktest is successfully published. View responses"
    else
      "Your quicktest is successfully saved. Please publish it."
    end
  end

  def return_top_n_scoring(quicktest,n)
    students=[]
    attempt_ids = get_first_attempts(quicktest)
    student_attempts=QuizAttempt.where(:id=>attempt_ids).order("sumgrades DESC").limit(n)
    #student_attempts=QuizAttempt.where(:quiz_id=>quicktest.id).order("sumgrades DESC").limit(n)
    student_attempts.each{|student_attempt|
      students << User.find(student_attempt.user_id)
    }
    students
  end

  def highest_score(quicktest)
    attempt_ids = get_first_attempts(quicktest)
    attempt = QuizAttempt.where(:id=>attempt_ids).order("sumgrades DESC").limit(1).first
    #attempt = QuizAttempt.where(:quiz_id=>quicktest.id).order("sumgrades DESC").limit(1).first
    if attempt
      attempt.sumgrades
    else
      0
    end
  end

  def lowest_score(quicktest)
    attempt_ids = get_first_attempts(quicktest)
    attempt = QuizAttempt.where(:id=>attempt_ids).order("sumgrades ASC").limit(1).first
    #attempt = QuizAttempt.where(:quiz_id=>quicktest.id).order("sumgrades ASC").limit(1).first
    if attempt
      attempt.sumgrades
    else
      0
    end
  end

  # calculating average score for given test
  def quiz_average_score(quicktest)
    attempt_ids = get_first_attempts(quicktest)
    attempt =  QuizAttempt.where(:id=>attempt_ids).average(:sumgrades)
    #attempt =  QuizAttempt.where(:quiz_id=>quicktest.id).average(:sumgrades)
  end

  def highest_score_student_number(quicktest)
    score = highest_score(quicktest)
    attempt_ids = get_first_attempts(quicktest)
    QuizAttempt.where(:id=>attempt_ids,sumgrades:score).map(&:user_id).count
    #QuizAttempt.where(:quiz_id=>quicktest.id,sumgrades:score).map(&:user_id).count
  end

  def lowest_score_student_number(quicktest)
    score = lowest_score(quicktest)
    attempt_ids = get_first_attempts(quicktest)
    QuizAttempt.where(:id=>attempt_ids,sumgrades:score).map(&:user_id).count
    #QuizAttempt.where(:quiz_id=>quicktest.id,sumgrades:score).map(&:user_id).count
  end

  def quicktest_published_user_count(quicktest)
    students_published(quicktest).count
  end

  def quicktest_downloaded_user_count(quicktest)
    students_downloaded(quicktest).count
  end

  def quicktest_taken_user_count(quicktest)
    tests_taken=0
    if published?(quicktest)
      QuizAttempt.where(:quiz_id=>quicktest.id).group(:user_id).each{|student_attempt|
        tests_taken+=1 if  students_published(quicktest).include?(User.find(student_attempt.user_id))
      }
    end
    tests_taken
  end

  def students_first_attempt_set(quicktest)
    #each entry corresponds to a unique student
    QuizAttempt.where(:quiz_id=>quicktest).group(:user_id)
  end

  def question_id_set(quicktest,limit)
    Quiz.find(quicktest).questions.map(&:id).first(limit)
  end

  def student_attempt_wise_each_question_correctness(attempt_set,question_set)
    student_question_wise_correctness= []
    attempt_set.each{|attempt|
      student = User.find(attempt.user_id).name
      question_attempts= {}
      question_set.each{|question_id|
        question_correct = false
        question_attempt = QuizQuestionAttempt.where(:quiz_attempt_id=>attempt.id,:question_id=>question_id)
        if question_attempt
          question_correct = true if question_attempt.first.correct
        end
        question_attempts = question_attempts.merge({question_id=>question_correct})
      }
      student_question_wise_correctness << [student,question_attempts,attempt.sumgrades]
    }
    student_question_wise_correctness
  end


  def average_question_correctness(attempt_set,question_set)
    question_average_correctness= {}
    question_set.each{|question_id|
      question_corrects =0
      attempt_set.each{|attempt|
        question_attempt = QuizQuestionAttempt.where(:quiz_attempt_id=>attempt.id,:question_id=>question_id)
        if question_attempt
          question_corrects +=1 if question_attempt.first.correct
        end
      }
      question_average_correctness = question_average_correctness.merge({question_id=>question_corrects})
    }
    question_average_correctness
  end

  def first_attempt_average_correctness_per_10_questions(quicktest)
    average_question_correctness(students_first_attempt_set(quicktest),question_id_set(quicktest,10))
  end
  def first_attempt_correctness_per_10_questions_per_each_student(quicktest)
    student_attempt_wise_each_question_correctness(students_first_attempt_set(quicktest),question_id_set(quicktest,10))
  end

  def published?(quicktest)
    if quicktest.format_type == 7
      quicktest.quiz_publishes.empty? ? false : true
    else
      quicktest.quiz_targeted_groups.empty? ? false : true
    end
  end
  def totalmarks(quicktest)
    quicktest.quiz_question_instances.sum(:grade)
  end

  def student_quiz_first_attempts(quicktest)
    all_attempts = []
    #this finds only attempts
    students_first_attempt_set(quicktest).each do |student_attempt|
      attempt_attributes={}
      #finding the group
      group = quicktest.format_type==7 ? User.find(QuizPublish.where(publish_id:student_attempt.publish_id).first.user_id).name : User.find(QuizTargetedGroup.where(id:student_attempt.publish_id).first.group_id).name
      attempt_attributes[:class_group]= group
      #finding student name
      attempt_attributes[:student_name]= User.find(student_attempt.user_id).name
      # finding downloaded status
      attempt_attributes[:downloaded] = "Y"
      attempt_attributes[:attempted] = "Y"
      attempt_attributes[:marks] = student_attempt.sumgrades
      all_attempts << attempt_attributes
    end
    all_attempts
  end

  def student_quiz_attempts(quicktest)
    all_attempts = []
    #this  finds all attempts
    QuizAttempt.where(:quiz_id=>quicktest.id).each do |student_attempt|
      attempt_attributes={}
      #finding the group
      group = quicktest.format_type==7 ? User.find(QuizPublish.where(publish_id:student_attempt.publish_id).first.user_id).name : User.find(QuizTargetedGroup.where(id:student_attempt.publish_id).first.group_id).name
      attempt_attributes[:class_group]= group
      #finding student name
      attempt_attributes[:student_name]= User.find(student_attempt.user_id).name
      # finding downloaded status
      attempt_attributes[:downloaded] = "Y"
      attempt_attributes[:attempted] = "Y"
      attempt_attributes[:marks] = student_attempt.sumgrades
      all_attempts << attempt_attributes
    end
    all_attempts
  end
  def students_not_downloaded(quicktest)
    not_downloaded = []
    students= students_published(quicktest)-students_downloaded(quicktest)
    students.each{|student|
      student_details={}
      student_details[:class_group]=student_user_group(quicktest,student.id)
      student_details[:student_name]= User.find(student.id).name
      student_details[:downloaded] = "N"
      student_details[:attempted] = "N"
      student_details[:marks] = "NA"
      not_downloaded << student_details

    }
    not_downloaded
  end

  def students_downloaded_but_not_attempted(quicktest)
    #this is an error

    downloaded_but_not_attempted = []
    students= students_downloaded(quicktest)
    students.each{|student|
      if QuizAttempt.where(:quiz_id=>quicktest.id,user_id:student.id).empty?
        student_details={}
        student_details[:class_group]= student_user_group(quicktest,student.id)
        student_details[:student_name]= User.find(student.id).name
        student_details[:downloaded] = "Y"
        student_details[:attempted] = "N"
        student_details[:marks] = "NA"
        downloaded_but_not_attempted << student_details
      end
    }
    downloaded_but_not_attempted
  end

  def student_wise_quicktest_status(quicktest)
    student_quiz_first_attempts(quicktest) + students_not_downloaded(quicktest) + students_downloaded_but_not_attempted(quicktest)
  end

  def student_user_group(quicktest,student_id)
    group=""
    if quicktest.format_type==7
      quicktest.quiz_publishes.each{|quiz_publish|
        publish_group = User.find(quiz_publish.user_id)
        if publish_group.is_group? and !(UserGroup.where(:group_id=>publish_group.id, :user_id=>student_id).empty?)
          group = publish_group.name
        end
      }
    else
      quicktest.quiz_targeted_groups.each{|quiz_publish|
        unless quiz_publish.group_id.nil?
          publish_group = User.find(quiz_publish.group_id)
          if !UserGroup.where(:group_id=>publish_group.id, :user_id=>student_id).empty?
            group = publish_group.name
          end
        end
      }
    end
    group
  end

  def student_taken_status(quicktest,student_id)
    QuizAttempt.where(:quiz_id=>quicktest.id,:user_id=>student_id).any?
  end
  def student_download_status(quicktest,student_id)
    unless published?(quicktest)
      return false
    else
      status=false
      if student_taken_status(quicktest,student_id)
        return true
      end
      quicktest_messageid_list(quicktest).each{|message_id|
        user_message= UserMessage.where(message_id: message_id, user_id: student_id)
        if !user_message.empty?
          status= !user_message.first.sync
          return status if status
        end
      }
      status
    end
  end

  def student_message_download_status(message_id,student_id)
    user_message= UserMessage.where(message_id: message_id, user_id: student_id)
    if !user_message.empty?
      !user_message.first.sync
    else
      false
    end
  end

  def quicktest_messageid_list(quicktest)
    if quicktest.format_type==7
      #QuizPublish.group(&:message_id).having(quiz_id:quicktest.id).map(&:message_id)
      QuizPublish.where(:quiz_id=>quicktest.id).map(&:message_id).uniq
    else
      message_list=[]
      QuizTargetedGroup.where(quiz_id:quicktest.id).each{|target_entry|
        message_list << MessageQuizTargetedGroup.find_by_quiz_targeted_group_id(target_entry.id).message_id
      }
      message_list
    end
  end


  def quick_test_unique_messages(quicktest)
    quicktest.quiz_publishes
  end

  def groups_published(quicktest)
    groups_published=""
    if (quicktest.quiz_publishes.empty? and quicktest.quiz_targeted_groups.empty?)
      groups_published << "None"
    else
      if quicktest.format_type==7
        quicktest.quiz_publishes.each{ |quiz_publish_entry|
          quickest_taker_id=quiz_publish_entry.user_id
          quicktest_taker =  User.find(quickest_taker_id)
          groups_published << quicktest_taker.name+" "

        }
      else
        quicktest.quiz_targeted_groups.each{ |quiz_publish_entry|
          unless quiz_publish_entry.group_id.nil?
            quicktest_taker =  User.find(quiz_publish_entry.group_id)
            groups_published << quicktest_taker.name+" "
          else
            groups_published << User.find(quiz_publish_entry.recipient_id).name+" "
          end
        }
      end
      return groups_published
    end
  end

  def students_published(quicktest)
    students=[]
    if quicktest.format_type==7
      quicktest.quiz_publishes.each{ |quiz_publish_entry|
        quicktest_taker_id = quiz_publish_entry.user_id
        quicktest_taker =  User.find(quicktest_taker_id)
        if quicktest_taker.is_group?
          students += quicktest_taker.students
        else
          students << quicktest_taker
        end
      }
    else
      quicktest.quiz_targeted_groups.each{ |quiz_publish_entry|
        if quiz_publish_entry.group_id
          quicktest_taker_id=quiz_publish_entry.group_id
          quicktest_taker =  User.find(quicktest_taker_id)
          students += quicktest_taker.students
        else
          students << User.find(quiz_publish_entry.recipient_id)
        end
      }
    end

    students
  end

  # returns all the students who downloaded the test . Removes duplicates by uniq method.
  def students_downloaded(quicktest)
    students_downloaded = []
    students_published(quicktest).uniq.each{ |student|
      quicktest_messageid_list(quicktest).each{|message_id|
        students_downloaded << student if ((student_message_download_status(message_id,student.id)) or (student_download_status(quicktest,student.id)))
      }
    }
    students_downloaded.uniq
  end

# The below methods apply for both quicktests and regular tests but they depend on the methods qriten for quicktest

# assumes that the test is published to a group
  def get_rank(student_id,publish_id)
    rank = 0
    #excluding the test for user esists and user is a student
    first_attempts = QuizAttempt.where(:publish_id=>publish_id).group(:user_id).order("sumgrades DESC")
    user_first_attempt = QuizAttempt.where(:publish_id=>publish_id,:user_id=>student_id).first
    rank = 1+first_attempts.index{|x| x.user_id == user_first_attempt.user_id} if user_first_attempt && first_attempts
    rank
  end

  def get_no_of_students_published(publish_id)
    student_number = 0
    quiz = Quiz.find(QuizTargetedGroup.find(publish_id).quiz_id)
    return student_number unless quiz
    student_number = quicktest_published_user_count(quiz)
    student_number
  end

  def get_no_of_students_taken_test(publish_id)
    student_number = 0
    quiz_attempts = QuizAttempt.where(:publish_id=>publish_id) #this filters out illegal test takers
    if quiz_attempts
      student_number = quiz_attempts.group(:user_id).map(&:user_id).size
    end
    student_number
  end


  def get_first_attempts(quiz_id)
    attempt_ids = QuizAttempt.where(:quiz_id=>quiz_id.id).group(:user_id).map(&:id)
  end  

end



