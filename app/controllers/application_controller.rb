class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_employee!
  protect_from_forgery with: :exception

  protected

  def configure_permitted_parameters
    added_attrs = [:username, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    #devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end

  def employee_params
    if current_user.try(:can?, :set_password)
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

  def current_user
    request.env['warden'].user
  end

end
