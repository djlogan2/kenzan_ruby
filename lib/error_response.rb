require('errorcode')
class ErrorResponse
  def initialize(errorcode_or_id, errormsg = nil)
    if errormsg.nil?
      @errorcode = ErrorCode::NONE
      @error = nil
      @id = errorcode_or_id
    else
      @errorcode = errorcode_or_id
      @error = errormsg
      @id = nil
    end
  end
end