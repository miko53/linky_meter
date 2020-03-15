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

##
# This class is used to retrieve data from the electrical meter
class LinkyMeter
  
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
  def new(activate_log = false, log_filename = 'mechanize.log')
    @log = activate_log
    @log_filename = log_filename
  end
  
  ##
  # the first function to call it permits to register on the website with your credentials
  # +login+ and +password+ are two String
  def connect(login, password)
    create_agent()
    
    request =  
    {
      'IDToken1' => login,
      'IDToken2' => password,
      'goto' => Base64.encode64(HOME_URL.encode('utf-8')),
      'gotoOnFail' => '',
      'SunQueryParamsString' => Base64.encode64('realm=particuliers'),
      'encoded' => 'true',
      'gx_charset' => 'UTF-8'
    }

    @agent.post(LOGIN_URL, request)
    
    is_correctly_connected = false
    @agent.cookie_jar.store.each do |c| 
      if c.name == 'iPlanetDirectoryPro' then
        is_correctly_connected = true
      end
    end
    
    if (!is_correctly_connected) then
      raise('authentification error')
    end
  end
  
  ##
  # the main function of the class, can be called after successfull connection
  # see +connect+
  # the data are retrived from +begin_date+ to +end_date+ (two +DateTime+ objects)
  # the data interval is specified with +step+ which can be +BY_YEAR+, +BY_MONTH+, +BY_DAY+ or +BY_HOUR+
  # the `result` is a +JSON+ object provided by the server
  def get(begin_date, end_date, step)
    
    case step
    when BY_YEAR
      ressource_id = 'urlCdcAn'
    when BY_MONTH
      ressource_id = 'urlCdcMois'
    when BY_DAY
      ressource_id = 'urlCdcJour'
    when BY_HOUR
      ressource_id = 'urlCdcHeure'
    else
      raise(ArgumentError, 'wrong value for step argument')
    end
    
    begin_date = begin_date.strftime('%d/%m/%Y')
    end_date = end_date.strftime('%d/%m/%Y')
    
    request = 
    {
      'p_p_id' => REQUEST_WAR_NAME,
      'p_p_lifecycle' => 2,
      'p_p_state'=> 'normal',
      'p_p_mode'=> 'view',
      'p_p_resource_id' => ressource_id,
      'p_p_cacheability'=> 'cacheLevelPage',
      'p_p_col_id' => 'column-1',
      'p_p_col_pos'=> 1,
      'p_p_col_count' => 3,
      '_' + REQUEST_WAR_NAME + '_dateDebut' => begin_date,
      '_' + REQUEST_WAR_NAME + '_dateFin'  => end_date
    }
    
    page = @agent.get(CONSUMPTION_MONITORING_URL, request)
    if (page.code.to_i == 302) then
      page = @agent.get(CONSUMPTION_MONITORING_URL, request)
    end
    
    if (page.code.to_i == 200) then
      json_result = JSON.parse(page.body)
    else
      raise('Unable to retrieve data')
    end
    
    return json_result
  end

  
protected

  LOGIN_URL = 'https://espace-client-connexion.enedis.fr/auth/UI/Login'
  HOME_URL = 'https://mon-compte.enedis.fr/accueil'
  CONSUMPTION_MONITORING_URL = 'https://espace-client-particuliers.enedis.fr/group/espace-particuliers/suivi-de-consommation'
  
  REQUEST_WAR_NAME = 'lincspartdisplaycdc_WAR_lincspartcdcportlet'

  ##
  # This function initializes the +Mechanize+ agent used to get data from site  
  def create_agent()
    @agent =  Mechanize.new
    @agent.user_agent_alias = 'Mechanize'
    @agent.redirect_ok = false
    if (@log) then
      @agent.log = Logger.new(@log_filename)
    end
  end
  
end
