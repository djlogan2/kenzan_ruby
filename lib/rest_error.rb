class RestError < StandardError
  attr_reader :error
  def initialize(errorcode, errormsg)
    @error = ErrorResponse.new(errorcode, errormsg)
  end
end