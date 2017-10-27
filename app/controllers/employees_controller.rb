require('error_status')

class EmployeesController < ApplicationController
  def index;
    @employees = Employee.where(:bStatus => EmployeeStatus::ACTIVE)
  end

  def create
    @employee = Employee.new(employee_params)
    @employee.bStatus = EmployeeStatus::ACTIVE
    begin
      if @employee.save
        redirect_to @employee
      else
        @messages = @employee.errors.full_messages
        render :new
      end
    rescue ActiveRecord::StatementInvalid => e
      @messages = e.message
      render :new
    end
  end

  def new
    @employee = Employee.new
  end

  def show;
    @employee = Employee.find_by id: params[:id], bStatus: EmployeeStatus::ACTIVE
    if @employee == nil || !Employee.exists?(@employee.id)
      @messages = 'Invalid employee id'
      @employees = index
      render :index
    end
  end

  def edit;
    @employee = Employee.find_by id: params[:id], bStatus: EmployeeStatus::ACTIVE
    if @employee == nil || !Employee.exists?(@employee.id)
      @messages = 'Invalid employee id'
      @employees = index
      render :index
    end
  end

  def update;
    p_employee = Employee.new(employee_params)
    @employee = Employee.find(params[:id])
    @employee.username = p_employee.username
    @employee.firstName = p_employee.firstName
    @employee.middleInitial = p_employee.middleInitial
    @employee.lastName = p_employee.lastName
    @employee.dateOfBirth = p_employee.dateOfBirth
    @employee.dateOfEmployment = p_employee.dateOfEmployment
    @employee.bStatus = p_employee.bStatus
    @employee.employee_roles = EmployeeRole.where(:role => params[:newroles])
    if @employee.save
      render :show
    else
      @messages = @employee.errors.full_messages
      render :edit
    end
  end

  def destroy
    employee = Employee.find_by id: params[:id], bStatus: EmployeeStatus::ACTIVE
    employee.bStatus = EmployeeStatus::INACTIVE
    if employee.save
      @employees = index
      render :index
    else
      @messages = @employee.errors.full_messages
      render :edit
    end

  end

  def employee_params
    params.require(:employee).permit(:username,
                                      :firstName, :middleInitial, :lastName,
                                      :dateOfBirth,
                                      :dateOfEmployment,
                                      :bStatus)
  end
end
