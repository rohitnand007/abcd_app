class EtxFile < ActiveRecord::Base
  belongs_to :zip_upload

  include Workflow

  workflow_column :state
  workflow do
    state :pending_status do
      event :being_processed, :transitions_to => :awaiting_result
    end
    state :awaiting_result do
      event :accept, :transitions_to => :accepted
      event :reject, :transitions_to => :rejected
    end
    state :accepted
    state :rejected
  end

end
