# -*- coding: utf-8 -*-

class RTWatcherTwitterAPI

  def initialize( consumer_key, consumer_secret, access_token, access_token_secret, target_user )
    @target_user = target_user
    @basic_url = 'https://api.twitter.com/1.1/statuses/user_timeline'
    @result_type = 'json'
    @api_url = "#{@basic_url}/#{@target_user}.#{@result_type}?count=200"
    @api_url_after = "#{@basic_url}/#{@target_user}.#{@result_type}?since_id="

    
    @consumer = OAuth::Consumer.new(
                                   consumer_key,
                                   consumer_secret,
                                   :site => 'https://twitter.com'
                                   )
    @access_token = OAuth::AccessToken.new(
                                          @consumer,
                                          access_token,
                                          access_token_secret
                                          )

  end

  def request( after_id = nil )
    return @access_token.get( self.create_request( after_id ))
  end

  def create_request( after_id = nil )
    if (after_id == nil)
      request = @api_url
    else
      request = @api_url_after + after_id
    end
    return request
  end


end
