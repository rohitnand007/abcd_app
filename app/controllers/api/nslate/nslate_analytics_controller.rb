class Api::Nslate::NslateAnalyticsController < Api::Nslate::BaseController

  def nslate_home
    if NgiQuizData.count != 0
      quiz_data = NgiQuizData.order('created_at DESC').all.collect{|p| {"date"=>p.quiz_date,"published_id"=>p.publish_id}}
      @final_quiz_data_page1 = {}
      @final_quiz_data_page2 = []
      present_user = @api_user
      quiz_data.each do |data|
        quiz_targeted_group_id = data["published_id"]
        date = data["date"]
        q_data = Quiz.ngi_home_page_data(present_user,quiz_targeted_group_id,date)
        @final_quiz_data_page2 << q_data if q_data[date].present?
        @final_quiz_data_page1[date] = {:published=>[],:downloaded=>[],:submitted=>[],:not_submitted=>[]} if q_data[date].present?
      end
      @final_quiz_data_page2.each do |p|
        p.first[1].each do |k|
          @final_quiz_data_page1[p.keys[0]][:published] << k.first[1][:published]
          @final_quiz_data_page1[p.keys[0]][:downloaded] << k.first[1][:downloaded]
          @final_quiz_data_page1[p.keys[0]][:submitted] << k.first[1][:submitted]
          @final_quiz_data_page1[p.keys[0]][:not_submitted] << k.first[1][:not_submitted]
        end
      end
    end

    render :json=> { :data=>@final_quiz_data_page1 }

  end
  def nslate_home_ia
    if NgiQuizData.count !=0
      quiz_data = NgiQuizData.order('created_at DESC').all.collect{|p| {"date"=>p.quiz_date,"published_id"=>p.publish_id}}
      @final_quiz_data_page1 = {}
      @final_quiz_data_page2 = []
      present_user = @api_user
      quiz_data.each do |data|
        quiz_targeted_group_id = data["published_id"]
        date = data["date"]
        @final_quiz_data_page2 << {date =>[]} unless @final_quiz_data_page2.find{|k| k[date]}.present?
        @final_quiz_data_page2.find{|k| k[date]}[date] << Quiz.ngi_institute_wise_data(present_user, quiz_targeted_group_id, date)
        @final_quiz_data_page2.find{|k| k[date]}[date] = @final_quiz_data_page2.find{|k| k[date]}[date].flat_map(&:entries).group_by(&:first).map{|k,v| Hash[k, v.map(&:last)]}
      end
    end
    render :json=>{:data=>@final_quiz_data_page2}
  end
  def download_institute_wise_data_full

    date = params["date"]
    assess_data = NgiQuizData.where(quiz_date: date).order('created_at DESC').collect{|p| {"date"=>p.quiz_date,"published_id"=>p.publish_id}}

    ultimate_hash = {:downloaded=>[],:submitted=>[],:not_submitted=>[]}
    assess_data.each do |data|
      get_qtg1 = QuizTargetedGroup.where(id: data["published_id"]).first
      group_id1 = get_qtg1.group_id
      student_ids1  = UserGroup.where("group_id=#{group_id1}").map(&:user_id)
      message1 = MessageQuizTargetedGroup.find_by_quiz_targeted_group_id(data["published_id"])
      if message1
        message_id1 = message1.message_id
        downloaded_students1 = UserMessage.where(message_id: message_id1, user_id: student_ids1,sync: false).map(&:user_id)
      end
      attempted1 = (get_qtg1.quiz_attempts.select(:user_id).group(:user_id).collect{|i|i.user_id} & student_ids1)
      not_submitted_1 =  downloaded_students1 - attempted1

      downloaded_students1.each do |id1|
        ultimate_hash[:downloaded] << [data["published_id"], id1, User.find(id1).name]
      end

      not_submitted_1.each do |id1|
        ultimate_hash[:not_submitted] << [data["published_id"], id1,User.find(id1).name]
      end
      attempted1.each do |id1|
        ultimate_hash[:submitted] << [data["published_id"], id1,User.find(id1).name]
      end
      end
    render :json=>{:data=>ultimate_hash}
  end
  def datewise_quiz
    @date = params[:date]
    @final_quiz_data_page2 = []
    quiz_data = NgiQuizData.order('created_at DESC').all.collect{|p| {"date"=>p.quiz_date,"published_id"=>p.publish_id}}
    present_user = @api_user
    quiz_data.select{|data| data["date"] == @date}.each do |refined_data|
      quiz_targeted_group_id = refined_data["published_id"]
      date = refined_data["date"]
      q_data = Quiz.ngi_home_page_data(present_user,quiz_targeted_group_id,date)
      @final_quiz_data_page2 << q_data
    end
    render :json=>{:data=>@final_quiz_data_page2}
  end
  def download_datewise_quiz_data_full
    date = params["date"]
    quiz_data = NgiQuizData.where(quiz_date: date).order('created_at DESC')
    @final_quiz_data_page1 = {}
    @final_quiz_data_page2 = []
    present_user = @api_user
    quiz_data.each do |data|
      quiz_targeted_group_id = data.publish_id
      date = data.quiz_date
      q_data = Quiz.ngi_home_page_csv_data(present_user,quiz_targeted_group_id,date)
      @final_quiz_data_page2 << q_data
    end
    render :json=>{:data=>@final_quiz_data_page2}
  end
  def download_datewise_quiz_data
    date = params["date"]
    quiz_data = NgiQuizData.where(quiz_date: date).order('created_at DESC')
    @final_quiz_data_page1 = {}
    @final_quiz_data_page2 = []
    present_user = @api_user
    quiz_data.each do |data|
      quiz_targeted_group_id = data.publish_id
      date = data.quiz_date
      q_data = Quiz.ngi_home_page_csv_data(present_user,quiz_targeted_group_id,date)
      @final_quiz_data_page2 << q_data
    end
    render :json=>{:data=>@final_quiz_data_page2}
  end

end