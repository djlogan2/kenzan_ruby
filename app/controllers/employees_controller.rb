require('employee_status')

class EmployeesController < ApplicationController
  before_action :authenticate_employee!
  protect_from_forgery with: :exception

  def fuckme
    authenticate_employee!
  end

  def index;
    @employees = Employee.all
  end

  def create
    if !current_employee.try(:can?, :add)
      @messages = 'Not authorized to add an employee'
      @employees = index
      render :index
    end

    @employee = Employee.new(employee_params)
    @employee.bStatus = EmployeeStatus::ACTIVE

    if !current_employee.try(:can?, :set_password)
      @employee.password = SecureRandom.hex
    end

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
    if !current_employee.try(:can?, :add)
      @messages = 'Not authorized to add an employee'
      @employees = index
      render :index
    end
    @employee = Employee.new
  end

  def show;
    begin
      @employee = Employee.select(returned_employee_fields).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @messages = 'Invalid employee id'
      @employees = index
      render :index
    end
  end

  def edit;
    if !current_employee.try(:can?, :update)
      @messages = 'Not authorized to update an employee'
      @employees = index
      render :index
    end

    begin
      @employee = Employee.select(returned_employee_fields).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @messages = 'Invalid employee id'
      @employees = index
      render :index
    end
  end

  def update;
    if !current_employee.try(:can?, :update)
      @messages = 'Not authorized to update an employee'
      @employees = index
      render :index
    end

    p_employee = Employee.new(employee_params)

    begin
      @employee = Employee.select(returned_employee_fields).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @messages = 'Unable to find employee record'
      render :index
    end

    @employee.username = p_employee.username
    @employee.firstName = p_employee.firstName
    @employee.middleInitial = p_employee.middleInitial
    @employee.lastName = p_employee.lastName
    @employee.dateOfBirth = p_employee.dateOfBirth
    @employee.dateOfEmployment = p_employee.dateOfEmployment
    @employee.bStatus = p_employee.bStatus
    if current_employee.try(:can?, :set_password)
      @employee.password = p_employee.password
      @employee.employee_roles = EmployeeRole.where(:role => params[:newroles])
    end
    if @employee.save
      render :show
    else
      @messages = @employee.errors.full_messages
      render :edit
    end
  end

  def destroy
    if !current_employee.try(:can?, :delete)
      @messages = 'Not authorized to delete an employee'
      @employees = index
      render :index
    end

    begin
      employee = Employee.select(returned_employee_fields).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @messages = 'Employee record not found'
      render :index
    end

    employee.bStatus = EmployeeStatus::INACTIVE
    if employee.save
      @employees = index
      render :index
    else
      @messages = @employee.errors.full_messages
      render :edit
    end

  end

  protected

  def employee_params
    if current_employee.try(:can?, :set_password)
      params.require(:employee).permit(:id, :username,
                                       :firstName, :middleInitial, :lastName,
                                       :dateOfBirth,
                                       :dateOfEmployment,
                                       :bStatus, :email, :password, :employee_roles)
    else
      params.require(:employee).permit(:id, :username,
                                       :firstName, :middleInitial, :lastName,
                                       :dateOfBirth,
                                       :dateOfEmployment,
                                       :bStatus, :email)
    end
  end

end
