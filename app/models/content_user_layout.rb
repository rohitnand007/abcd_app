class ContentUserLayout < ActiveRecord::Base
  serialize :content_layout, Hash
  belongs_to :content
  belongs_to :teacher

  def self.content_reterive
    main_hash = ContentUserLayout.last.content_layout
    @contents = Content.includes(:topics).where(:id=>main_hash.keys.map{|key|main_hash[key]['id']})
    main_hash.keys.each_with_index do |key,index|
      puts "chapter",  index, main_hash[key],main_hash[key]["is_locked"],main_hash[key]["id"],@contents.where(:id=>main_hash[key]["id"]).first.name
      if main_hash[key].has_key?"data"
        main_hash[key]["data"].keys.each do |k|
          puts "topic for #{main_hash[key]['id']}",  main_hash[key]['data'][k]["is_locked"],main_hash[key]['data'][k]["id"],@contents.where(:id=>(main_hash[key]["id"])).first.topics.where(:id=>main_hash[key]['data'][k]["id"]).first.name
        end
      end
    end
  end

  def self.get_unlocked_chapters(subject,user)
    content = ContentUserLayout.where("(user_id =? OR user_id IN (?)) AND content_id =? ",user.id,user.center.center_admins.map(&:id),subject.id)
    if !content.empty?
      main_hash = content.last.content_layout
      chapter_ids = main_hash.keys.collect{|key| main_hash[key]['id'] if main_hash[key]['is_locked'] == "1"}
      chapter_ids = chapter_ids - [nil]
    end
  end

  def self.get_unlocked_topics(chapter,user)
    content = ContentUserLayout.where("(user_id =? OR user_id IN (?)) AND content_id =? ",user.id,user.center.center_admins.map(&:id),chapter.subject.id)
    if !content.empty?
      main_hash = content.last.content_layout
      topic_ids = []
      main_hash.keys.each_with_index do |key,index|
        if main_hash[key]["id"] == chapter.id.to_s
          if main_hash[key].has_key?"data"
            main_hash[key]["data"].keys.each do |k|
              if  main_hash[key]['data'][k]["is_locked"] == "1"
                topic_ids << main_hash[key]['data'][k]["id"]
              end
            end
            break
          end
        end
      end

      topic_ids = topic_ids - [nil]
    end
  end


end
