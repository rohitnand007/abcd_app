class ErrorLog < ActiveRecord::Base
  before_save :set_defaults

  def set_defaults
    self.requested_at = Time.now.to_i
  end
end
