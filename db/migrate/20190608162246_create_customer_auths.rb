class CreateCustomerAuths < ActiveRecord::Migration
  def change
    create_table :customer_auths do |t|
      t.string :auth_code
      t.string :status
      t.string :customer_number


      t.timestamps null: false
    end
  end
end
