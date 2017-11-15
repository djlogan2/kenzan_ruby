require('error_response')
require('errorcode')
require('json_web_token')
require('rest_error')

class RestController < ApplicationController
  before_action :authenticate_employee!, :except => :login
  before_action :adjust_parameters

  ActionController::Parameters.action_on_unpermitted_parameters = :raise

  rescue_from Exception do |e|
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, e.as_json)
  end

  rescue_from ActiveRecord::UnknownAttributeError do |uae|
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, uae.to_s)
  end

  rescue_from ActionController::UnpermittedParameters do |pme|
    if params[:action] == 'set_password' or params[:action] == 'login'
      render :json => ErrorResponse.new(ErrorCode::INVALID_USERNAME_OR_PASSWORD, 'Unknown fields')
    else
      render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_UNKNOWN_FIELDS, 'Unknown fields')
    end
  end

  def get_all
    employees = Employee.select(returned_employee_fields).all
    render :json => employees
  end

  def get_emp
    begin
      findparams = {}
      [:id, :firstName, :middleInitial, :lastName, :username, :email, :dateOfBirth, :dateOfEmployment].each do |element|
        findparams[element] = params[element] if params.has_key? element
      end

      employees = Employee.where(findparams)
      if employees.count > 1
        render :json => nil #ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'Record not found' )
        return
      end

      render :json => employees[0]
    rescue ActiveRecord::RecordNotFound
      render :json => nil #ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'Record not found' )
    end
  end

  def delete_emp
    if !@current_user.try(:can?, :delete)
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized')
      return
    end
    begin
      employee = Employee.find(params[:id])
      employee.bStatus = EmployeeStatus::INACTIVE
      employee.save
      #employee.delete
      render :json => ErrorResponse.new(employee.id)
    rescue ActiveRecord::RecordNotFound
      render :json => ErrorResponse.new(ErrorCode::CANNOT_DELETE_NONEXISTENT_RECORD, 'Record not found')
    end

  end

  def login
    if !params.has_key?(:rest) or !params[:rest].has_key?(:username) or !params[:rest].has_key?(:password)
      render :json => ErrorResponse.new(ErrorCode::INVALID_USERNAME_OR_PASSWORD, 'Not authorized')
      return
    end
    params.require(:rest).permit(:username, :password)
    authenticate_employee
  end

  def add_emp
    if !@current_user.try(:can?, :add)
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized')
      return
    end

    if !params.has_key?(:bStatus)
      render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_MISSING_FIELDS, 'bStatus must be specified')
      return
    end

    employee = Employee.new employee_params

    if !@current_user.try(:can?, :set_password) || employee.password.blank?
      employee.password = SecureRandom.hex
    end

    begin
      if employee.save
        render :json => ErrorResponse.new(employee.id)
      else
        render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_MISSING_FIELDS, employee.errors.messages.to_s)
      end
    rescue ActiveRecord::StatementInvalid => e
      render :json => ErrorResponse.new(ErrorCode::DUPLICATE_RECORD, e.message)
    end
  end

  def update_emp
    if !@current_user.try(:can?, :update)
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized')
      return
    end

    if params[:rest][:id].nil?
      render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_MISSING_FIELDS, 'id is missing')
      return
    end

    begin
      employee = Employee.find(params[:rest][:id])
      employee.update(employee_params)

      if !employee.valid?
        render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_MISSING_FIELDS, employee.errors.as_json.to_s)
        return
      end

      if employee.save
        render :json => ErrorResponse.new(employee.id)
      else
        render :json => ErrorResponse.new(employee.errorcode, employee.errors.to_s)
      end
    rescue RestError => e
      render :json => e.error
    rescue ActiveRecord::RecordNotFound
      render :json => ErrorResponse.new(ErrorCode::CANNOT_UPDATE_NONEXISTENT_RECORD, 'Record not found')
    rescue ActionController::UnpermittedParameters
      render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_UNKNOWN_FIELDS, 'Unknown fields')
    rescue => e
      render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, e.to_s)
    end
  end

  def set_password
    if !params.has_key?(:rest) or !params[:rest].has_key?(:username) or !params[:rest].has_key?(:password)
      render :json => ErrorResponse.new(ErrorCode::INVALID_USERNAME_OR_PASSWORD, 'Not authorized')
      return
    end

    params.require(:rest).permit(:username, :password)

    if params[:rest][:username] != @current_user.username and !@current_user.try(:can?, :set_password)
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized')
      return
    end

    begin
      employee = Employee.find_by_username(params[:rest][:username])
      if employee.nil?
        render :json => ErrorResponse.new(ErrorCode::INVALID_USERNAME_OR_PASSWORD, 'User not found' )
        return
      end
    rescue ActiveRecord::RecordNotFound
      render :json => ErrorResponse.new(ErrorCode::INVALID_USERNAME_OR_PASSWORD, 'User not found' )
      return
    end
    employee.password = params[:rest][:password]
    if !employee.save
      render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, employee.errors.to_s )
    else
      render :json => ErrorResponse.new(ErrorCode::NONE)
    end
  end

  def authenticate_employee
    employee = Employee.find_for_database_authentication(username: params[:username])
    if employee.nil?
      render :json => { jwt: nil,  errorcode: ErrorCode::INVALID_USERNAME_OR_PASSWORD, error: 'Invalid username or password' }
    elsif employee.valid_password?(params[:password])
      render json: jwt_token_response(employee)
    else
      render :json =>  { jwt: nil,  errorcode: ErrorCode::INVALID_USERNAME_OR_PASSWORD, error: 'Not authorized for operation' }
    end
  end

  protected

  def authenticate_employee!
    begin
      unless username_in_token?
        render :json => @error
        return
      end
    rescue RestError => e
      render :json => e.error
      return
    end

    @current_user = Employee.find_by_username(@auth_token["username"])

    if @current_user.nil?
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized for operation')
    end
  rescue JWT::VerificationError, JWT::DecodeError
    render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized for operation')
  end

  private

  def http_token
    if request.headers['Authorization'].present?
      @http_token = request.headers['Authorization'] #.split(' ').last
    else
      raise RestError.new(ErrorCode::NO_AUTHORIZATION_TOKEN, 'No authorization token')
    end
  end

  def auth_token
    @auth_token = JsonWebToken.decode(@http_token)
  rescue RestError => e
    raise e
  rescue => e
    raise RestError.new(ErrorCode::UNKNOWN_ERROR, e.to_s)
  end

  def username_in_token?
    http_token && auth_token && @auth_token['username']
  end

  def jwt_token_response(employee)
    return nil unless employee
    {
        jwt: JsonWebToken.encode(employee),
        errorcode: ErrorCode::NONE,
        error: nil
    }
  end

  def adjust_parameters
    adjust_ids if params[:action] != 'set_password' and params[:action] != 'login'
  end

  def adjust_ids
    if params[:rest].has_key?(:_id)
      params[:rest][:id] = params[:rest][:_id]
      params[:rest].delete(:_id)
    end

    if params.has_key?(:_id)
      params[:id] = params[:_id]
      params.delete(:id)
    end

    [:username, :firstName, :middleInitial, :lastName, :dateOfBirth, :dateOfEmployment, :bStatus].each do |key|
      params[:rest][key] = nil if !params[:rest].has_key?(key)

    end
  end

  def employee_params
    if @current_user.try(:can?, :set_password)
      params.require(:rest).permit(:id, :username,
                                   :firstName, :middleInitial, :lastName,
                                   :dateOfBirth,
                                   :dateOfEmployment,
                                   :bStatus, :email, :password, :employee_roles)
    else
      params.require(:rest).permit(:id, :username,
                                   :firstName, :middleInitial, :lastName,
                                   :dateOfBirth,
                                   :dateOfEmployment,
                                   :bStatus, :email)
    end
  end

end
