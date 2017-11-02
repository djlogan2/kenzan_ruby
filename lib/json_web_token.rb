class JsonWebToken
  class << self
    def encode(employee)
      new(:employee, employee).send(:do_encode)
    end

    def decode(token)
      new(:token, token).send(:do_decode)
    end
  end

  private

  SIGNING_KEY = 'Kenzan Signing Key'.freeze #Rails.application.secrets.secret_key_base
  EXPIRATION_MINUTES = 60.freeze
  ISSUER = 'Kenzan'.freeze

  def initialize(type, value)
    if type == :employee
      @employee = value
      #do_encode
    else
      @token = value
      #do_decode
    end
  end

  def do_encode
    @payload = {iss: ISSUER, username: @employee.username}
    @payload[:atIssued] = Time.now
    @payload[:exp] = @payload[:atIssued].clone + EXPIRATION_MINUTES * 60
    @header = {alg: 'HS256'}
    s_header = Base64.strict_encode64(@header.to_json)
    s_payload = Base64.strict_encode64(@payload.to_json)
    s_signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, SIGNING_KEY, s_header + '.' + s_payload))
    @token = 'Bearer ' + s_header + '.' + s_payload + '.' + s_signature
#    @token
  end

  def do_decode
    raise(RestError.new(ErrorCode::NO_AUTHORIZATION_TOKEN, 'Token is empty')) if @token.nil?

    bearer, token, hocus = @token.split(' ')

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_TOKEN_PARSE_ERROR, 'Invalid token')) unless bearer == 'Bearer' and token and hocus.nil?

    header, payload, signature, hocus = token.split('.')

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_TOKEN_PARSE_ERROR, 'Signature has expired')) unless payload and header and signature and hocus.nil?

    begin
      @header = JSON.parse Base64.decode64 header
      @payload = JSON.parse Base64.decode64 payload
    rescue JSON::ParserError => e
      raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_TOKEN_PARSE_ERROR, e.message))
    end

    s_signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, SIGNING_KEY, header + '.' + payload))

    begin
      @payload['atIssued'] = Time.parse(@payload['atIssued']) if !@payload['atIssued'].nil?
    rescue ArgumentError => e
      raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_INVALID_ISSUED, e.message))
    end

    begin
      @payload['exp'] = Time.parse(@payload['exp']) if !@payload['exp'].nil?
    rescue ArgumentError => e
      raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_INVALID_EXPIRATION, e.message))
    end

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_HEADER_INVALID_ALGORITHM, 'Invalid algorithm')) unless @header['alg'] == 'HS256'

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_NO_ISSUER, 'No issuer')) if @payload['iss'].nil?
    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_INVALID_ISSUER, 'Invalid issuer')) unless @payload['iss'] == ISSUER

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_NO_ISSUED, 'No issue date')) if @payload['atIssued'].nil?
    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_NO_EXPIRATION, 'No expiration date')) if @payload['exp'].nil?

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_TOKEN_EXPIRED, 'Signature has expired')) if @payload['exp'].localtime <= Time.now

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_INVALID_ISSUED, 'atIssued >= now')) if @payload['atIssued'].localtime >= Time.now
    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_PAYLOAD_INVALID_ISSUED, 'exp <= atIssued')) if @payload['exp'].localtime <= @payload['atIssued'].localtime

    raise(RestError.new(ErrorCode::INVALID_AUTHORIZATION_TOKEN_INVALID_SIGNATURE, 'Invalid signature')) unless s_signature == signature

    @payload
  end

end