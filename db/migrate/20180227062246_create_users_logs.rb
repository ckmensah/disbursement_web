class CreateUsersLogs < ActiveRecord::Migration
  def change
    create_table :users_logs do |t|
      t.integer :idd
      t.string :email
      t.string :username
      t.integer :role_id
      t.string :lastname
      t.string :other_names
      t.string :mobile_number
      t.string :client_code
      t.boolean :active_status
      t.timestamp :old_created_at
      t.string :encrypted_password
      t.string :reset_password_token
      t.timestamp :reset_sent_at
      t.timestamp :remember_created_at
      t.integer :sign_in_count
      t.timestamp :current_user_sign_in_at
      t.timestamp :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.integer :creator_id
      t.boolean :status
      t.boolean :save_status
      t.integer :user_idd

      t.timestamps null: false
    end
  end
end
