require('error_response')
require('errorcode')
require('json_web_token')
require('rest_error')

class RestController < ApplicationController
  before_action :authenticate_employee!, :except => :login
  before_action :adjust_ids

  ActionController::Parameters.action_on_unpermitted_parameters = :raise

  rescue_from Exception do |e|
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, e.as_json )
  end

  rescue_from ActiveRecord::UnknownAttributeError do |uae|
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, uae.to_s )
  end

  rescue_from ActionController::UnpermittedParameters do |pme|
    render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_UNKNOWN_FIELDS, 'Unknown fields' )
  end

  def get_all
    employees = Employee.select(returned_employee_fields).all
    render :json => employees
  end

  def get_emp
    begin
      employee = Employee.select(returned_employee_fields).find(params[:id])
      render :json => employee
    rescue ActiveRecord::RecordNotFound
      render :json => nil #ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'Record not found' )
    end
  end

  def delete_emp
    if !current_user.try(:can?, :delete)
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized' )
      return
    end
    begin
      employee = Employee.find(params[:id])
      employee.bStatus = EmployeeStatus::INACTIVE
      employee.save
      #employee.delete
      render :json => ErrorResponse.new(employee.id )
    rescue ActiveRecord::RecordNotFound
      render :json => ErrorResponse.new(ErrorCode::CANNOT_DELETE_NONEXISTENT_RECORD, 'Record not found' )
    end

  end

  def login
    authenticate_employee
  end

  def add_emp
    if !current_user.try(:can?, :add)
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized' )
      return
    end

    if !params.has_key?(:bStatus)
      render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_MISSING_FIELDS, 'bStatus must be specified')
      return
    end

    employee = Employee.new employee_params

    if !current_user.try(:can?, :set_password) || employee.password.blank?
      employee.password = SecureRandom.hex
    end

    if employee.email.blank?
      employee.email = 'none@none.non'
    end

    begin
      if employee.save
        render :json => ErrorResponse.new(employee.id )
      else
        render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_MISSING_FIELDS, employee.errors.messages.to_s )
      end
    rescue ActiveRecord::StatementInvalid => e
      render :json => ErrorResponse.new(ErrorCode::DUPLICATE_RECORD, e.message )
    end
  end

  def update_emp
    if !current_user.try(:can?, :update)
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized' )
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
        render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_MISSING_FIELDS, employee.errors.as_json.to_s )
        return
      end

      if employee.save
        render :json => ErrorResponse.new(employee.id )
      else
        render :json => ErrorResponse.new(employee.errorcode, employee.errors.to_s )
      end
    rescue RestError => e
      render :json => e.error
    rescue ActiveRecord::RecordNotFound
      render :json => ErrorResponse.new(ErrorCode::CANNOT_UPDATE_NONEXISTENT_RECORD, 'Record not found' )
    rescue ActionController::UnpermittedParameters
      render :json => ErrorResponse.new(ErrorCode::CANNOT_INSERT_UNKNOWN_FIELDS, 'Unknown fields' )
    rescue => e
      render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, e.to_s )
    end
  end

  def set_password
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'not implemeneted' )
  end

  def authenticate_employee
    employee = Employee.find_for_database_authentication(username: params[:username])
    if employee.nil?
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized for operation' )
    elsif employee.valid_password?(params[:password])
      render json: payload(employee)
    else
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized for operation' )
    end
  end

  protected

  def authenticate_employee!
    begin
      unless employee_id_in_token?
        render :json => @error
        return
      end
    rescue RestError => e
      render :json => e.error
      return
    end

    @current_user = Employee.find(auth_token["employee_id"])
    if @current_user.nil?
      render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized for operation' )
    end
  rescue JWT::VerificationError, JWT::DecodeError
    render :json => ErrorResponse.new(ErrorCode::NOT_AUTHORIZED_FOR_OPERATION, 'Not authorized for operation' )
  end

  private

  def http_token
    raise RestError.new(ErrorCode::NO_AUTHORIZATION_TOKEN, 'No authorization token') unless request.headers['Authorization'].present?
    @http_token ||= if request.headers['Authorization'].present?
                      request.headers['Authorization'].split(' ').last
                    end
  end

  def auth_token
    @auth_token ||= JsonWebToken.decode(@http_token)[0]
  rescue RestError => e
    raise e
  rescue JWT::ExpiredSignature
    raise RestError.new(ErrorCode::INVALID_AUTHORIZATION_TOKEN_EXPIRED, 'Authorization token expired')
  rescue => e
    raise RestError.new(ErrorCode::UNKNOWN_ERROR, e.to_s)
  end

  def employee_id_in_token?
    http_token && auth_token && auth_token["employee_id"].to_i
  end

  def payload(employee)
    return nil unless employee and employee.id
    {
        jwt: JsonWebToken.encode(employee.id),
        errorcode: ErrorCode::NONE,
        error: nil
    }
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

    [:username, :firstName, :middleInitial, :lastName, :dateOfBirth, :dateOfEmployment, :bStatus].each do |key| params[:rest][key] = nil if !params[:rest].has_key?(key)

    end
  end

  def employee_params
    if current_user.try(:can?, :set_password)
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
