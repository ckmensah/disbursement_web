class CreateRecipients < ActiveRecord::Migration
  def change
    create_table :recipients do |t|
      t.string :mobile_number
      t.string :network
      t.decimal :amount
      t.integer :group_id
      t.boolean :status
      t.boolean :changed_status
      t.boolean :disburse_status
      t.string :transaction_id
      t.string :client_code
      t.text :fail_reason
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
