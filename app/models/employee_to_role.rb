class EmployeeToRole < ApplicationRecord
  belongs_to :employee
  belongs_to :employee_role
end
