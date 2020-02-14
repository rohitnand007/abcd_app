include ActionView::Helpers::AssetTagHelper
class Ibook < ActiveRecord::Base
  serialize :metadata
  has_and_belongs_to_many :ipacks
  has_and_belongs_to_many :courses
  has_many :license_sets, through: :ipacks
  has_many :content_deliveries
  has_many :user_assets
  has_many :quiz_ibook_locations
  #has_many :ipacks, :dependent => :destroy
  has_many :toc_items,:dependent => :destroy


  # ibooks with version = 2 must have toc extracted on portal and GUIDs should be available in each column of TocItems
  has_attached_file :info_file,
                    :url => "ibook_assets/:id/info_files/:basename" + ".:extension",
                    :path => ":rails_root/:url"
  has_attached_file :encrypted_content,
                    :url => "ibook_assets/:id/encrypted_content/:basename" + ".:extension",
                    :path => ":rails_root/:url"
  validates_attachment_content_type :info_file, :content_type => ["application/zip", "application/x-zip", "application/x-zip-compressed", "application/octet-stream"]
  validates_attachment_content_type :encrypted_content, :content_type => ["application/zip", "application/x-zip", "application/x-zip-compressed", "application/octet-stream"]


  validates_attachment_presence :info_file, :on => :create
  validates_attachment_presence :encrypted_content, :on => :update
  #  validates_attachment_size :encrypted_content, :less_than => 200.megabytes

  validate :presence_of_key_files, :on => :create
  validate :uniqueness_of_ibook_id, :on => :create

  after_commit :house_keep, :on => :create

  scope :desc, order("ibooks.updated_at DESC")

  def house_keep
    self.persist_book_id
    logger.info "method----persist_bookid"
    self.dump_toc
    logger.info "method-----dump_toc"
    self.dump_cover
    logger.info "method-----dump_cover"
    self.save_toc
    logger.info "method------save_toc"
    self.update_version
    logger.info "method----update_version"
    self.save_metadata
    logger.info "method==-----save_metadata"
  end

  def update_info    
    replace_content_db
    # Destroy existing TOC columns associated with the book
    toc_items.destroy_all
    # Populate TOC columns with new info file & Update serialized JSON
    save_toc
    #update CdnContentInfo after book update to facilitate for this book transfer to cdn ops server
    logger.info "method==-------------------------------------------start update CDN UPLOAD STATUS"
    update_cdn_book_upload_status
    logger.info "method==-------------------------------------------ended update CDN UPLOAD STATUS"

  end

  def update_cdn_book_upload_status
    @cdn_book_info = CdnContentInfo.where(guid: self.ibook_id).first
    unless @cdn_book_info.nil?
      #file_md5 = Digest::MD5.hexdigest(File.read(self.encrypted_content.path)) rescue ""
      @cdn_book_info.update_attribute(:upload_status,false)
    end
  end

  def replace_content_db
    # Delete the EdutorContent DB
    path = get_attachment_parent_dir+"EdutorContent.db"
    File.delete(path) if File.exist?(path)
    dump_content_db
  end

  def presence_of_key_files
    file_names = []
    return if self.info_file.queued_for_write[:original].nil?  
    Rails.logger.debug("--Started--")

    Zip::ZipFile.open(self.info_file.queued_for_write[:original].path) do |zip_file|
    Rails.logger.debug("--Started1--")

      zip_file.each { |entry| file_names << entry.name }
    Rails.logger.debug("--Started2--")

    end
    if file_names.exclude?("enc_keys.key")
      errors.add(:super_key, " is not present")
    end
    if file_names.exclude?("EdutorContent.db")
      errors.add(:content_db, " is not present")
    end
    if file_names.exclude?("bookpackage.json")
      errors.add(:book_metadata, " is absent.(JSON file)")
    end
  end

  def uniqueness_of_ibook_id
    return if self.info_file.queued_for_write[:original].nil?
    ibook_id = JSON.parse(Zip::ZipFile.open(self.info_file.queued_for_write[:original].path).read("bookpackage.json"))["bookId"]
    Rails.logger.debug("--------edutor debug--------#{JSON.parse(Zip::ZipFile.open(self.info_file.queued_for_write[:original].path).read("bookpackage.json"))["bookId"]}------------------------")
    if Ibook.where({ibook_id: ibook_id}).present?
      # if some books exist with same ibook_id, then don't allow to save but throw errors
      errors.add(:book_id, " already exists")
      return false
    end
  end

  def schools_published
    self.license_sets.map { |ls| ls.school.name unless ls.school.nil? }.compact
  end

  def total_licenses_issued
    self.license_sets.reduce(0) { |sum, ls| sum+(ls.licences||=0) }
  end

  def total_licenses_utilized
    self.license_sets.inject(0) { |total, license_set| total+license_set.utilized }
  end

  def license_consumed_percentage
    self.total_licenses_issued==0 ? 0 : (self.total_licenses_utilized * 100/self.total_licenses_issued)
  end

  def part_of_collections
    self.ipacks.map(&:name).compact
  end

  def get_metadata
    if self.info_file.exists?
      begin
        JSON.parse(Zip::ZipFile.open(self.info_file.path).read("bookpackage.json"))
      rescue Exception => e
        {error: true, message: "Info package is corrupted, please do upload a new one.",}
      end
    else
      {}
    end
  end

  def get_title
    self.get_metadata["displayName"]
  end
  def get_book_class
    self.get_metadata["academicClass"].to_s
  end

  def get_title_and_class
    self.get_metadata["displayName"].to_s + " - " + self.get_metadata["academicClass"].to_s + " Class"
  end

  def get_key
    if self.info_file.exists?
      Zip::ZipFile.open(self.info_file.path).read("enc_keys.key")
    else
      ""
    end
  end

  def book_info_for_user
    {"book_id" => self.get_metadata["bookId"], "status" => "0"}
  end

  def book_info_full
    {book_id: self.ibook_id,
     book_name: self.get_metadata["displayName"],
     book_url: self.get_ibook_url,
     book_hash: "",
     book_size: self.encrypted_content_file_size.to_i, # in bytes
     book_key: self.get_key,
     book_start_date: "",
     book_end_date: ""}
  end

  def get_ibook_url
    if self.encrypted_content.exists?
      "ibooks/#{self.id}/get_ibook"
    else
      ""
    end
  end

  def get_ibook_info_file_url
    if self.info_file.exists?
      "ibooks/#{self.id}/get_ibook_info_file"
    else
      ""
    end
  end


  def get_attachment_parent_dir
    Rails.root.to_s+"/ibook_assets/"+self.id.to_s+"/info_files/"
  end

  def dump_toc
    Rails.logger.debug("--Started dumping of toc--")
    Rails.logger.debug("--#{self.info_file.path}--")
    Zip::ZipFile.open(self.info_file.path) do |zipfile|
      Rails.logger.debug("--Succesfully opened zipfule--")
      db_file_entry = zipfile.find_entry("EdutorContent.db")
      db_file_entry.extract self.get_attachment_parent_dir+"EdutorContent.db"
    end
    return
  end
  alias :dump_content_db :dump_toc

  def dump_cover
    Rails.logger.debug("--Started dumping of cover image--")
    Zip::ZipFile.open(self.info_file.path) do |zipfile|
      db_file_entry = zipfile.find_entry("icons/drawables_ldpi/cover.png")
      zipfile.extract db_file_entry, self.get_attachment_parent_dir+"cover.png"
      FileUtils.mkpath Rails.root.to_s+"/public/ibook_public/#{self.id}/"
      FileUtils.cp_r self.get_attachment_parent_dir+"cover.png", Rails.root.to_s+"/public/ibook_public/#{self.id}/"
    end
    return
  end

  def book_image_path
    self.get_attachment_parent_dir+"cover.png"
  end

  def book_image_url(host)
    if File.exist?(Rails.root.to_s+"/public/ibook_public/#{id}/"+"cover.png")
      "http://#{host}/ibook_public/#{id}/"+"cover.png"
    else
      ""
    end
  end
  # def build_toc_branches(type, parent_guid, book_guid)
  #   TocItem.where(book_guid:book_guid, parent_guid:parent_guid, content_type: type).map{|toc_item|
  #   item_hash = { "name"=>toc_item.name, "uri"=>toc_item.uri, "type"=>toc_item.content_type}
  #     case type
  #       when "chapter"
  #         item_hash["topics"] = build_toc_branches("topic",toc_item.guid,book_guid)
  #       when "topic"
  #         item_hash["sub-topics"] = build_toc_branches("sub-topic",toc_item.guid,book_guid)
  #       when "sub-topic"
  #         item_hash["sub-sub-topics"] = build_toc_branches("sub-sub-topic",toc_item.guid,book_guid)
  #       when "sub-sub-topic"
  #         item_hash["sub-sub-sub-topics"] = build_toc_branches("sub-sub-sub-topic",toc_item.guid,book_guid)
  #     end
  #     item_hash
  #   }
  #
  #
  # end
  def get_toc_tree
  # if self.toc_items.count !=0
  # toc_tree = {"chapters" => build_toc_branches("chapter",self.ibook_id,self.ibook_id)}
  #
  # else
    current_toc_node ={"chapter_name" => "", "topic_name" => "", "sub-topic_name" => "", "sub-sub-topic_name" => "", "sub-sub-sub-topic_name" => ""}
    toc_tree = {"chapters" => []}
    SQLite3::Database.open(self.get_attachment_parent_dir+"EdutorContent.db") do |db|
      db.execute("select uri,class,name from edutorcontentlogical") do |row|
        #row is an array of strings where first item represents uri, and second represents class/type
        uri = row[0]
        type = row[1]
        name = row[2]

        case type
          when "sub-sub-sub-topic"
            current_chapter_name = current_toc_node["chapter_name"]
            current_topic_name = current_toc_node["topic_name"]
            current_sub_topic_name = current_toc_node["sub-topic_name"]
            current_sub_sub_topic_name = current_toc_node["sub-sub-topic_name"]
            relevant_chapter_node = toc_tree["chapters"].find { |chapter| chapter["name"]==current_chapter_name }
            relevant_topic_node = relevant_chapter_node["topics"].find { |topic| topic["name"].to_s==current_topic_name.to_s }
            relevant_sub_topic_node = relevant_topic_node["sub-topics"].find { |stopic| stopic["name"]== current_sub_topic_name }
            relevant_sub_sub_topic_node = relevant_sub_topic_node["sub-sub-topics"].find { |sstopic| sstopic["name"]== current_sub_sub_topic_name }
            relevant_sub_sub_topic_node["sub-sub-sub-topics"] << {"name" => name, "uri" => uri, "type" => type}
          when "sub-sub-topic"
            current_chapter_name = current_toc_node["chapter_name"]
            current_topic_name = current_toc_node["topic_name"]
            current_sub_topic_name = current_toc_node["sub-topic_name"]
            relevant_chapter_node = toc_tree["chapters"].find { |chapter| chapter["name"]==current_chapter_name }
            relevant_topic_node = relevant_chapter_node["topics"].find { |topic| topic["name"].to_s==current_topic_name.to_s }
            relevant_sub_topic_node = relevant_topic_node["sub-topics"].find { |stopic| stopic["name"]== current_sub_topic_name }
            relevant_sub_topic_node["sub-sub-topics"] << {"name" => name, "uri" => uri, "type" => type, "sub-sub-sub-topics" => []}
            current_toc_node["sub-sub-topic_name"] = name
            current_toc_node["sub-sub-sub-topic_name"] = ""
          when "sub-topic"
            current_chapter_name = current_toc_node["chapter_name"]
            current_topic_name = current_toc_node["topic_name"]
            relevant_chapter_node = toc_tree["chapters"].find { |chapter| chapter["name"]==current_chapter_name }
            relevant_topic_node = relevant_chapter_node["topics"].find { |topic| topic["name"].to_s==current_topic_name.to_s }
            relevant_topic_node["sub-topics"] << {"name" => name, "uri" => uri, "type" => type, "sub-sub-topics" => []}
            current_toc_node["sub-topic_name"] = name
            current_toc_node["sub-sub-topic_name"] = ""
            current_toc_node["sub-sub-sub-topic_name"] = ""

          when "topic"
            current_chapter_name = current_toc_node["chapter_name"]
            relevant_chapter_node = toc_tree["chapters"].find { |chapter| chapter["name"]==current_chapter_name }
            relevant_chapter_node["topics"] << {"name" => name, "uri" => uri, "type" => type, "sub-topics" => []}
            current_toc_node["topic_name"] = name
            current_toc_node["sub-topic_name"] = ""
            current_toc_node["sub-sub-topic_name"] = ""
            current_toc_node["sub-sub-sub-topic_name"] = ""
          when "chapter"
            toc_tree["chapters"] << {"name" => name, "uri" => uri, "type" => type, "topics" => []}
            current_toc_node ={"chapter_name" => name, "topic_name" => "", "sub-topic_name" => "", "sub-sub-topic_name" => "", "sub-sub-sub-topic_name" => ""}
        end

      end

    end
    return toc_tree
  # end

  end

  def created_on
    Time.at(self.created_at).strftime("%d/%m/%Y %H:%M")
  end

  def updated_on
    Time.at(self.updated_at).strftime("%d/%m/%Y %H:%M")
  end


  def persist_book_id
    # Directly modifies the value in database instead of going through model
    self.update_column :ibook_id, self.get_metadata["bookId"]
  end

  def self.csv_book_list(user)
    # Assuming user to be a publisher
    books = user.ignitor_books
    csv_data = FasterCSV.generate do |csv|
      csv << "bookId,author,publisher,isbn,subject,academicClass,displayName,description,bookType".split(",")
      books.each do |ibook|
        metadata = ibook.get_metadata
        csv << [metadata["bookId"], metadata["author"], metadata["publisher"], metadata["isbn"], metadata["subject"], metadata["academicClass"], metadata["displayName"], metadata["description"], metadata["bookType"]]
      end
    end
    csv_data
  end

  def save_toc
    # populating the book uploaded toc to the ibook toc items
    metadata = self.get_metadata
    if metadata.has_key? "databaseVersion" and metadata["databaseVersion"] == "2"
      ActiveRecord::Base.transaction do
        SQLite3::Database.open(self.get_attachment_parent_dir+"EdutorContent.db") do |db|
          db.execute("select guid,parent_guid,book_id,target_guid,name,class,uri,passwd,is_locked,play_order,params,tags,is_content,is_assessment,show_in_live_page,show_in_toc,is_streamable,file_type from edutorcontentlogical") do |row|
            toc_row = TocItem.new
            toc_row.guid = row[0]
            toc_row.parent_guid = row[1]
            toc_row.book_guid = row[2]
            toc_row.target_guid = row[3]
            toc_row.name = row[4]
            toc_row.content_type = row[5]
            toc_row.uri = row[6]
            toc_row.passwd = row[7]
            toc_row.is_locked = row[8]
            toc_row.play_order = row[9]
            toc_row.params = row[10]
            toc_row.tagstring = row[11]
            toc_row.is_content = row[12]
            toc_row.is_assessment = row[13]
            toc_row.show_in_live_page = row[14]
            toc_row.show_in_toc = row[15]
            toc_row.is_streamable = row[16]
            toc_row.file_type = row[17]
            toc_row.ibook_id = self.id
            toc_row.save
          end
        end
      end
    end
  end

  def build_toc
    toc_tree  = {bookGuid:ibook_id,toc:{chapters:construct_toc_item_sets('chapter',ibook_id,ibook_id),assets:[]}}
  end

  def construct_toc_item_sets(item_type,parent_guid,book_guid)
    # return statement line not need but just in case
    return [] if TocItem.where({content_type:item_type,parent_guid:parent_guid,book_guid:book_guid}).empty?
    TocItem.where({content_type:item_type,parent_guid:parent_guid,book_guid:book_guid}).map{|toc_item|
      item_hash = {name:toc_item.name,
                   type:toc_item.content_type,
                   uri:toc_item.uri,
                   guid: toc_item.guid,
                   assets:child_assets_for_toc_item(toc_item.guid),
                   tags:(toc_item.tagstring||="")}
      case item_type
        when 'chapter'
          item_hash['topics']= construct_toc_item_sets('topic',toc_item.guid,book_guid)
        when 'topic'
          item_hash['sub-topics']= construct_toc_item_sets('sub-topic',toc_item.guid,book_guid)
        when 'sub-topic'
          item_hash['sub-sub-topics']= construct_toc_item_sets('sub-sub-topic',toc_item.guid,book_guid)
        when 'sub-sub-topic'
          item_hash['sub-sub-sub-topics']= construct_toc_item_sets('sub-sub-sub-topic',toc_item.guid,book_guid)
      end
      item_hash
    }
  end

  def child_assets_for_toc_item(guid)
    TocItem.where(parent_guid:guid).where('file_type not in (?)',['null',""]).map do |toc_asset_item|
     item_hash = {guid:toc_asset_item.guid,file_type:toc_asset_item.file_type,name:toc_asset_item.name} 
     item_hash[:vdocipher_id] = get_vdocipher_id(toc_asset_item.target_guid) if toc_asset_item.file_type=="videocipher"
     item_hash
    end
  end

  def get_vdocipher_id(guid)
    UserAsset.where(guid: guid).present? ? UserAsset.where(guid: guid).first.vdocipher_id.to_s : ""
  end

  def update_version
    metadata = self.get_metadata
    if metadata.has_key? "DatabaseVersion"
      self.update_attribute(:version,metadata["DatabaseVersion"].to_i)
    end
    if metadata.has_key? "databaseVersion"
      self.update_attribute(:version,metadata["databaseVersion"].to_i)
    end
  end

  def get_tags
    tags = Hash.new
    tags["primary"] = Array.new
    tags["secondary"] = Array.new
    self.toc_items.select("tagstring").each do |toc_item|
      begin
        if toc_item.tagstring.present?
          t = JSON.parse(toc_item.tagstring)
          tags["primary"] << t["primary"]
          tags["secondary"] << t["secondary"]
        end
      rescue Exception => e 
        #In some cases tagstring is not a proper json
        logger.info "Exception: #{e}, toc_item_id: #{toc_item.id}"
        next
      end
    end
    tags["primary"] = tags["primary"].flatten.compact.map(&:downcase).uniq
    tags["secondary"] = tags["secondary"].flatten.compact.map(&:downcase).uniq
    tags
  end

  def rename_ibook_info_files
    old_path = info_file.path.gsub("/"+info_file_file_name,"")
    folder_path = self.info_file.path.gsub("/info_files"+"/"+self.info_file_file_name,"")
    if File.exist? "#{folder_path}"+"/info_old_files"
      return false
    else
      FileUtils.mv "#{old_path}", "#{folder_path}"+"/info_old_files"
    end
  end

 def rename_to_latest_ibook_info_files
     old_path = info_file.path.gsub("/"+info_file_file_name,"")
     folder_path = self.info_file.path.gsub("/info_files"+"/"+self.info_file_file_name,"")
     if File.exist? "#{folder_path}"+"/info_#{Time.now.to_i.to_s}_files"
       return false
     else
       FileUtils.mv "#{old_path}", "#{folder_path}"+"/info_#{Time.now.to_i.to_s}_files"
     end
   end

  def converted_house_keep
      self.dump_toc
      self.dump_cover
      self.save_toc
      self.update_version
  end

  def save_metadata
    data = self.get_metadata
    self.metadata = data
    self.subject = data["subject"]
    self.form = data["academicClass"]
    self.save(:validate=>false)
  end

  def self.book_asset_details_for_ops(ibook_ids)
    result = []
    ibooks = Ibook.where(:ibook_id=>ibook_ids)
    ibooks.each do |book|
      info_url = "ibooks/#{book.id}/get_ibook_info_file"
      url = "ibooks/#{book.id}/get_ibook"
      info_filename = book.info_file_file_name rescue ""
      filename = book.encrypted_content_file_name rescue ""
      info_relativefilepath = book.info_file_file_name rescue ""
      relativefilepath = book.encrypted_content_file_name rescue ""
      info_file_md5 = Digest::MD5.hexdigest(File.read(book.info_file.path)) rescue ""
      file_md5 = Digest::MD5.hexdigest(File.read(book.encrypted_content.path)) rescue ""
      info_url_md5 = Digest::MD5.hexdigest(info_url)
      url_md5 = Digest::MD5.hexdigest(url)
      is_sync = "n"
      date_created = Time.at(book.updated_at)
      result << [info_url,info_filename,info_relativefilepath,info_file_md5,info_url_md5,is_sync,date_created,book.ibook_id,"failed","book_info", book.id]
      result << [url,filename,relativefilepath,file_md5,url_md5,is_sync,date_created,book.ibook_id,"failed","book", book.id]
      asset_ids =  book.toc_items.map{|p| p.target_guid}.compact
      # asset_ids = []
      # asset_ids << UserAsset.last(3).map(&:guid)
      # asset_ids << QuizTargetedGroup.last(3).map(&:guid)
      assets = UserAsset.where(:guid=>asset_ids)
      qtgs = QuizTargetedGroup.where(:guid=>asset_ids)
      assets.each do |asset|
        begin
          asset_url = asset.get_attachment_enc_path
          asset_url = (asset_url.split("/") - [""]).join("/")
          asset_filename = asset_url.split("/").last rescue ""
          asset_relativefilepath = asset_url.split("/").last rescue ""
          asset_file_md5 = Digest::MD5.hexdigest(File.read("#{Rails.root.to_s}/public/"+asset.get_attachment_enc_path)) rescue ""
          asset_url_md5 = Digest::MD5.hexdigest(asset_url)
          asset_is_sync = "n"
          asset_date_created = Time.at(asset.updated_at)
          result << [asset_url,asset_filename,asset_relativefilepath,asset_file_md5,asset_url_md5,asset_is_sync,asset_date_created,asset.guid,"failed","asset", asset.id]
        rescue
          next
        end
      end
      qtgs.each do |qtg|
        begin
          quiz_url = qtg.message_quiz_targeted_group.message.assets.first.attachment.url
          quiz_url = (quiz_url.split("/") - [""]).join("/")
          quiz_filename = quiz_url.split("/").last rescue ""
          quiz_relativefilepath = quiz_url.split("/").last rescue ""
          quiz_file_md5 = Digest::MD5.hexdigest(File.read("#{Rails.root.to_s}/public/"+quiz_url)) rescue ""
          quiz_url_md5 = Digest::MD5.hexdigest(quiz_url)
          quiz_is_sync = "n"
          quiz_date_created = Time.at(qtg.timeclose) rescue Time.now
          result << [quiz_url,quiz_filename,quiz_relativefilepath,quiz_file_md5,quiz_url_md5,quiz_is_sync,quiz_date_created,qtg.guid,"failed","quiz",qtg.quiz.createdby ]
        rescue
          next
        end
      end
    end
    return result
  end

end
