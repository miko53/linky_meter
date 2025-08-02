# frozen_string_literal: true
require 'date'
require 'mechanize'
require 'json'
#require 'byebug'

# This class is used to retrieve data from the electrical meter
module Linky
  # class
  class LinkyMeter
    protected

    URL_COOKIE = 'https://mon-compte.enedis.fr'
    URL_USER_INFOS = '/mon-compte/api/private/v2/userinfos'
    URL_USER_INFOS_2 = '/mon-compte/api/private/v2/userinfos?espace=PARTICULIER'

    def get_url_prms_id(av2_interne_id)
      "/mes-prms-part/api/private/v2/personnes/#{av2_interne_id}/prms"
    end

    public

    ##
    # the following constant are used to retrieve data by time interval
    # use in +get+ method
    BY_YEAR = 0
    BY_MONTH = 1
    BY_DAY = 2
    BY_HOUR = 3

    def initialize(activate_log = false, log_filename = 'mechanize.log')
      @log = activate_log
      @log_filename = log_filename
      create_agent
    end

    def connect(username, password, authentication_cookie)
      @agent.log&.info('LinkyMeter: begin connection')

      cookie = Mechanize::Cookie.new('atuserid', '%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%22336491e9-fb7b-4712-ad19-8de38860eae6%22%2C%22options%22%3A%7B%22end%22%3A%222026-06-19T13%3A26%3A06.043Z%22%2C%22path%22%3A%22%2F%22%7D%7D')
      cookie.domain = '.enedis.fr'
      cookie.path = '/'
      @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)

      cookie = Mechanize::Cookie.new('atauthority', '%7B%22name%22%3A%22atauthority%22%2C%22val%22%3A%7B%22authority_name%22%3A%22default%22%2C%22visitor_mode%22%3A%22optin%22%7D%2C%22options%22%3A%7B%22end%22%3A%222026-06-19T13%3A26%3A12.174Z%22%2C%22path%22%3A%22%2F%22%7D%7D')
      cookie.domain = '.enedis.fr'
      cookie.path = '/'
      @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)
      cookie = Mechanize::Cookie.new('TCPID', '12550152663921428712')
      cookie.domain = '.enedis.fr'
      cookie.path = '/'
      @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)
      cookie = Mechanize::Cookie.new('TC_Consentement', '0%40042%7C3%7C5%7C106%7C7%7C4557%402%2C3%407%401747574769320%2C1747574769320%2C1763126769320%40_h8%3D')
      cookie.domain = '.enedis.fr'
      cookie.path = '/'
      @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)
      cookie = Mechanize::Cookie.new('TC_Consentement_CENTER', '2%2C3')
      cookie.domain = '.enedis.fr'
      cookie.path = '/'
      @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)

      cookie = Mechanize::Cookie.new('internalAuthId', authentication_cookie)
      cookie.domain = '.enedis.fr'
      cookie.path = '/'
      @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)

      r = @agent.get('https://alex.microapplications.enedis.fr/authenticate?target=https://mon-compte-client.enedis.fr/hub?allEspace=false')

      params = {}
      loop do
        break unless r.code.to_i == 302

        url = r.response['location']
        r = @agent.get(url)
        # p "reply: #{r}"
        # p "location: #{r.response['location']}"
        unless r.response['location'].nil?
          encoded_uri = r.response['location']
          encoded_uri = CGI.unescape(encoded_uri)
          @agent.log&.info("encoded_uri: #{encoded_uri}")
          # p "encoded_uri: #{encoded_uri}"
          param = decode_uri(encoded_uri)
          if !param.nil?
            params = param
          end
        end
      end

      r = @agent.get('https://mon-compte.enedis.fr/auth/json/serverinfo/*?realm=/enedis', [], 'https://mon-compte.enedis.fr/auth/XUI/')
      # p r
      # p r.response['location']

      headers = {
        'Accept' => 'application/json, text/javascript, */*; q=0.01',
        'Accept-Encoding' => 'gzip, deflate, br, zstd',
        'Content-Type' => 'application/json',
        'Accept-API-Version' => 'protocol=1.0,resource=2.0',
        'X-Requested-With' => 'XMLHttpRequest',
        'Origin' => 'https://mon-compte.enedis.fr',
        'Connection' => 'keep-alive',
        'Referer' => 'https://mon-compte.enedis.fr/auth/XUI/',
        'Sec-Fetch-Dest' => 'empty',
        'Sec-Fetch-Mode' => 'cors',
        'Sec-Fetch-Site' => 'same-origin',
        'Content-Length' => '0'
      }

      begin
        r = @agent.post('https://mon-compte.enedis.fr/auth/json/users?_action=idFromSession&realm=/enedis', [], headers)
      rescue
        @agent.log&.info('Exception ? ')
        # p 'exception ?'
      end

      client_id = params['client_id'].first
      nonce = params['nonce'].first
      state = params['state'].first

      @agent.log&.info("LinkyMeter: client_id=#{client_id} state=#{state} nonce=#{nonce}")

      url = "/auth/json/authenticate?realm=/enedis&goto=https%3A%2F%2Fmon-compte.enedis.fr%2Fauth%2Foauth2%2Fenedis%2Fauthorize%3Fresponse_type%3Dcode%26client_id%3D#{client_id}%26scope%3Dopenid%2520email%2520profile%26state%3D#{state}%253D%26redirect_uri%3Dhttps%253A%252F%252Falex.microapplications.enedis.fr%252Flogin%252Foauth2%252Fcode%252Falexwebsso%26nonce%3D#{nonce}"
      r = @agent.post(url, [], headers)
      # p r

      body = r.body
      auth_data_basic = JSON.parse(body)

      auth_data_basic['callbacks'][0]['input'][0]['value'] = username
      auth_data_basic['callbacks'][1]['input'][0]['value'] = password

      url = "/auth/json/authenticate?realm=/enedis&realm=/enedis&goto=https%3A%2F%2Fmon-compte.enedis.fr%2Fauth%2Foauth2%2Fenedis%2Fauthorize%3Fresponse_type%3Dcode%26client_id%3D#{client_id}%26scope%3Dopenid%2520email%2520profile%26state%3D#{state}%253D%26redirect_uri%3Dhttps%253A%252F%252Falex.microapplications.enedis.fr%252Flogin%252Foauth2%252Fcode%252Falexwebsso%26nonce%3D#{nonce}"
      r = @agent.post(url, auth_data_basic.to_json, headers)
      # p r

      auth_url_data = JSON.parse(r.body)
      # p auth_url_data

      @agent.log&.info('LinkyMeter: add the tokenId cookie')
      cookie = Mechanize::Cookie.new('enedisExt', auth_url_data['tokenId'])
      cookie.domain = '.enedis.fr'
      cookie.path = '/'
      @agent.cookie_jar.add(URI.parse(URL_COOKIE), cookie)

      url = '/auth/json/users?_action=idFromSession&realm=/enedis'
      r = @agent.post(url, [], headers)
      # p r

      url = "/auth/json/enedis/users/#{username}?realm=/enedis"
      r = @agent.get(url)
      # p r

      url = "/auth/oauth2/enedis/authorize?response_type=code&client_id=#{client_id}&scope=openid%20email%20profile&state=#{state}&redirect_uri=https%3A%2F%2Falex.microapplications.enedis.fr%2Flogin%2Foauth2%2Fcode%2Falexwebsso&nonce=#{nonce}"
      r = @agent.get(url)
      # p r
      # code = 302
      url = r.response['location']
      r = @agent.get(url)
      # p r
      # code = 302
      # url = r.response['location']
      r = @agent.get('/authenticate?target=https://mon-compte-client.enedis.fr%2Fhub%3FallEspace%3Dfalse')
      # p r
      # code = 307

      headers['Referer'] = 'https://mon-compte-client.enedis.fr'

      # get information
      @av2_interne_id = ''
      @agent.log&.info('LinkyMeter: get userinfos ==> retrieve  av2_interne_id')
      r = @agent.get(URL_USER_INFOS)
      raise('authentication probably failed') if r.code != '200'

      r = @agent.get(URL_USER_INFOS_2)
      raise('authentication probably failed') if r.code != '200'

      user_data = JSON.parse(r.body)
      @av2_interne_id = user_data['cnAlex']

      @agent.log&.info('LinkyMeter: retrieve primary key ==> IdPrm')
      @prm_id = ''
      url = get_url_prms_id(@av2_interne_id)
      r = @agent.get(url)
      raise('authentication probably failed') if r.code != '200'

      user_data = JSON.parse(r.body)
      @prm_id = user_data[0]['idPrm']

      @agent.log&.info("LinkyMeter: authentication done #{@av2_interne_id} #{@prm_id}")
    end

    ##
    # the main function of the class, can be called after successfull connection
    # see +connect+
    # the data are retrieved from +begin_date+ to +end_date+ (two +DateTime+ objects)
    # the data interval is specified with +step+ which can be +BY_YEAR+, +BY_MONTH+, +BY_DAY+ or +BY_HOUR+
    # the `result` is a +JSON+ object provided by the server
    def get(begin_date, end_date, step)
      url = ''
      begin_date = begin_date.strftime('%Y-%m-%d')

      # no more used
      end_date = end_date.strftime('%Y-%m-%d')

      case step
      when BY_YEAR, BY_MONTH, BY_DAY
        url = "/mes-mesures-prm/api/private/v1/personnes/#{@av2_interne_id}/prms/#{@prm_id}/donnees-energetiques?mesuresTypeCode=ENERGIE&mesuresCorrigees=false&typeDonnees=CONS&dateDebut=#{begin_date}"

      when BY_HOUR
        url = "/mes-mesures-prm/api/private/v1/personnes/#{@av2_interne_id}/prms/#{@prm_id}/donnees-energetiques?mesuresTypeCode=COURBE&mesuresCorrigees=false&typeDonnees=CONS&dateDebut=#{begin_date}"

      else
        raise(ArgumentError, 'wrong value for step argument')
      end

      page = @agent.get(url)
      raise('Unable to retrieve data') if page.code != '200'

      JSON.parse(page.body)
    end

    protected

    def decode_uri(uri)
      # p uri
      uri = URI.parse(uri)
      if !uri.query.nil?
        CGI.parse(uri.query)
      else
        nil
      end
    end

    ##
    # This function initializes the +Mechanize+ agent used to get data from site
    def create_agent
      @agent = Mechanize.new
      @agent.user_agent_alias = 'Windows Chrome'
      @agent.redirect_ok = false
      @agent.log = Logger.new(@log_filename) if @log
    end
  end
end
