class ContentDelivery < ActiveRecord::Base
  attr_accessible :uri, :message_id, :ibook_id, :user_id
  belongs_to :user
  belongs_to :user_asset
  belongs_to :ibook
  belongs_to :message
  validates_presence_of :published_as
  validates_presence_of :ibook_id
  validates_presence_of :user_id
  #validates_presence_of :user_asset_id
  after_commit :publish, :on => :create

  def publish
    asset_types = {"pdf"=>"text-book","text"=>"text-book","video"=>"video-lecture","audio"=>"audio","weblink"=>"weblink","image"=>"image-gallery",
                   "animation" => "animation", "text-book" => "text-book", "Assessment" => "assessment-practice-tests","assessment-practice-tests"=>"assessment-practice-tests",
                   "concept-map" => "concept-map", "Audio" => "audio", "video-lecture" => "video-lecture", "Web Link"=> "weblink", "mp3"=>"audio", "mp4"=>"video-lecture", "html5"=>"activity"}

    @user_asset = UserAsset.find(self.user_asset_id)
    @ibook = Ibook.find(self.ibook_id)
    @new_book = @ibook.toc_items.present?

    if self.published_as == "weblink"
      path = "#{Rails.root.to_s}/public/system/content_deliveries/attachments/" + self.id.to_s+"_tmp"
      zip_location = File.join(path,"bookpart_" + File.basename(path))+'.zip'
      FileUtils.mkdir_p path
    else
      path = @user_asset.attachment.path.split("/")
      path.pop
      path = path.join("/") + "_extract_enc"
      FileUtils.mkdir_p path
      zip_location = File.join(path,"bookpart_" + File.basename(path))+'.zip'

    end
    book_json = []
    book_json << {
        "book_id" => @ibook.ibook_id,
        "uri" => self.uri,
        "src" => @user_asset.asset_type=="weblink" ? @user_asset.weblink_url : "/" + (@user_asset.launch_file.nil? ? "" : @user_asset.launch_file),
        "class_type" => asset_types[@user_asset.asset_type],
        "parameters" => "",
        "name"  => "#{self.display_name}",
        "is_content" => "#{self.is_content}",
        "is_assessment" => "#{self.is_assessment}",
        "is_homework" => "#{self.is_homework}",
        "show_in_live_page" => "true",
        "show_in_toc" => "#{self.show_in_toc}",
        "glossary_meaning"=>"",
        "guid" => @new_book ? @user_asset.guid : "",
        "parent_guid"=>@new_book ? "#{self.parent_guid}" : "",
        "file_type"=>@user_asset.file_type
    }

    ActiveRecord::Base.transaction do
      File.open("#{path}/info.json","w") do |f|
        f.write(book_json.to_json)
      end
      path.sub!(%r[/$],'')
      puts path

      FileUtils.rm zip_location, :force=>true

      Zip::ZipFile.open(zip_location, 'w') do |zipfile|
        Dir["#{path}/**/**"].reject{|f|f==zip_location}.each do |file|
          zipfile.add(file.sub(path+'/',''),file)
        end
      end
        @message = Message.new
        @asset = @message.assets.build
        @asset.attachment = File.open("#{zip_location}")
        @message.sender_id = self.user_id
        if self.group_id
          @message.group_id =  self.group_id
          @recipients = []
        else
          @message.recipient_id = self.recipients.split(",").first
          @recipients = self.recipients.split(",")
        end
        @message.subject = message_subject #"Published content-#{self.uri.split("/").last}"
        @message.body = "Published to-#{@ibook.get_title}" + "$:" + @ibook.ibook_id + self.uri
        @message.message_type = "Content"
        @message.severity = 1
        @message.label = "Encrypted Material"
        @message.save
        @recipients.shift
        @recipients.each do |recipient|
          UserMessage.create(:user_id=>recipient,:message_id=>@message.id)
        end
      end
      self.update_attributes(message_id: @message.id)

    end
   handle_asynchronously :publish #, :priority => 2

  def self.encrypt_assessment_message(user,quiz_targeted_group,zip_location)

    argsA = zip_location.split("/")
    argsA.pop
    if quiz_targeted_group.quiz_ibook_location.blank?
      info = QuizIbookLocation.new
      info.quiz_targeted_group_id = quiz_targeted_group.id
      info.ibook_id = "00000000-0000-0000-0000-000000000000"
      info.uri = "/assessment_#{quiz_targeted_group.id}"
      info.save
      @ibook_id = "00000000-0000-0000-0000-000000000000"
    else
      info = quiz_targeted_group.quiz_ibook_location
      @ibook_id = Ibook.find(info.ibook_id).ibook_id
      @ibook = Ibook.find(info.ibook_id)
      @new_book = @ibook.toc_items.present?
    end
    argsA = argsA.join("/") + "_extract_enc"
    path = argsA
    book_json =[]
    ActiveRecord::Base.transaction do
      extract(zip_location)
      encrypt_files(zip_location)
      quiz = info.quiz_targeted_group.quiz
      book_json << {
          "book_id" => @ibook_id,
          "uri" => info.uri,
          "src" => "/#{quiz.name}_#{quiz_targeted_group.id}.etx",
          "class_type" => "assessment-#{quiz_targeted_group.get_assessment_ncx}",
          "parameters" => "",
          "name"  =>  quiz.name,
          "is_content" => "true",
          "is_assessment" => "true",
          "is_homework" => "false",
          "show_in_live_page" => "true",
          "show_in_toc" => "true",
          "glossary_meaning"=>"",
          "passwd" => quiz_targeted_group.password,
          "guid" => @new_book ? quiz_targeted_group.guid : "",
          "parent_guid"=>@new_book ? "#{info.guid}" : "",
          "file_type"=>"assessment"
      }
      File.open("#{argsA}/info.json","w") do |f|
        f.write(book_json.to_json)
      end
      path.sub!(%r[/$],'')
      puts path
      archive = File.join(path,"bookpart_" + File.basename(path))+'.zip'
      FileUtils.rm archive, :force=>true

      Zip::ZipFile.open(archive, 'w') do |zipfile|
        Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
          zipfile.add(file.sub(path+'/',''),file)
        end
      end
      @message = Message.new
      @asset = @message.assets.build
      @asset.attachment = File.open("#{archive}")
      @message.sender_id = user.id
      if quiz_targeted_group.group_id.present?
        @message.group_id = quiz_targeted_group.group_id
      else
        @message.recipient_id = quiz_targeted_group.recipient_id
      end
      @message.subject = "Assessment - #{quiz_targeted_group.quiz.name}"
      @message.body = @ibook_id == "00000000-0000-0000-0000-000000000000" ? "Published to Mock Tests" + "$:" +@ibook_id +info.uri : "Published to-#{Ibook.find_by_ibook_id(@ibook_id).get_title}" + "$:" +@ibook_id +info.uri
      @message.message_type = "Assessment"
      @message.severity = 1
      @message.label = "Encrypted Material"
      @message.save
      MessageQuizTargetedGroup.create(:message_id=>@message.id,:quiz_targeted_group_id=>quiz_targeted_group.id)
      @quiz = quiz_targeted_group.quiz
      QuizPublish.create(:message_id=>@message.id,:publish_id=>quiz_targeted_group.id,:user_id=>quiz_targeted_group.group_id,:quiz_id=>@quiz.id) if @quiz.format_type == 7
    end
  end

  def self.encrypt_files(location)
    argsA = location.split("/")
    argsA.pop
    argsA = argsA.join("/") + "_extract"
    argsB = argsA + "_enc"
    Dir.chdir("public/jars/") do
      # Use your path to the java according to the java directory installed in your machine.
      retResult  = system("java -jar encryptDataV1.jar #{argsA} #{argsB}")
    end
  end

  def self.extract(location)
    argsA = location.split("/")
    argsA.pop
    Zip::ZipFile.open(location) { |zip_file|
      zip_file.each { |f|
        f_path=File.join("#{argsA.join("/")}"+"_extract", f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }
    #FileUtils.remove_file self.attachment.path
  end

  def published_to_inbox_or_toc
    if self.ibook_id == 0
      "inbox"
    else
      "toc"
    end
  end

  def message_subject
    #Your teacher [Teacher name] - [ID also] published [weblink/video/text/pdf file/image] to [bookname] -> [Unit Name] -> [Chapter Name] -> [Section name] -> [Sub Section Name]
    @name = "#{user.name}-#{user.edutorid}"
    @role = user.type.downcase
    @book_name = @ibook.get_title
    @uri = self.uri.gsub("/"," -> ")
    @asset_type = @user_asset.asset_type
    "Your #{@role}#{@name} published #{@asset_type} to #{@book_name} #{@uri}"
  end

end
