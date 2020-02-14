class TinymceAssetsController < ApplicationController
	require 'net/http'
	require 'open-uri'
  respond_to :json

  def create
    # Take upload from params[:file] and store it somehow...
    # Optionally also accept params[:hint] and consume if needed
    #geometry     = Paperclip::Geometry.from_file params[:file]
   # image = TinymceAsset.new
    #@timestamp=  Time.now.to_time.to_i
    #@filename= @timestamp.to_s << params[:file].original_filename
    #File.open(File.join("app/assets/images/", @filename), 'wb') do |f|
    #  f.write params[:file].read
    #end
   image =  Image.create(:attachment=>params[:file])
    render json: {
        image: {
            url: image.src.split("/").last
        }
    }, content_type: "text/html"
  end
  
  def store_google_image
  	image_source = params[:image_source]
  	image_name = image_source.split("/").last
  	image = ""
      tmp_file_path = Rails.root.to_s+"/tmp/"+ Time.now.to_i.to_s+image_name
			File.open(tmp_file_path, "wb") do |saved_file|
			# the following "open" is provided by open-uri
			open(image_source, "rb") do |read_file|
				saved_file.write(read_file.read)
			image =  Image.create(:attachment=>saved_file)	
			end
		end
			File.delete(tmp_file_path)
		
  	render json: {path: image.src.split("/").last
  	},content_type: "text/html"
  	
  	logger.info "-----------------------------#{image.src} booo-----------------------------"

  end
  
end
