class UserMessage < ActiveRecord::Base

  def self.get_messages(user_or_id, type="id")
    # Identify the user
    if user_or_id.respond_to? :id
      user = user_or_id
    elsif type=='id'
      user = User.find(user_or_id)
    elsif type=="rollno"
      user = User.where(:rollno => user_or_id).first
    elsif type=="edutorid"
      user = User.where(:edutorid => user_or_id).first
    else
      user = nil
    end
    # Empty Array if there is no user to be found
    return [] if user.blank?
    # Proceed if the user exists
    if user.type=="Student"
      UserMessage.where(user_id: user.id)
    elsif user.respond_to? :students
      students = user.students
      if students.present?
        UserMessage.where(user_id: students.map(&:id))
      else
        []
      end
    else
      []
    end
  end

end
