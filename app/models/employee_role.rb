class EmployeeRole < ApplicationRecord
  has_many :employee_to_roles
  has_many :employees, :through => :employee_to_roles
  validates :role, presence: true
end
