class AssessmentReportsTask < BackgroundTask
  has_many :assessment_pdf_jobs, :as => :scheduled_task, :dependent => :destroy
  belongs_to :quiz_targeted_group

  include Workflow

  workflow_column :status
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

  def self.clean_up
    AssessmentReportsTask.where("created_at < ?",30.days.ago.to_i).destroy_all
  end
end
