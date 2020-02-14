class StatsController < ApplicationController
  EDUTOR = 1
  def index
    if current_user.id == EDUTOR
      @filter_center = 0
    else
      @filter_center = current_user.center_id
    end
    if params[:filter_center].present?
      @filter_center = params[:filter_center]
    end
    @centers = get_centers
    @filter_type = "messages"
    @filter_start_date = ""
    @filter_end_date = ""
    @filter_group_by = "date"
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def filter
    if current_user.id == EDUTOR
      @filter_center = 0
    else
      @filter_center = current_user.center_id
    end
    if params[:filter_center].present?
      @filter_center = params[:filter_center]
    end
    @centers = get_centers
    @filter_type = "messages"
    @filter_start_date = ""
    @filter_end_date = ""
    @filter_group_by = "date"
    @filter_teacher_type = ""
    if params[:filter_type].present?
      @filter_type = params[:filter_type]
    end
    if params[:filter_start_date].present?
      @filter_start_date = params[:filter_start_date]
    end
    if params[:filter_end_date].present?
      @filter_end_date = params[:filter_end_date]
    end
    if params[:filter_teacher_type].present?
      @filter_teacher_type = params[:filter_teacher_type]
    end
    name =""
    if params[:filter_group_by].present?
      @filter_group_by = params[:filter_group_by]
      name = @filter_group_by
      if @filter_group_by =="month"
        name = "MONTHNAME"
      end
    end

    center_where = " WHERE u.center_id = #{params[:filter_center]} "
    if @filter_center.to_i == 0
      center_where = ""
    end

    

    if @filter_type == "messages"
      @stats = Message.find_by_sql("SELECT #{name}(FROM_UNIXTIME(m.created_at)) as time,count(DISTINCT(m.id)) as num_messages, count(DISTINCT(ug.user_id)) as num_recipients FROM messages m INNER JOIN users u on u.id=m.group_id INNER JOIN user_groups ug on ug.group_id=u.id #{center_where} group by #{@filter_group_by}(FROM_UNIXTIME(m.created_at)) order by #{@filter_group_by}(FROM_UNIXTIME(m.created_at)) DESC limit 100")
      respond_to do |format|
        format.html { render "messages_stats"}
      end
      return
    elsif @filter_type == "published_assessments"
      @stats = QuizTargetedGroup.find_by_sql("SELECT #{name}(FROM_UNIXTIME(p.published_on)) as time,count(DISTINCT(p.quiz_id)) as num_published, count(DISTINCT(ug.user_id)) as num_recipients FROM quiz_targeted_groups p INNER JOIN users u on u.id=p.group_id INNER JOIN user_groups ug on ug.group_id=p.group_id #{center_where} group by #{@filter_group_by}(FROM_UNIXTIME(p.published_on)) order by #{@filter_group_by}(FROM_UNIXTIME(p.published_on)) DESC limit 100")
      respond_to do |format|
        format.html { render "published_assessments_stats"}
      end
      return
    elsif @filter_type == "taken_assessments"
      @stats = QuizAttempt.find_by_sql("SELECT #{name}(FROM_UNIXTIME(qa.timefinish)) as time,count(DISTINCT(u.id)) as num_students FROM quiz_attempts qa INNER JOIN users u on u.id=qa.user_id #{center_where} group by #{@filter_group_by}(FROM_UNIXTIME(qa.timefinish)) order by #{@filter_group_by}(FROM_UNIXTIME(qa.timefinish)) DESC limit 100")
      respond_to do |format|
        format.html { render "taken_assessments_stats"}
      end
      return
    elsif @filter_type == "teacher_activity"
      @stats = ""
      if @filter_teacher_type == "all_messages"
        @stats = Message.find_by_sql("SELECT count(DISTINCT(m.id)) as num_messages, CONCAT(p.firstname,' ',p.surname) as name FROM messages m INNER JOIN users u on u.id=m.sender_id INNER JOIN profiles p on p.user_id=u.id #{center_where} group by m.sender_id")
      elsif @filter_teacher_type == "published_assessments"
        @stats = Message.find_by_sql("SELECT count(DISTINCT(qt.id)) as num_messages, CONCAT(p.firstname,' ',p.surname) as name FROM quiz_targeted_groups qt INNER JOIN users u on u.id=qt.published_by INNER JOIN profiles p on p.user_id=u.id #{center_where} group by qt.published_by")
      end
      respond_to do |format|
        format.html { render "teacher_activity_stats"}
      end
      return
    end
  end

  def get_centers
    if current_user.id == 1
      d = {}
      d[1] = "Edutor"
      Center.all.each do |i|
        d[i.id] = i.profile.firstname
      end
      return d
    end
    d = {}
    Institution.where(:id=>current_user.institution_id).first.centers.each do |i|
      d[i.id] = i.profile.firstname
    end
    return d
  end
end
