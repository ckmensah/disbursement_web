class CreateTransactionReprocesses < ActiveRecord::Migration
  def change
    create_table :transaction_reprocesses do |t|
      t.string :old_trnx_id
      t.string :new_trnx_id
      t.decimal :amount
      t.boolean :status
      t.boolean :auto
      t.string :err_code
      t.integer :user_id
      t.string :nw_resp

      t.timestamps null: false
    end
  end
end
