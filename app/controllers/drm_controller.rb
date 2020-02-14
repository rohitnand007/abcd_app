class DrmController < ApplicationController

  def content_zip_upload
    unless params[:data].present?
      flash[:error] = "File can't be blank."
    else
      name =  params[:data].original_filename
      if File.extname(name) == '.zip'
        #begin
        #  ActiveRecord::Base.transaction do
            directory = "#{Rails.root.to_s}/drm_zip_files"
            path = File.join(directory, name)
            File.open(path, "wb") { |f| f.write(params[:data].read) }
            extract_path =  Rails.root.to_s+"/drm_zip_files/#{Time.now.to_i}"
            FileUtils.mkdir_p(Rails.root.to_s+"/drm_zip_files/#{Time.now.to_i}")
            Zip::ZipFile.open(path) {|zip_file|
              zip_file.each { |f|
                f_path=File.join(extract_path, f.name)
                FileUtils.mkdir_p(File.dirname(f_path))
                zip_file.extract(f,f_path)    }
            }
            metadata =  Nokogiri::XML(open(extract_path+"/publisher-metadata.xml"))
            publisher = DrmPublisher.new
            publisher.identifier = metadata.xpath('/metadata/identifier').text
            publisher.creator = metadata.xpath('/metadata/creator').text
            publisher.publisher_id = metadata.xpath('/metadata/publisher-id').text
            publisher.name = metadata.xpath('/metadata/publisher-name').text
            publisher.save!

            license = DrmLicense.new
            license.total_licenses = metadata.xpath('/metadata/total_licences').text
            license.license_cost = metadata.xpath('/metadata/cost_per_licence').text
            license.start_date = metadata.xpath('/metadata/datetime/start').text.to_i
            license.end_date = metadata.xpath('/metadata/datetime/end').text.to_i
            license.save

            opf_file = Nokogiri::XML(open(extract_path+"/content/META-INF/container.xml")).xpath("/container/rootfiles/rootfile").attr('full-path').to_s

            opf_file_path =  extract_path+"/content/"+opf_file
            opf_file_name =  opf_file_path.split('/').last

            content_meta = Nokogiri::XML(open(opf_file_path))
            drm_content = DrmContent.new
            drm_content.title = content_meta.xpath('/package/metadata/title').text
            drm_content.subject = content_meta.xpath('/package/metadata/subject').text
            drm_content.syllabus = content_meta.xpath('/package/metadata/syllabus').text
            drm_content.academic_class = content_meta.xpath('/package/metadata/class').text
            drm_content.key = metadata.xpath('/metadata/package_cek').text
            drm_content.drm_publisher_id = publisher.id
            drm_content.drm_license_id = license.id
            drm_content.src = extract_path
            drm_content.save

            items = []
            content_meta.xpath('/package/manifest/item').collect{|x| items << x if x.attr("media-type").to_s == "application/pdf"}
            items = items - [nil]
            items.each do |item|
              if item.attr('href') != ''
              asset = DrmAsset.new
              asset.drm_content_id = drm_content.id
              asset.attachment = File.open(opf_file_path.gsub(opf_file_name,'')+item.attr('href').to_s)
              asset.save
              end
            end
            FileUtils.rm extract_path+"/publisher-metadata.xml"
         # end
          flash[:notice]= "zip uploaded"
          redirect_to  drm_content_show_path(drm_content)
        #rescue Exception => e
        #  puts "Exception in publishing...............#{e.message}"
        #  logger.info "Exception in publishing...............#{e}"
        #  flash[:error] = "#{e.message} for #{e.try(:record).try(:class).try(:name)}"
        #  redirect_to  drm_content_show_path(drm_content)
        #end


      else
        flash[:error] = "File type must be a zip."
      end
    end
  end

  def drm_content_list
    @contents = DrmContent.all
  end

  def drm_content_show
    @content = DrmContent.find(params[:id])
  end

  def drm_content_publish
    @message = Message.new
    @content = DrmContent.find(params[:id])
  end

  def  drm_content_send
    @message = Message.new(params[:message])
    @content = DrmContent.find(params[:id])
    user_id = params[:message][:multiple_recipient_ids]
    @user= User.find(user_id)
    #begin
    #  ActiveRecord::Base.transaction do
        user_key = get_user_key(@user)
        user_content_key = get_user_content_key(user_key,@user,@content)
        user_files_path = Rails.root.to_s+"/drm_zip_files/#{@user.id}/#{@user.id}_#{@content.id}"
        zip_path =  Rails.root.to_s+"/drm_zip_files/#{@user.id}/#{@user.id}_#{@content.id}_zip"
        FileUtils.mkdir_p zip_path
        FileUtils.mkdir_p Rails.root.to_s+"/drm_zip_files/#{@user.id}/#{@user.id}_#{@content.id}"
        FileUtils.cp_r "#{@content.src}/.", user_files_path

        #FileUtils.rm user_files_path+"/content/META-INF/rights.xml"
        #FileUtils.rm user_files_path+"/content/META-INF/signature.xml"


        @rights = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.rights {
            xml.rights_context {
              xml.rights_version 1.0
              xml.uid user_content_key.rid
            }
            xml.agreement{
              @content.drm_assets.each do |file|
                xml.asset(:id=>file.attachment_file_name){
                  xml.key_info{
                    xml.ecek{
                      xml.chiper_data user_content_key.encrypted_text.unpack('H*').join('')
                    }
                    xml.digest get_asset_digest(file.attachment.path).unpack('H*').join('')
                  }
                }
              end
              xml.permission(:on_expired_url=>"http://edutor.com/whattodo"){
                @content.drm_assets.each do |file|
                  xml.asset(:idref=>file.attachment_file_name){}
                end
                xml.constraint{
                  xml.date_time{
                    xml.start @content.drm_license.start_date
                    xml.end @content.drm_license.end_date
                  }
                }
              }
            }
          }
        end
        path = user_files_path+"/content/META-INF"
        file = File.new(path+"/"+"rights.xml", "w+")
        File.open(file,'w') do |f|
          f.write(@rights.to_xml)
        end

        @signature = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.signatures{
            xml.signature(:id=>'sig'){
              xml.signed_info{
                xml.signature_method(:algorithm=>"HMAC")
                xml.reference(:uri=>"#manifest1"){
                  xml.digest_method(:algorithm=>"sha1")
                  xml.digest_value get_signature_key(path+"/rights.xml").unpack('H*').join('')
                }
              }
              xml.signature_value get_dsa_key(path,user_content_key,user_key).sign_key.unpack('H*').join('')
              xml.object{
                xml.manifest(:id=>"manifest1"){
                  xml.refernce(:uri=>"META-INF/rights.xml"){}
                }
              }
            }
          }
        end
        file = File.new(path+"/"+"signature.xml", "w+")
        File.open(file,'w') do |f|
          f.write(@signature.to_xml)
        end

        zip_file = drm_content_zip(zip_path,"#{@user.id}_#{@content.id}.zip",user_files_path)
        @message.body = params[:message][:body]
        @message.message_type = "Content"
        @message.recipient_id = @user.id
        message_asset = @message.assets.build
        message_asset.attachment = File.new(zip_file,'r')
        @message.save
    #  end

      flash[:notice]= "Content published successfully"
    #rescue Exception => e
    #  puts "Exception in publishing...............#{e.message}"
    #  logger.info "Exception in publishing...............#{e}"
    #  flash[:error] = "#{e.message} for #{e.try(:record).try(:class).try(:name)}"
    #end
    redirect_to drm_content_list_path

  end

  def get_user_key(user)
    if user.user_key
      return user.user_key
    else
      user_private_key = OpenSSL::PKey::RSA.new(1024)
      user_public_key = user_private_key.public_key
      user_dsa = OpenSSL::PKey::DSA.new(1024)
      user_key = UserKey.new(:user_id=>user.id,:rsa_public_key=>user_public_key.to_pem,:rsa_private_key=>user_private_key.to_pem,:dsa_private_key=>user_dsa.to_pem,:dsa_public_key=>user_dsa.public_key.to_pem)
      user_key.save
      return user_key
    end
  end

  def get_user_content_key(user_key,user,content)
    content_user_private_key = OpenSSL::PKey.read(user_key.rsa_private_key)
    content_user_public_key = content_user_private_key.public_key
    content_key = content_user_public_key.public_encrypt("#{content.key}")
    logger.info "======content-key========#{content_key}"
    user_content_key = UserContentKey.new(:user_id=>user.id,:encrypted_text=>content_key,:drm_content_id=>content.id,:rid=>"ER#{user.id}C#{content.id}")
    user_content_key.save
    return user_content_key
  end

  def get_asset_digest(file)
    data = File.read(file)
    sha256 = OpenSSL::Digest::SHA256.new
    digest = sha256.digest(data)
  end

  def get_dsa_key(path,content_key,user_key)
    dsa = OpenSSL::PKey.read(user_key.dsa_private_key)
    doc =  File.read(path+"/rights.xml")
    digest = OpenSSL::Digest::SHA1.digest(doc)
    #digest = Array(digest.unpack('H*').join('').gsub('0','')).pack('H*').join('')
    sign = dsa.syssign(digest)
    user_content_key = UserContentKey.find(content_key.id)
    user_content_key.update_attributes(:dsa_private_key=>dsa.to_pem,:dsa_public_key=>dsa.public_key.to_pem,:digest_key=>digest,:sign_key=>sign)
    return user_content_key
  end

  def get_signature_key(file)
    data = File.read(file)
    sha1 = OpenSSL::Digest::SHA1.new
    digest = sha1.digest(data)
  end


  def drm_content_zip(dest_path,name,source_path)
    target_file =  dest_path+'/'+name
    if File.exist?(target_file)
      FileUtils.rm_rf (target_file)
    end
    inputDir = source_path
    entries = Dir.entries(inputDir)
    entries.delete(".")
    entries.delete("..")
    io = Zip::ZipFile.open(target_file, Zip::ZipFile::CREATE)
    zipEntries(inputDir,entries, "", io)
    io.close();
    return target_file
  end
  def zipEntries(inputDir,entries, path, io)
    entries.each { |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(inputDir, zipFilePath)
      puts "==Deflating==" + diskFilePath
      if File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir = Dir.entries(diskFilePath)
        subdir.delete(".")
        subdir.delete("..")
        zipEntries(inputDir,subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
      end
    }
  end


  def user_drm_keys
    @user = User.find(params[:user_id])
    key = get_user_key(@user)
    respond_to do |format|
      format.json { render json:key }
    end
  end

  def user_content_registration
    @user = User.find_by_edutorid(params[:user_id])
    @content_key = UserContentKey.find_by_rid_and_user_id(params[:rid],@user.id)
    if @content_key
      @content_key.update_attribute(:status,1)
      rights = true
    else
      rights = false
    end
    respond_to do |format|
      format.json { render json:rights}
    end

  end


  def user_content_registration_list
    @contents = UserContentKey.all
  end

  def drm_user_content_list
    @contents = UserContentKey.where(:user_id=>current_user.id)
  end

  def drm_zip_download
    user = params[:user]
    content = params[:content]
    file = "#{Rails.root}/drm_zip_files/#{user}/#{user}_#{content}_zip/#{user}_#{content}.zip"
    send_file file
  end

end
