class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :username
      t.integer :role_id
      t.string :lastname
      t.string :other_names
      t.string :mobile_number
      t.string :client_code
      t.boolean :active_status

      t.timestamps null: false
    end
  end
end
