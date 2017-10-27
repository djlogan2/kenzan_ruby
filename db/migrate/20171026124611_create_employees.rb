class CreateEmployees < ActiveRecord::Migration[5.1]
  def change
    create_table :employees do |t|
      t.string :username, null: false
      t.string :firstName, null: false
      t.string :middleInitial
      t.string :lastName, null: false
      t.string :password
      t.integer :bStatus, null: false
      t.date :dateOfBirth, null: false
      t.date :dateOfEmployment
      t.timestamps
    end
    execute <<-SQL
      CREATE TRIGGER VerifyEmployeeInsert BEFORE INSERT ON employees
        FOR EACH ROW
          BEGIN
            IF (SELECT COUNT(1) FROM employees WHERE employees.username = NEW.username AND employees.bStatus = 0) > 0 THEN
              SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Unable to insert duplicate username';
            END IF;
          END;
    SQL
    execute <<-SQL
      CREATE TRIGGER VerifyEmployeeUpdate BEFORE UPDATE ON employees
      FOR EACH ROW
      BEGIN
        IF OLD.bStatus = 0 THEN
          BEGIN
            IF (SELECT COUNT(1) FROM employees WHERE OLD.username = employees.username AND employees.id <> OLD.id and employees.bStatus = 0) > 0 THEN
              SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Unable to insert duplicate username';
            END IF;
          END;
        END IF;
      END;
    SQL

  end
end
