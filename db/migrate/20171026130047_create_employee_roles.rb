class CreateEmployeeRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :employee_roles do |t|
      t.string :role
      t.timestamps
    end

  end
end
