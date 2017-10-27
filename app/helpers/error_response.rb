class ErrorResponse
  def initialize(errorcode_or_id, errormsg = nil)
    if errormsg.nil?
      @errorcode = NONE
      @errormsg = nil
      @id = errorcode_or_id
    else
      @errorcode = errorcode_or_id
      @errormsg = errormsg
      @id = nil
    end
  end
end