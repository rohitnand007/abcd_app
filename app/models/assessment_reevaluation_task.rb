class AssessmentReevaluationTask < BackgroundTask
  belongs_to :quiz_targeted_group
  include Workflow

  workflow_column :status
  workflow do
    state :queued do
      event :start, transitions_to: :processing
    end
    state :processing do
      event :success, transitions_to: :reevaluation_done
      event :failed, transitions_to: :reevaluation_failed
    end
    state :reevaluation_done
    state :reevaluation_failed
  end

  def reevaluate(quiz_targeted_group)
    self.start!
    begin
      quiz_targeted_group.reevaluate
      self.success!
    rescue Exception => e
      self.failed!
      Rails.logger.debug ".......#{e}........"
    end
  end

  def humanized_status
    "#{self.status.humanize} at #{Time.at(self.updated_at).to_formatted_s(:long)}"
  end
end