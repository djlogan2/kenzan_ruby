class Employee < ApplicationRecord
  has_many :employee_to_roles
  has_many :employee_roles, :through => :employee_to_roles
  validates :username, presence: true
  validates :bStatus, presence: true
  validates :firstName, presence: true
  validates :lastName, presence: true
  validates :dateOfBirth, presence: true

  def self.default_scope
    where(:bStatus => EmployeeStatus::ACTIVE) #.select([:id, :username, :firstName, :middleInitial, :lastName, :dateOfBirth, :dateOfEmployment])
  end
end
