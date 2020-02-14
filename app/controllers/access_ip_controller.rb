
# To change this template, choose Tools | Templates
# and open the template in the editor.

# Input format json
# params id,url
class AccessIpController < ApplicationController
#authorize_resource
  skip_before_filter :authenticate_user!
  def index
    require 'domainatrix'
    result = {};
    result['response'] = false;
    result['message'] = 'Not valid request format.';
    # First validate the request format

    #params['id'] = 'CR-00007';
    #params['url'] = 'http://google.com';

    if(params[:id].nil? || params[:url].nil?)
      respond_to do |format|
        format.html { render json: result }
        format.json { render json: result }
      end
      return
    end

    domainatrix = Domainatrix.parse(params['url'])
    exact_domain = domainatrix.subdomain+'.'+domainatrix.domain+'.'+domainatrix.public_suffix
    if domainatrix.subdomain.empty?
      exact_domain = 'www.'+domainatrix.domain+'.'+domainatrix.public_suffix #add www
    end
    domain = domainatrix.domain+'.'+domainatrix.public_suffix #without subdomain
    all_domain = '*.'+domain
    
    #Get the user
    user = User.where(:edutorid=>params[:id]);
    if (user.length > 1 || user.length ==0)
      result['message'] = "Authentication failure"
      respond_to do |format|
        format.html { render json: result }
        format.json { render json: result }
      end
      return;
    end

    user = user.first;

    #First Check in ip_override
    override = IpTableOverride.where("edutor_id = ? AND institution_id = ? AND center_id = ? AND (domain = ? OR domain = ? OR domain= ?) AND status=?",
      user.edutorid,user.institution_id,user.center_id,exact_domain,all_domain,'*',1)

    if override.exists?
      result['response'] = true;
      result['message'] = '';
      respond_to do |format|
        format.html { render json: result }
        format.json { render json: result }
      end
      return
    end

    #Now check with ip_table
    ip = IpTable.where("role_id = ? AND institution_id = ? AND center_id = ? AND (domain = ? OR domain = ? OR domain = ?) AND status=?",
      user.role_id,user.institution_id,user.center_id,exact_domain,all_domain,'*',1)

    
    if ip.exists?
      result['response'] = true;
      result['message'] = '';
    else
      result['message'] = "Not authorized"
    end
    respond_to do |format|
      format.html { render json: result }
      format.json { render json: result }
    end
  end
end
