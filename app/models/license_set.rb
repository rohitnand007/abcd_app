class LicenseSet < ActiveRecord::Base
  composed_of :starts, :class_name => 'Time', :mapping => %w(starts to_i), :constructor => Proc.new { |item| item }, :converter => Proc.new { |item| item }
  composed_of :ends, :class_name => 'Time', :mapping => %w(ends to_i), :constructor => Proc.new { |item| item }, :converter => Proc.new { |item| item }

  belongs_to :ipack
  belongs_to :institution
  belongs_to :center
  belongs_to :publisher
  has_and_belongs_to_many :users, uniq: true
  has_many :content_access_licenses

  validates :licences, presence: true
  validate :check_dates
  after_commit :reevaluate_license_set

  def check_dates
    errors.add(:base, "End date should be greater than Start") if self.ends < self.starts
  end

  def school
    if !(self.institution.nil?)
      self.institution
    elsif !(self.center.nil?)
      self.center
    else
      nil
    end
  end

  def start_date
    self.starts.nil? ? "" : Time.at(self.starts).strftime("%d/%m/%Y")
  end

  def end_date
    self.ends.nil? ? "" : Time.at(self.ends).strftime("%d/%m/%Y")
  end

  def assign_date
    self.created_at.nil? ? "" : Time.at(self.created_at).strftime("%d/%m/%Y")
  end

  def licenses
    self.licences
  end

  def available
    if self.licences.present?
      self.licences-self.users.count
    else
      0
    end
  end

  def utilized
    self.users.size
  end

  def get_books
    self.ipack.ibooks
  end

  def set_content_access_permission
    user_ids = self.users.map(&:id)
    book_ids = self.get_books.map(&:ibook_id)
    user_ids.each do |u|
      book_ids.each do |b|
        c=ContentAccessPermission.find_or_create_by_user_id_and_accessed_content_guid_and_accessed_content_type_and_access_type_and_starts_and_ends(u, b, "book", "package_assign", self.starts, self.ends)
        ContentAccessLicense.find_or_create_by_license_set_id_and_content_access_permission_id(self.id, c.id)
      end
    end
  end

  def reevaluate_license_set
    #called after revoking users
    begin
      present_user_ids = self.users.map(&:id)
      #remove the revoked old users
      all_content_access_licenses = self.content_access_licenses
      all_content_access_licenses.each do |c_l|
        c_p = c_l.content_access_permission
        if !(present_user_ids.include? c_p.user_id)
          #users license has been revoked
          logger.info "Deleting User: #{c_p.user_id}"
          c_l.destroy
          c_p.destroy
        end
      end
      self.set_content_access_permission 
    rescue Exception => e 
      logger.info "Exception: #{e}"
    end
  end
end
