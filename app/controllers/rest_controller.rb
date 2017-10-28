class RestController < ApplicationController

  def get_all
    employees = Employee.all
    render :json => employees
  end

  def get_emp
    employee = Employee.find(params[:id])
    render :json => employee
  end

  def delete_emp
    employee = Employee.find(params[:id])
    employee.delete
    render :json => ErrorResponse.new(employee.id )
  end

  def login
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'not implemeneted' )
  end

  def add_emp
    employee = Employee.new(employee_params)
    employee.password = SecureRandom.hex
    employee.email = 'none@none.non'

    if employee.save
      render :json => ErrorResponse.new(employee.id )
    else
      render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'not implemeneted' )
    end
  end

  def update_emp
    updates = Employee.new(employee_params)
    employee = Employee.find(params[:id])
    employee.username = updates.username
    employee.firstName = updates.firstName
    employee.middleInitial = updates.middleInitial
    employee.lastName = updates.lastName
    employee.bStatus = updates.bStatus
    employee.dateOfBirth = updates.dateOfBirth
    employee.dateOfEmployment = updates.dateOfEmployment

    if employee.save
      render :json => ErrorResponse.new(employee.id )
    else
      render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'not implemeneted' )
    end

  end

  def set_password
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'not implemeneted' )
  end

end
