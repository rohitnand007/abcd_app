class TagReferencesController < ApplicationController

  def destroy
    #@tagref = TagReference.where(tag_id: tag_refer_id: params[:tag_refer_id])
    # @tagref1 = TagReference.where(publisher_question_bank_id: params[:id], tag_id: params[:tag_refer_id])
    # @tagref.destroy_all
    # @tagref1.destroy_all
    @tag = Tag.find(params[:tag_id])
    @tagref = TagReference.find(params[:id])
    @tagref.destroy
    respond_to do |format|
      format.html { redirect_to tag_url(@tag) }
      format.json { head :ok }
    end
  end

end