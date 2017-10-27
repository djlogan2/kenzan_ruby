class CreateEmployeeToRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :employee_to_roles do |t|
      t.references :employee, index: true
      t.references :employee_role, index: true
      t.timestamps
    end
    add_foreign_key :employee_to_roles, :employees
    add_foreign_key :employee_to_roles, :employee_roles
  end

end
