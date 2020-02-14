class Api::V3::DataUploadController < Api::V3::BaseController

  def upload_screenshot
    @simulation = Simulation.new
    @simulation.asset_guid = params["asset_guid"]
    @simulation.book_guid = params["book_guid"]
    @simulation.extra_info = params["extra_info"]
    @simulation.screenshot = params["file"]
    @simulation.user_id = current_user.id
    if @simulation.save!
      render :json => {success:true, screenshot_url: @simulation.screenshot.path}
    else
      render :json=> {sucess: false, message:"Screenshot cannot be saved"}
    end
  end

  def upload_html_quiz_data
    @user_quiz_data = UserQuizData.new(params["html_quiz_data"])
    @user_quiz_data.user_id = current_user.id
    if @user_quiz_data.save!
      render :json => {success:true, message: "Html Quiz Data Saved Sucessfully"}
    else
      render :json=> {sucess: false, message:"Quiz Data Not Saved"}
    end
  end

  def save_user_notes
    notes_params = params["notes"]
    note_ids = []
    notes_params.each do |note|
      @user_note = UserNote.new(note)
      @user_note.user_id = current_user.id
      if @user_note.save!
        note_ids << @user_note.id
      else
        note_ids << "note not saved"
      end
    end
    render :json => {success:true, message: note_ids}
  end
end