class CreatePremiumClients < ActiveRecord::Migration
  def change
    create_table :premium_clients do |t|
      t.string :company_name
      t.string :client_code
      t.string :email
      t.string :contact_number
      t.string :client_id
      t.string :client_key
      t.string :secret_key

      t.timestamps null: false
    end
  end
end
