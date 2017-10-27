class RestController < ApplicationController
  def employee_params
    params.require(:employee).permit(:username,
                                      :firstName, :middleInitial, :lastName,
                                      :dateOfBirth,
                                      :dateOfEmployment,
                                      :bStatus)
  end

  def get_all
    employees = Employee.where(:bStatus => 0)
    render :json => employees
  end

  def get_emp
    employee = Employee.where(:id => params[:id], :bStatus =>0)
    render :json => employee
  end

  def delete_emp
    employee = Employee.where(:id => params[:id], :bStatus =>0)
    employee.delete
    render :json => ErrorResponse.new(employee.id )
  end

  def login
    render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'not implemeneted' )
  end

  def add_emp
    employee = Employee.new(employee_params)
    if employee.save
      render :json => ErrorResponse.new(employee.id )
    else
      render :json => ErrorResponse.new(ErrorCode::UNKNOWN_ERROR, 'not implemeneted' )
    end
  end

  def update_emp
    updates = Employee.new(employee_params)
    employee = Employee.find_by_id_and_bStatus(params[:id], 0)
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
