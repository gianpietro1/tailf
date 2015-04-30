class DevicesController < ApplicationController

  def index
    @devices = Device.all
  end

  def show
    @device = params[:device]
    @interfaces = Device.interfaces(@device)
    Device.sync_from(@device)
    if flash[:latest_xml]
      @latest_xml = flash[:latest_xml]
    else
      @latest_xml = "No stored XML transaction."
    end
  end

  def update
    @device = params[:device]
    @interfaces = Device.interfaces(@device)
    @interface = params[:interface]
    @ip_address = params[:ip_address]
    @mask = params[:mask_address]
    @transaction_data = Device.change_ip(@device, @interface, @ip_address, @mask)
    flash[:notice] = "IP/Mask for #{@transaction_data[:interface]} was updated with #{@transaction_data[:url]}"
    redirect_to "/devices/#{@device}", :flash => { :latest_xml => @transaction_data[:xml]}
  end

end