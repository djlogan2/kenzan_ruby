class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    added_attrs = [:username, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
  end

  def returned_employee_fields
    if current_employee.try(:can?, :set_password)
      return :id, :username, :firstName, :middleInitial, :lastName, :dateOfBirth, :dateOfEmployment, :bStatus, :email, :encrypted_password
    else
      return :id, :username, :firstName, :middleInitial, :lastName, :dateOfBirth, :dateOfEmployment, :bStatus, :email
    end
  end

end
