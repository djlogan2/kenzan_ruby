class JsonWebToken
  SIGNING_KEY = 'Kenzan Signing Key' #Rails.application.secrets.secret_key_base
  EXPIRATION_MINUTES = 60
  ISSUER = 'Kenzan'

  def self.encode(employee_id)
    payload = {iss: ISSUER, employee_id: employee_id}
    payload[:atIssued] = Time.now.to_i
    payload[:exp] = payload[:atIssued] + 60*60
    JWT.encode payload, SIGNING_KEY
  end

  def self.decode(token)
    JWT.decode token, SIGNING_KEY, true, {:iss => ISSUER, :verify_iss => true}
    #return HashWithIndifferentAccess.new(JWT.decode(token, Rails.application.secrets.secret_key_base)[0])
#  rescue
#    nil
  end
end