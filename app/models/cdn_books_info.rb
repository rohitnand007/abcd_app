class CdnBooksInfo < CdnContentInfo
after_create :set_asset_type

  def set_asset_type
    self.update_attribute(:asset_type,"book")
  end
end