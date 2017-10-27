class AddRecords < ActiveRecord::Migration[5.1]
  def change
    EmployeeRole.create role: 'ROLE_ADD_EMP'
    EmployeeRole.create role: 'ROLE_UPDATE_EMP'
    EmployeeRole.create role: 'ROLE_DELETE_EMP'
    EmployeeRole.create role: 'ROLE_SET_PASSWORD'

    Employee.create username: 'kenzan',    firstName: 'Kenzan', middleInitial: 'A', lastName: 'Test',     dateOfBirth: '1968-11-26', dateOfEmployment: '2001-01-01', bStatus: 0
    Employee.create username: 'kenzana',   firstName: 'Kenzan', middleInitial: 'B', lastName: 'Test A',   dateOfBirth: '1968-11-27', dateOfEmployment: '2001-02-02', bStatus: 0
    Employee.create username: 'kenzanad',  firstName: 'Kenzan', middleInitial: 'C', lastName: 'Test AD',  dateOfBirth: '1968-11-28', dateOfEmployment: '2001-03-03', bStatus: 0
    Employee.create username: 'kenzanau',  firstName: 'Kenzan', middleInitial: 'D', lastName: 'Test AU',  dateOfBirth: '1968-11-29', dateOfEmployment: '2001-04-04', bStatus: 0
    Employee.create username: 'kenzanadu', firstName: 'Kenzan', middleInitial: 'E', lastName: 'Test ADU', dateOfBirth: '1968-11-30', dateOfEmployment: '2001-05-05', bStatus: 0
    Employee.create username: 'kenzand',   firstName: 'Kenzan', middleInitial: 'F', lastName: 'Test D',   dateOfBirth: '1968-12-01', dateOfEmployment: '2001-06-06', bStatus: 0
    Employee.create username: 'kenzandu',  firstName: 'Kenzan', middleInitial: 'G', lastName: 'Test DU',  dateOfBirth: '1968-12-02', dateOfEmployment: '2001-07-07', bStatus: 0
    Employee.create username: 'kenzanu',   firstName: 'Kenzan', middleInitial: 'H', lastName: 'Test U',   dateOfBirth: '1968-12-03', dateOfEmployment: '2001-08-08', bStatus: 0
    Employee.create username: 'kenzanp',   firstName: 'Kenzan', middleInitial: 'I', lastName: 'Test P',   dateOfBirth: '1968-12-04', dateOfEmployment: '2001-09-09', bStatus: 0

    [%w[%a% ROLE_ADD_EMP],%w[%u% ROLE_UPDATE_EMP],%w[%d% ROLE_DELETE_EMP],%w[%p% ROLE_SET_PASSWORD]].each do |pattern, role|
      employees = Employee.where("username like 'kenzan" + pattern + "' OR username='kenzanp'")
      employees.each do |employee|
        employee.employee_roles.push(EmployeeRole.find_by_role(role))
        employee.save
      end
    end
  end
end
