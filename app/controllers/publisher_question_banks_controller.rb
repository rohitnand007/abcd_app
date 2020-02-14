class PublisherQuestionBanksController < ApplicationController
  load_and_authorize_resource
  def index
    # Lists all the question banks and enables assigning question banks to institutions/ users
    @publisher_question_banks = PublisherQuestionBank.all
    @institutions = Institution.all
  end
  def list
    @publisher_question_banks = PublisherQuestionBank.where(publisher_id: current_user.id)
  end

  def new
    # Create new Publisher Question Bank for the user. Not yet planned.
    @publisher_question_bank = PublisherQuestionBank.new
  end

  def create
    @publisher_question_bank = PublisherQuestionBank.new(params[:publisher_question_bank])
   if @publisher_question_bank.save
     redirect_to @publisher_question_bank, notice: "Question Bank Created Successfully."
   else
     render new_publisher_question_bank_path, notice: "Error While Creating."
   end
  end

  def edit
    # Assigns tags and questions to question bank
    @publisher_question_bank = PublisherQuestionBank.find(params[:id])
    @all_tags = Tag.where(:name=>["blooms_taxonomy","difficulty_level","specialCategory","qsubtype"])
  end

  def update
    @publisher_question_bank = PublisherQuestionBank.find(params[:id])
    respond_to do |format|
      if @publisher_question_bank.update_attributes(params[:publisher_question_bank])
        format.html { redirect_to @publisher_question_bank, notice: 'Question bank successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @publisher_question_bank.errors, status: "Something went wrong !!" }
      end
    end
  end

  def add_questions_to_qb
    #@publisher_question_bank = PublisherQuestionBank.find(params[:id])
    q_ids=[]
    redis_qids = []
    @new_db = PublisherQuestionBank.find(params[:qb_id])
    parent_qb_id = params[:id].to_i
    ac_tag_ids = params[:tag_ids]
    all_tag_ids = []
    # @tag_ids = params[:tag_ids].split(",")
    str = ""
    if params[:sub_tag_ids].present?
      tags_keys = []
          params[:sub_tag_ids].each{|k| all_tag_ids << k.split(' ')}
            all_tag_ids.each do |p|
              p.each{|tg_id| tags_keys << "qb:#{params[:id]}:tg:#{tg_id}:qus"}
                redis_qids = $redis.sinter("qb:#{params[:id]}:qus", tags_keys)
              tags_keys = []
        q_ids << redis_qids
      end
    q_ids = q_ids.flatten.uniq
    str = str + "#{q_ids.count}"
    else
      params[:tag_ids].each do |tag|
        redis_qids = $redis.sinter("qb:#{params[:id]}:tg:#{tag}:qus")
        q_ids << redis_qids
        str = str + "Class: #{Tag.find(tag).value} has #{redis_qids.count} questions. "
      end
    end
    #@new_db.questions << Question.where(id: final_question_ids)

    @new_db.populate_sliced_qb(parent_qb_id, ac_tag_ids, all_tag_ids)

    redirect_to publisher_question_bank_path(@new_db.id), notice: str + " Questions added to question bank successfully. New tags are being populated(Duplicate Questions if present, wont be added)"
  end

  def slice_qb
    @publisher_question_bank = PublisherQuestionBank.find(params[:id])
    @all_question_banks = PublisherQuestionBank.where("publisher_id=? and id !=?",current_user.id, params[:id])
    #@all_question_banks.delete(@publisher_question_bank)
    
    r = RedisInteract::Reading.new
    @class_tags = Tag.where(id: r.get_live_tags(@publisher_question_bank.id)[:ac_tg_ids])
    ac_tag_ids = @class_tags.collect{|p|p.id}
    @class_subject_tags = []
    ac_tag_ids.each do |p|
      @class_subject_tags << {:class=>Tag.find(p),:subject=>Tag.where(id: r.get_live_tags(@publisher_question_bank.id,:ac_tg_id=>p)[:su_tg_ids])}
    end

    end


  def show
    # List all the tag references of the question bank and probably questions (not planned)
    @publisher_question_bank = PublisherQuestionBank.find(params[:id])
  end

  def destroy
    # Not planned
  end

  def map_institution_to
    institution_id = params[:institution_id]
    publisher_question_bank_id = params[:publisher_question_bank_id]
    publisher_question_bank = PublisherQuestionBank.find(publisher_question_bank_id)
    institution = Institution.find(institution_id)
    begin
      publisher_question_bank.users << institution
      redirect_to publisher_question_banks_url, flash:{success:"Successfully assigned Question bank to user."}
    rescue
      redirect_to publisher_question_banks_url, flash:{error:"The question bank has already been assigned to user"}
    end

  end

  def unmap_institution_from
    institution_id = params[:institution_id]
    publisher_question_bank_id = params[:publisher_question_bank_id]
    question_bank_assigned_to_user = QuestionBankUser.where(user_id:institution_id,publisher_question_bank_id:publisher_question_bank_id).first
    question_bank_assigned_to_user.destroy unless question_bank_assigned_to_user.nil?
    redirect_to publisher_question_banks_url, flash:{success:"Successfully unassigned Question bank to user."}
  end

end