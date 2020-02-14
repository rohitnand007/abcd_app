class PublisherQuestionBank < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :institution, foreign_key: :publisher_id
  has_and_belongs_to_many  :questions, :uniq => true
  has_and_belongs_to_many  :tags
  has_many :question_bank_users
  has_many :users, through: :question_bank_users

  validates :question_bank_name, :uniqueness => { :case_sensitive => false }

  after_create :create_an_entry_in_redis_server


  def create_an_entry_in_redis_server
    # this begin rescue is called in case a server
    begin
      require 'redis_interact'
      p = RedisInteract::Plumbing.new
      p.add_qb_to_redis_db(self.id)
    rescue Exception => e
      Rails.logger.debug ".......#{e}........"
      raise e
    end
  end

  def parent_class
    User.find(self.publisher_id).class.to_s
  end

  def populate_qb(q_ids)
    self.questions << Question.where(id: q_ids)
    #populate redis
    require 'redis_interact'
    p = RedisInteract::Plumbing.new
    q_ids.each do |q_id|
      p.update_redis_server_after_question_creation(self.id, q_id)
    end
  end
  handle_asynchronously :populate_qb, queue: "reports"

  def populate_sliced_qb(parent_qb_id, ac_tg_ids, ac_su_tag_ids)
    q_ids=[]
    redis_qids = []
    if ac_su_tag_ids.present?
      tags_keys = []
      ac_su_tag_ids.each do |p|
        p.each{|tg_id| tags_keys << "qb:#{parent_qb_id}:tg:#{tg_id}:qus"}
        redis_qids = $redis.sinter("qb:#{parent_qb_id}:qus", tags_keys)
        tags_keys = []
        q_ids << redis_qids
      end
      q_ids = q_ids.flatten.uniq
    else
      ac_tg_ids.each do |tag|
        redis_qids = $redis.sinter("qb:#{parent_qb_id}:tg:#{tag}:qus")
        q_ids << redis_qids
      end
      q_ids = q_ids.flatten.uniq
    end
    self.question_ids = (self.question_ids + q_ids).uniq
    p = RedisInteract::Spawning.new
    p.spawn_sliced_question_bank_base_data(self.id)
  end
  handle_asynchronously :populate_sliced_qb, queue:"reports"
end

