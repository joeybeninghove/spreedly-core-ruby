require 'cgi'
require 'uri'

module SpreedlyCore
  module TestHelper
    extend self
    
    def cc_data(cc_type, options={})
    
      card_numbers = {:master => [5555555555554444, 5105105105105100],
        :visa => [4111111111111111, 4012888888881881],
        :american_express => [378282246310005, 371449635398431],
        :discover => [6011111111111117, 6011000990139424]
      }
      
      card_number = options[:card_number] == :failed ? :last : :first
      number = card_numbers[cc_type].send(card_number)
      
      { :credit_card => {
          :first_name => "John",
          :last_name => "Foo",
          :card_type => cc_type,
          :number => number,
          :verification_value => 123,
          :month => 4,
          :year => Time.now.year + 1 }.merge(options[:credit_card] || {})
      }
    end
    
    # Return the base uri as a mocking framework would expect
    def mocked_base_uri_string
      uri = URI.parse(Base.base_uri)
      auth_params = Base.default_options[:basic_auth]
      uri.user = auth_params[:username]
      uri.password = auth_params[:password]
      uri.to_s
    end
  end

  class PaymentMethod

    # Call spreedly core to create a test token.
    # pass_through_data will be added as the "data" field.
    # 
    def self.create_test_token(cc_data={}, pass_through_data=nil)
      data = cc_data.merge(:redirect_url => "http://example.com",
                           :api_login => SpreedlyCore::Base.login,
                           :data => pass_through_data)
      
      response = post("/payment_methods", :body => data, :no_follow => true)
    rescue HTTParty::RedirectionTooDeep => e
      if e.response.body =~ /href="(.*?)"/
        # rescuing the RedirectionTooDeep exception is apparently the way to
        # handle redirect following
        token = CGI::parse(URI.parse($1).query)["token"].first
      end
      raise "Could not find token in body: #{e.response.body}" if token.nil?
      return token
    end
  end
end
