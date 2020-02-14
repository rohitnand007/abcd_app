class CdnPing < ActiveRecord::Base
  #around_create :set_last_ping

  def set_last_ping
    last_ping = CdnPing.where({device_id:device_id}).last
    unless last_ping.nil?
      self.last_ping = last_ping.created_at
    end
    yield
    self.last_ping ||= self.created_at
  end
end
