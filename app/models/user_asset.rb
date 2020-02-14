class UserAsset < ActiveRecord::Base
  attr_accessible :attachment, :asset_name,:is_encrypted, :launch_file, :weblink_url, :asset_type
  belongs_to :user
  has_attached_file :attachment,
                    :path => ":rails_root/public/system/:class/:attachment/:id/:filename"
  # order of processors is the run order
  #                    :processors => [:encrypt]
  # launch_file entry for weblink would be nil

  #some firefox browsers sending pdf file content type as: application/force-download
  validates_attachment_content_type :attachment,
                                    :content_type => ["application/zip", "application/x-zip",
                                                      "application/x-zip-compressed",
                                                      "application/octet-stream",
                                                      "application/pdf", "application/x-shockwave-flash",
                                                      "video/mp4", "video/flv", "audio/mpeg3","audio/mp3", "application/mp4",
                                                      "application/force-download","image/png","image/jpeg","audio/mpeg","application/vnd.android.package-archive"]
  validates_attachment_presence :attachment, :if => Proc.new { |ua|  ua.asset_type != "weblink"}
  has_many :content_deliveries
  belongs_to :ibook
  validates_presence_of :asset_name
  # after_commit :extract_encrypt_and_zip, :on => :create

  has_many :tag_mappings, :as => :taggable
  has_many :tags, :through => :tag_mappings
  after_create :set_file_type
  
  def extract_encrypt_and_zip
    # if self.attachment_content_type == "application/pdf"
      extract
      logger.info "Extraction done"
      encrypt_files
      logger.info "Encryption done"
      zip_enc_files
      logger.info "Zipped encrypt_files"
      #remove_extract_and_encrypted_files
      #logger.info "removed encrypted files"
      system("chmod -R 777 #{Rails.root.to_s + "/public/system"} ")
    # end
  end

  def extract_uploaded_zip
    # if self.attachment_content_type == "application/pdf"
    extract
    logger.info "Extraction done"

    #remove_extract_and_encrypted_files
    #logger.info "removed encrypted files"
    # end
  end
  def encrypt_and_zip
    encrypt_files
    logger.info "Encryption done"
    zip_enc_files
    logger.info "Zipped encrypt_files"
    system("chmod -R 777 #{Rails.root.to_s + "/public/system"} ")

  end
  def reorder_launch_file_in_keys_db
    src = "/" +  self.launch_file.to_s
    a = []
    i = 0
    argsA = self.attachment.path.split("/")
    argsA.pop
    argsA = argsA.join("/") + "_extract"
    argsB = argsA + "_enc" + "/" + "keys.db"
     SQLite3::Database.open(argsB) do |db|
      db.execute("select source_file_path,destination_file_path,md5o,md5e,mimetype,fileSize,key from keys") do |row|
        if row[0].to_s == src
          a << row
        end
      end
      begin
        row = a[0]
        logger.info "source_file_path :selected"
        db.execute("INSERT INTO keys(source_file_path,destination_file_path,md5o,md5e,mimetype,fileSize,key) VALUES (?,?,?,?,?,?,?)",row[0],row[1],row[2],row[3],row[4],row[5],row[6])
      rescue
        logger.info "source file not Duplicated"
      end

    end

  end

  def zip_enc_files
    book_json = []
    book_json << {
        "src" => self.asset_type=="weblink" ? self.weblink_url : "/" + (self.launch_file.nil? ? "" : self.launch_file)
    }
    path = self.attachment.path.split("/")
    path.pop
    zip_location = File.join(path.join("/"),"/asset_" + File.basename(path.join("/")))+'.zip'
    path = path.join("/") + "_extract_enc"
    ActiveRecord::Base.transaction do
      File.open("#{path}/info.json","w") do |f|
        f.write(book_json.to_json)
      end
    end

    Zip::ZipFile.open(zip_location, 'w') do |zipfile|
      Dir["#{path}/**/**"].reject{|f|f==zip_location}.each do |file|
        zipfile.add(file.sub(path+'/',''),file)
      end
    end
  end


  def remove_extract_and_encrypted_files
    argsA = self.attachment.path.split("/")
    argsA.pop
    argsA = argsA.join("/") + "_extract"
    #argsB = argsA + "_enc"
    FileUtils.rm_rf argsA
  end

  def encrypt_files
    if self.asset_type != "weblink"
      argsA = self.attachment.path.split("/")
      argsA.pop
      argsA = argsA.join("/") + "_extract"
      argsB = argsA + "_enc"
      Dir.chdir("public/jars/") do
        # Use your path to the java according to the java directory installed in your machine.
        retResult  = system("java -jar encryptDataV1.jar #{argsA} #{argsB}")
      end
      reorder_launch_file_in_keys_db
      logger.info "reordering src_file_path :Done"
      self.update_attributes(is_encrypted: true)
    end
  end
  # handle_asynchronously :encrypt_files, :priority => 3

  def extract
    if self.asset_type != "weblink"
      argsA = self.attachment.path.split("/")
      argsA.pop
      begin
      if(File.extname(self.attachment.path) == ".zip")
        Zip::ZipFile.open(self.attachment.path) { |zip_file|
          zip_file.each { |f|
            f_path=File.join("#{argsA.join("/")}"+"_extract", f.name)
            FileUtils.mkdir_p(File.dirname(f_path))
              zip_file.extract(f, f_path) unless File.exist?(f_path)
          }
        }
      else
        f_path = "#{argsA.join("/")}" + "_extract"
        logger.info "Destination path: #{f_path}"
        logger.info "source path: #{self.attachment.path}"
        logger.info "Extraction status: started."
        FileUtils.mkdir_p(f_path)
        FileUtils.mv(self.attachment.path,f_path)
        logger.info "Extraction status: done."
      end
      rescue Exception => e
        logger.info "Exception is #{e}"
        # If the uploaded file is not a zip file
        # f_path = "#{argsA.join("/")}" + "_extract"
        # puts f_path
        # FileUtils.mkdir_p(f_path)
        # FileUtils.cp(self.attachment.path,f_path)
        end
    #FileUtils.remove_file self.attachment.path
    end
  end
  def determine_asset_type
    asset_type = []
    Zip::ZipFile.open(self.attachment.path){|zip_file|
     zip_file.each do |file|
       asset_type << File.extname("#{file}")
     end
    }
    if asset_type.include? (".ign")
      return "animation"
    else
      return "html5"
    end
  end

  def upload_attachment_to_vdo_cipher(request_base_url)
    upload_url = request_base_url+ "/user_assets/#{self.id}/download_asset/video.mp4"
    # upload_url = "http://testing2.myedutor.com/message_download/182430/2237/1435671169/2-2-1.mp4"
    url = URI.parse("http://api.vdocipher.com/v2/importURL?url=#{upload_url}")
    req = Net::HTTP::Post.new(url.to_s)
    req.body = 'clientSecretKey=' + $vdo_cipher_key
    res = Net::HTTP.start(url.host, url.port, use_ssl:false) {|http|http.request(req)}
    otp = JSON.parse(res.body)
    self.vdocipher_id = otp['id']
    self.save
  end

  def get_attachment_extract_path
    unextracted_path = self.attachment.path
    x = unextracted_path.split("/")
    file_name = x.pop
    actual_path = x.join("/")+"_extract/"+file_name
  end

  def get_attachment_enc_path
    unextracted_path = self.attachment.path
    x = unextracted_path.split("/")
    file_name = x.pop
    actual_path = x.join("/")+"/asset_"+self.id.to_s+".zip"
    actual_path = actual_path.gsub("#{Rails.root.to_s}/public", "")
  end

  def get_vdo_cipher_details
    start_time = Time.now
    url = URI.parse("http://api.vdocipher.com/v2/videos?search[id]=#{self.vdocipher_id}")
    req = Net::HTTP::Post.new(url.to_s)
    req.body = 'clientSecretKey=' + $vdo_cipher_key
    res = Net::HTTP.start(url.host, url.port, use_ssl:false) {|http|http.request(req)}
    otp = JSON.parse(res.body)
    end_time = Time.now
    logger.info "total_time_taken: #{end_time - start_time} seconds"

    #to get width, height size
    # url2 = URI.parse("http://api.vdocipher.com/v2/files?video=#{self.vdocipher_id}")
    # req = Net::HTTP::Post.new(url2.to_s)
    # req.body = 'clientSecretKey=' + $vdo_cipher_key
    # res2 = Net::HTTP.start(url.host, url.port, use_ssl:false) {|http|http.request(req)}
    # otp2 = JSON.parse(res2.body)
    # logger.info "Second Respone: #{otp2}"
    return otp.first
  end

  def academic_class
    self.tags.where(name: 'academic_class', standard: true).map(&:value)
  end

  def subject
    self.tags.where(name: 'subject', standard: true).map(&:value)
  end

  def concept_name
    self.tags.where(name: 'concept_name', standard:true).map(&:value)
  end

  def add_tags(academic_class, subject, concept_names)
    begin
      ac_tag = Tag.find_by_name_and_value("academic_class", academic_class)
      su_tag = Tag.find_by_name_and_value("subject", subject)
      co_tags = []
      concept_names.each do |concept_name|
        co_tag = Tag.find_by_name_and_value("concept_name", concept_name)
        self.tag_mappings.create(tag_id: co_tag.id)
        co_tags << co_tag
      end
      self.tag_mappings.create(tag_id: ac_tag.id)
      self.tag_mappings.create(tag_id: su_tag.id)
    rescue Exception => e
      logger.info "Exception while adding tags #{e}"
    end
  end

  def set_file_type
    asset_type = self.asset_type
    case asset_type
      when "pdf"
        self.update_attribute(:file_type,"pdf")
      when "concept-map"
        self.update_attribute(:file_type,"concept-map")
      # when "animation"
      #   self.update_attribute(:file_type,"animation")
      when "video-lecture"
        self.update_attribute(:file_type,"video")
      when "text-book"
        self.update_attribute(:file_type,"text-book")
      when "weblink"
        self.update_attribute(:file_type,"url")
      when "audio"
        self.update_attribute(:file_type,"audio")
      when "assessment-quiz"
        self.update_attribute(:file_type,"assessment-quiz")
      when "assessment-practice-tests"
        self.update_attribute(:file_type,"assessment-practice-tests")
      when "image"
        self.update_attribute(:file_type,"text-book")
      when "video"
        self.update_attribute(:file_type,"video-lecture")
      when "text"
        self.update_attribute(:file_type,"pdf")
      when "mp3"
        self.update_attribute(:file_type,"audio")
      when "mp4"
        self.update_attribute(:file_type,"video")
      when "thirdparty"
        self.update_attribute(:file_type,"apk")
      when "animation"
        self.update_attribute(:file_type,"ign")
    end
  end
end
