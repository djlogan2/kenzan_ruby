require('employee_status')

class EmployeesController < ApplicationController
  before_action :authenticate_employee!
  protect_from_forgery with: :exception

  def index;
    @employees = Employee.all
  end

  def create
    if !current_employee.try(:can?, :add)
      @messages = 'Not authorized to add an employee'
      @employees = index
      render :index
      return
    end

    @employee = Employee.new(employee_params)
    @employee.bStatus = EmployeeStatus::ACTIVE

    if !current_employee.try(:can?, :set_password)
      @employee.password = SecureRandom.hex
    else
      @employee.employee_roles = EmployeeRole.where(:role => params[:newroles])
    end

    begin
      if @employee.save
        redirect_to @employee
        return
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
      return
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
      return
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
      return
    end

    if params[:employee][:hasEmploymentDate].to_i == 0
      params[:employee][:dateOfEmployment] = nil
    else
      params[:employee][:dateOfEmployment] = params[:employee]['dateOfEmployment(1i)'] + '-' + params[:employee]['dateOfEmployment(2i)'] + '-' + params[:employee]['dateOfEmployment(3i)']
    end
    params[:employee][:dateOfBirth] = params[:employee]['dateOfBirth(1i)'] + '-' + params[:employee]['dateOfBirth(2i)'] + '-' + params[:employee]['dateOfBirth(3i)']
    params[:employee].delete(:hasEmploymentDate)
    params[:employee].delete('dateOfBirth(1i)')
    params[:employee].delete('dateOfBirth(2i)')
    params[:employee].delete('dateOfBirth(3i)')
    params[:employee].delete('dateOfEmployment(1i)')
    params[:employee].delete('dateOfEmployment(2i)')
    params[:employee].delete('dateOfEmployment(3i)')

    p_employee = Employee.new(employee_params)

    begin
      @employee = Employee.select(returned_employee_fields).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @messages = 'Unable to find employee record'
      render :index
      return
    end

    @employee.username = p_employee.username
    @employee.email = p_employee.email
    @employee.firstName = p_employee.firstName
    @employee.middleInitial = p_employee.middleInitial
    @employee.lastName = p_employee.lastName
    @employee.dateOfBirth = p_employee.dateOfBirth
    @employee.dateOfEmployment = p_employee.dateOfEmployment
    @employee.bStatus = p_employee.bStatus
    if current_employee.try(:can?, :set_password)
      if !p_employee.password.to_s.empty?
        @employee.password = p_employee.password
      end
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
      return
    end

    begin
      employee = Employee.select(returned_employee_fields).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @messages = 'Employee record not found'
      render :index
      return
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
