class CreateNumberValidations < ActiveRecord::Migration
  def change
    create_table :number_validations do |t|
      t.string :mobile_number
      t.string :network
      t.integer :group_id
      t.boolean :status
      t.boolean :changed_status
      t.integer :user_id
      t.string :recipient_name
      t.string :client_code
      t.string :csv_upload_id

      t.timestamps null: false
    end
  end
end
