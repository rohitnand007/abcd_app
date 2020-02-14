class NewContext < ActiveRecord::Base

  def self.update_context_with_content
    #@contexts = Context.includes(:board,:subject,:chapter,:topic).join(:question)
    @questions = Question.includes(:question_answers,:context=>[:board,:content_year,:subject,:chapter,:topic]).joins(:context).each do |q|
      context = {:context_id=>q.context_id,:board=>(q.context.board.name rescue ''),:subject=>(q.context.subject.name rescue ''),:chapter=>(q.context.chapter.name rescue ''),:topic=>(q.context.topic.name rescue '') }
      NewContext.create(context)
    end
  end
end
