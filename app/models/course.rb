class Course < ActiveRecord::Base
  has_and_belongs_to_many :ibooks
  belongs_to :store
  attr_accessor :book_ids
  def attributes
    super.merge({'book_ids'=>self.ibooks.map(&:ibook_id)})
  end
  def book_ids
    self.ibooks.map(&:ibook_id)
  end

  def get_tags
  	tags = Hash.new
  	tags["primary"] = Array.new
    tags["secondary"] = Array.new
    self.ibooks.each do |ibook|
    	book_tags = ibook.get_tags
    	if book_tags.present?
	    	tags["primary"] << book_tags["primary"] if book_tags["primary"].present?
	    	tags["secondary"] << book_tags["secondary"] if book_tags["secondary"].present?
	    end
    end
    tags["primary"] = tags["primary"].flatten.compact.map(&:downcase).uniq
    tags["secondary"] = tags["secondary"].flatten.compact.map(&:downcase).uniq
    tags
  end

  def booklist(request_host_with_port)
    booklist= self.ibooks.map do |ibook|
      metadata = ibook.get_metadata
      image_url = ibook.book_image_url(request_host_with_port)
      {book_id: ibook.ibook_id,
       publisher_id: ibook.publisher_id,
       description: metadata["description"],
       image_url: image_url,
       author: metadata["author"],
       publisher: metadata["publisher"],
       isbn: metadata["isbn"],
       subject: metadata["subject"],
       academicClass: metadata["academicClass"],
       name: metadata["displayName"]}
    end.uniq
  end

  def as_json(options = { })
      # Extends the original method to give books information
      options[:request_host_with_port]||=""
      super(options).merge({
          :booklist => self.booklist(options[:request_host_with_port])
      })
  end

end