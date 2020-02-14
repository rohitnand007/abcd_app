class UsbChipsController < ApplicationController
  skip_before_filter :authenticate_user!, :only => :whitelist_entry
  layout false
  def whitelist_entry
    @usb_chip = UsbChip.new(:chipid => params[:chipid], :chip_size => params[:chip_size], :extras => params[:extras])
    if @usb_chip.save
      respond_to do |format|
        format.json {render :json => {:chip_white_listed=> true}}
      end
    else
      respond_to do |format|
        format.json {render :json => {:chip_white_listed=> false, :error => @usb_chip.errors}}
      end
    end
  end
end
