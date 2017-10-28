class AddRecords < ActiveRecord::Migration[5.1]
  def change

    EmployeeRole.create role: 'ROLE_ADD_EMP'
    EmployeeRole.create role: 'ROLE_UPDATE_EMP'
    EmployeeRole.create role: 'ROLE_DELETE_EMP'
    EmployeeRole.create role: 'ROLE_SET_PASSWORD'

    ['', 'a', 'ad', 'au', 'adu', 'd', 'du', 'u', 'p'].each do |suffix|
      e = Employee.new
      e.username = 'kenzan' + suffix
      e.firstName = 'Kenzan'
      e.middleInitial = 'M'
      e.lastName = 'Test ' + suffix
      e.dateOfBirth = '1968-11-26'
      e.dateOfEmployment = '2001-01-01'
      e.email = 'kenzan@gmail.com'
      e.password = 'kenzan'
      e.save!
    end

    [%w[%a% ROLE_ADD_EMP],%w[%u% ROLE_UPDATE_EMP],%w[%d% ROLE_DELETE_EMP],%w[%p% ROLE_SET_PASSWORD]].each do |pattern, role|
      employees = Employee.where("username like 'kenzan" + pattern + "' OR username='kenzanp'")
      employees.each do |employee|
        employee.employee_roles.push(EmployeeRole.find_by_role(role))
        employee.save
      end
    end
  end
end
