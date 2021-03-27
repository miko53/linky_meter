# Copyright (c) 2020 miko53
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
    
require 'date'
require 'mechanize'
require 'json'
#require 'byebug'

##
# This class is used to retrieve data from the electrical meter
class LinkyMeter

protected
  URL_ENEDIS_AUTHENTICATE = 'https://apps.lincs.enedis.fr/authenticate?target=https://mon-compte-particulier.enedis.fr/suivi-de-mesures/'
  URL_COOKIE = 'https://mon-compte-particulier.enedis.fr'
  URL_USER_INFOS = 'https://apps.lincs.enedis.fr/userinfos'
  URL_GET_PRMS_ID = 'https://apps.lincs.enedis.fr/mes-mesures/api/private/v1/personnes/null/prms'
  
public  
  ## 
  # the following constant are used to retrieve data by time interval
  # use in +get+ method
  BY_YEAR = 0
  BY_MONTH = 1
  BY_DAY = 2
  BY_HOUR = 3
      
  ##
  # The constructor, the +activate_log+ boolean can be set to activate the loggin of http request
  # if necessaory to debug them. the +log_filename+ is the file where log are saved.
  def initialize(activate_log = false, log_filename = 'mechanize.log')
    @log = activate_log
    @log_filename = log_filename
  end
  
  ##
  # the first function to call it permits to register on the website with your credentials
  # +login+ and +password+ and +authentication_cookie+ three string, the last one is to avoid the catcha for the authentication
  def connect(login, password, authentication_cookie)
    
    create_agent() 
    
    cookie = Mechanize::Cookie.new('internalAuthId', authentication_cookie)
    cookie.domain = ".enedis.fr"
    cookie.path = "/"
    @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)
    url = URL_ENEDIS_AUTHENTICATE
    @agent.log.info("LinkyMeter: step 1 : authentification #{url}") unless @agent.log == nil
    r = @agent.get(url)
    if (r.code != "200") then
      raise("Reception Error #{r.code} expected code 200")
    end
    
    @agent.log.info('LinkyMeter: reception request SAML') unless @agent.log == nil
    samlRequest = r.form.field('SAMLRequest').value
    url = r.form.action
    
    request = 
    {
      'SAMLRequest' => samlRequest
    }
    
    @agent.log.info("LinkyMeter: step 2 : send SSO SAMLRequest #{url}") unless @agent.log == nil
    r = @agent.post(url, request)
    if r.code != "302" then
      raise("Reception Error #{r.code} expected : 302")
    end
    
    @agent.log.info('LinkyMeter: get the location and the reqID') unless @agent.log == nil
    #p r.header['location']
    reqID = r.header['location'].match(/ReqID%(.*?)%26/)[1]
    #p reqID
    
    #it should be possible to use r.header['location'] directly but they are some difference...
    url = "https://mon-compte.enedis.fr/auth/json/authenticate?realm=/enedis&forward=true&spEntityID=SP-ODW-PROD&goto=/auth/SSOPOST/metaAlias/enedis/providerIDP?ReqID%#{reqID}%26index%3Dnull%26acsURL%3Dhttps://apps.lincs.enedis.fr/saml/SSO%26spEntityID%3DSP-ODW-PROD%26binding%3Durn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST&AMAuthCookie="
    #p url
    
    @agent.log.info("LinkyMeter: step 3 : auth 1 - retrieve the template (thanks to cookie internalAuthId, the user is already set)") unless @agent.log == nil
    headers = {
            'X-NoSession' => true,
            'X-Password' => 'anonymous',
            'X-Requested-With' => 'XMLHttpRequest',
            'X-Username' => 'anonymous'
            }
    r = @agent.post(url, [], headers)
    if (r.code != "200") then
      raise("Reception error #{r.code} expected 200")
    end
    
    auth_data_basic = JSON.parse(r.body)
    
    if auth_data_basic['callbacks'][0]['input'][0]['value'] != login then
      raise("authentication error, the authentication_cookie is probably wrong")
    end
    
    #fill with the password
    auth_data_basic['callbacks'][1]['input'][0]['value'] = password
    
    url = "https://mon-compte.enedis.fr/auth/json/authenticate?realm=/enedis&spEntityID=SP-ODW-PROD&goto=/auth/SSOPOST/metaAlias/enedis/providerIDP?ReqID%#{reqID}%26index%3Dnull%26acsURL%3Dhttps://apps.lincs.enedis.fr/saml/SSO%26spEntityID%3DSP-ODW-PROD%26binding%3Durn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST&AMAuthCookie="
    @agent.log.info('LinkyMeter: step 3 : auth 2 - send the auth data') unless @agent.log == nil
        headers = {
                'Content-Type' => 'application/json',
                'X-NoSession' => true,
                'X-Password' => 'anonymous',
                'X-Requested-With' => 'XMLHttpRequest',
                'X-Username' => 'anonymous'
                }
    r = @agent.post(url, auth_data_basic.to_json, headers)
    if (r.code != "200") then
      raise("Reception error #{r.code} expected 200")
    end
    
    auth_url_data = JSON.parse(r.body)    
    
    @agent.log.info('LinkyMeter: add the tokenId cookie') unless @agent.log == nil
    cookie = Mechanize::Cookie.new('enedisExt', auth_url_data['tokenId'])
    cookie.domain = ".enedis.fr"
    cookie.path = "/"
    @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)
    
    @agent.log.info('LinkyMeter: step 4 : retrieve the SAMLresponse') unless @agent.log == nil
    r = @agent.get(auth_url_data['successUrl'])
    if (r.code != "200") then
      raise("Reception error #{r.code} expected 200")
    end
    
    url = r.form.action
    response_data = r.form.field('SAMLResponse').value
    request =
    {
    'SAMLResponse' => response_data
    }

    @agent.log.info('LinkyMeter: step 5 : post the SAMLresponse to finish the authentication') unless @agent.log == nil
    r = @agent.post(url, request)
    #p r.code
    if (r.code != "302") then
      raise("Reception error #{r.code} expected 302")
    end
    
    #get information
    @av2_interne_id = ""
    @agent.log.info('LinkyMeter: get userinfos ==> retrieve  av2_interne_id') unless @agent.log == nil
    r = @agent.get(URL_USER_INFOS)
    if (r.code != "200") then
      raise('authentication probably failed')
    else
      user_data = JSON.parse(r.body)
      @av2_interne_id = user_data['userProperties']['av2_interne_id']
    end
     
    @agent.log.info('LinkyMeter: retrieve primary key ==> prmId') unless @agent.log == nil
    @prmId = ""
    r = @agent.get(URL_GET_PRMS_ID)
    if (r.code != "200") then
      raise('authentication probably failed')
    else
      user_data = JSON.parse(r.body)
      @prmId = user_data[0]['prmId']
    end
    
    @agent.log.info("LinkyMeter: authentication done #{@av2_interne_id} #{@prmId}") unless @agent.log == nil
  end
  
  ##
  # the main function of the class, can be called after successfull connection
  # see +connect+
  # the data are retrieved from +begin_date+ to +end_date+ (two +DateTime+ objects)
  # the data interval is specified with +step+ which can be +BY_YEAR+, +BY_MONTH+, +BY_DAY+ or +BY_HOUR+
  # the `result` is a +JSON+ object provided by the server
  def get(begin_date, end_date, step)

    url = ""
    begin_date = begin_date.strftime('%d-%m-%Y')
    end_date = end_date.strftime('%d-%m-%Y')
    
    case step
      
      when BY_YEAR, BY_MONTH, BY_DAY
        url = "https://apps.lincs.enedis.fr/mes-mesures/api/private/v1/personnes/#{@av2_interne_id}/prms/#{@prmId}/donnees-energie?dateDebut=#{begin_date}&dateFin=#{end_date}&mesuretypecode=CONS"
        
      when BY_HOUR
        url = "https://apps.lincs.enedis.fr/mes-mesures/api/private/v1/personnes/#{@av2_interne_id}/prms/#{@prmId}/courbe-de-charge?dateDebut=#{begin_date}&dateFin=#{end_date}&mesuretypecode=CONS"
        
      else
        raise(ArgumentError, 'wrong value for step argument')
    end
    
    page = @agent.get(url)
    if (page.code != "200") then
      raise('Unable to retrieve data')
    else
      json_result = JSON.parse(page.body)
    end
    
    return json_result
  end

  
protected
  ##
  # This function initializes the +Mechanize+ agent used to get data from site  
  def create_agent()
    @agent =  Mechanize.new
    @agent.user_agent_alias = 'Windows Chrome'
    @agent.redirect_ok = false
    if (@log) then
      @agent.log = Logger.new(@log_filename)
    end
  end
end
