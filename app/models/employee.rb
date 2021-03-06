require('employee_status')

class Employee < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  has_many :employee_to_roles
  has_many :employee_roles, :through => :employee_to_roles
  validates :username, presence: true
  validates :bStatus, presence: true
  validates :firstName, presence: true
  validates :lastName, presence: true
  validates :dateOfBirth, presence: true

  def as_json(options)
    return {
        id: id,
        bStatus: (bStatus == EmployeeStatus::ACTIVE ? 'ACTIVE' : 'INACTIVE'),
        username: username,
        firstName: firstName,
        middleInitial: middleInitial,
        lastName: lastName,
        dateOfBirth: dateOfBirth.to_date,
        dateOfEmployment: (dateOfEmployment.nil? ? nil : dateOfEmployment.to_date),
        email: email
    }
  end

  def hasEmploymentDate
    !dateOfEmployment.to_s.empty?
  end

#  def hasEmploymentDate=(hed)
#    if hed == false || hed == 0
#      dateOfBirth = nil
#    else
#      if dateOfBirth.to_s.empty?
#        dateOfBirth = Date.now
#      end
#    end
#  end

  def can? do_what
    case do_what
      when :add
        employee_roles.pluck(:role).include?('ROLE_ADD_EMP')
      when :delete
        employee_roles.pluck(:role).include?('ROLE_DELETE_EMP')
      when :update
        employee_roles.pluck(:role).include?('ROLE_UPDATE_EMP')
      when :set_password
        employee_roles.pluck(:role).include?('ROLE_SET_PASSWORD')
      else
        false
    end
  end

  def will_save_change_to_email?
    false
  end

  def self.default_scope
    where(:bStatus => EmployeeStatus::ACTIVE)
  end
end
