class TocItem < ActiveRecord::Base
	belongs_to :ibook
	belongs_to :parent, :class_name => "TocItem", :foreign_key => "parent_guid", primary_key: "guid"
	has_many :children, :class_name => "TocItem", :foreign_key => "parent_guid", primary_key: "guid"

	def all_childrens
		children.map do |ch|
			[ch]+ch.all_childrens
		end.flatten
	end


	def all_children_download_info
		my_info = Hash.new
		my_info["guid"] = self.guid
		my_info["target_guid"] = self.target_guid
		if self.target_guid.present?
			u = UserAsset.where(guid: self.target_guid)
			qtg = QuizTargetedGroup.where(guid: self.target_guid)
			if u.present?
				#if target is an asset
				if  u.first.asset_type == "mp4"
					# {:type =>"vdocipherVideo",:url=>user_asset.vdocipher_id}
					# my_info["type"] = "vdocipherVideo"
          my_info["type"] = "mp4"
					# my_info["url"] = u.first.vdocipher_id
          my_info["url"] = u.first.get_attachment_enc_path
        elsif u.first.asset_type == "pdf"
					# {:type =>"pdf",:url=>user_asset.get_attachment_enc_path}
					my_info["type"] = "pdf"
					my_info["url"] = u.first.get_attachment_enc_path
				end
				#elsif is an assessment
			elsif qtg.present?
				#{:type =>"assessment",:url=>qtg.message_quiz_targeted_group.message.assets.first.attachment.url}
				my_info["type"] = "assessment"
				my_info["url"] = qtg.first.message_quiz_targeted_group.message.assets.first.attachment.url
			end
		end
		my_info["children"] = Array.new
		self.children.each do |c|
			my_info["children"] << c.all_children_download_info
		end
		return my_info
	end


	def self.toc_item_download_info(guid,user)
		item = TocItem.find_by_guid(guid)
		book = Ibook.find_by_ibook_id(guid)
		info = {}
		assets = []
		is_target = false
		if item.present?
			if item.target_guid.nil?
				is_target = true
			end
			toc_items = item.all_childrens
			toc_items << item
		elsif book.present?
			is_target = true
			toc_items  = book.toc_items
		else
			info = {}
			toc_items = []
		end

		toc_items.each do |c|
			begin
				my_info = {}
				if c.target_guid.present?
					my_info["targetGuid"] = c.target_guid
					u = UserAsset.where(guid: c.target_guid)
					qtg = QuizTargetedGroup.where(guid: c.target_guid)
					if u.present?
						#if target is an asset
						if  u.first.asset_type == "mp4"
							# {:type =>"vdocipherVideo",:url=>user_asset.vdocipher_id}
							# my_info["type"] = "vdocipherVideo"
              my_info["type"] = "mp4"
							# my_info["url"] = u.first.vdocipher_id
              my_info["downloadUrl"] = u.first.get_attachment_enc_path
						elsif u.first.asset_type == "pdf"
							# {:type =>"pdf",:url=>user_asset.get_attachment_enc_path}
							my_info["type"] = "pdf"
							my_info["downloadUrl"] = u.first.get_attachment_enc_path
						else
							my_info["type"] = c.content_type
							my_info["downloadUrl"] = u.first.get_attachment_enc_path
						end
						#elsif is an assessment
					elsif qtg.present?
						#{:type =>"assessment",:url=>qtg.message_quiz_targeted_group.message.assets.first.attachment.url}
						my_info["type"] = "assessment"
						my_info["downloadUrl"] = qtg.first.message_quiz_targeted_group.message.assets.first.attachment.url
					end
					assets << my_info
				else
					is_target = true
				end
			rescue
				next
			end
		end
		info["assets"] = assets
		if is_target
			if book.present?
				info["book"] = { "bookId"=>book.ibook_id, "downloadUrl"=>book.get_ibook_url}
			else
				info["book"] = { "bookId"=>item.book_guid, "downloadUrl"=>item.ibook.get_ibook_url}
			end
		else
			info["book"] = { "bookId"=>"", "downloadUrl"=>""}
		end
		return info
	end

	def self.download_book_url(book,user)
		@cdn = user.center.cdn_configs
		if @cdn.empty?
			return book.get_ibook_url
		else
			return @cdn.first.cdn_ip+book.get_ibook_url+"?edutor_id=#{user.edutorid}"
		end
	end

end

