require 'set'

require 'httparty'
require 'active_support/core_ext/hash/conversions'

require 'spreedly-core-ruby/base'
require 'spreedly-core-ruby/payment_method'
require 'spreedly-core-ruby/gateway'
require 'spreedly-core-ruby/test_extensions'
require 'spreedly-core-ruby/test_gateway'
require 'spreedly-core-ruby/transactions'
require 'active_support/core_ext/hash/conversions'

module SpreedlyCore
  # Hash of user friendly credit card name to SpreedlyCore API name
  CARD_TYPES = {
    "Visa" => "visa",
    "MasterCard" => "master",
    "American Express" => "american_express",
    "Discover" => "discover"
  }

  class Error < RuntimeError; end

  # Custom exception which occurs when a request to SpreedlyCore times out
  # See SpreedlyCore::Base.default_timeout
  class TimeOutError < Error; end
  class InvalidResponse < Error
    def initialize(response, message)
      super("#{message}\nResponse:\n#{response.inspect}")
    end
  end

  class UnprocessableRequest < Error
    attr_accessor :errors

    def initialize(errors)
      errors = [errors] unless errors.is_a?(Array)
      @errors = errors

      super(errors.join("\n"))
    end
  end

  # Configure SpreedlyCore with a particular account.
  # Strongly prefers environment variables for credentials
  # and will issue a stern warning should they not be present.
  # Reluctantly accepts :login and :secret as options
  def self.configure(options = {})
    login = ENV['SPREEDLYCORE_API_LOGIN']
    secret = ENV['SPREEDLYCORE_API_SECRET']
    gateway_token = ENV['SPREEDLYCORE_GATEWAY_TOKEN']

    if options[:api_login]
      Kernel.warn("ENV and arg both present for api_login. Defaulting to arg value") if login
      login = options[:api_login]
    end

    if options[:api_secret]
      Kernel.warn("ENV and arg both present for api_secret. Defaulting to arg value") if secret
      secret = options[:api_secret]
    end

    if options[:gateway_token]
      Kernel.warn("ENV and arg both present for gateway_token. Defaulting to arg value") if gateway_token
      gateway_token = options[:gateway_token]
    end
    options[:gateway_token] ||= gateway_token

    if options[:api_login] || options[:api_secret]
      Kernel.warn("It is STRONGLY preferred that you house your Spreedly Core credentials only in environment variables.")
      Kernel.warn("This gem prefers only environment variables named SPREEDLYCORE_API_LOGIN, SPREEDLYCORE_API_SECRET, and optionally SPREEDLYCORE_GATEWAY_TOKEN.")
    end

    if login.nil? || secret.nil?
      raise ArgumentError.new("You must provide a login and a secret. Gem will look for ENV['SPREEDLYCORE_API_LOGIN'] and ENV['SPREEDLYCORE_API_SECRET'], but you may also pass in a hash with :api_login and :api_secret keys.")
    end

    options[:endpoint] ||= "https://spreedlycore.com/#{SpreedlyCore::API_VERSION}"

    Base.configure(login, secret, options)
  end

  def self.gateway_token=(gateway_token)
    Base.gateway_token = gateway_token
  end

  def self.gateway_token
    Base.gateway_token
  end

  # returns the configured SpreedlyCore login
  def self.login; Base.login; end

  # A container for a response from a payment gateway
  class Response < Base
    attr_reader(:success, :message, :avs_code, :avs_message, :cvv_code,
                :cvv_message, :error_code, :error_detail, :created_at,
                :updated_at)
  end
end
