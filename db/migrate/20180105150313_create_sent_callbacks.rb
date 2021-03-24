class CreateSentCallbacks < ActiveRecord::Migration
  def change
    create_table :sent_callbacks do |t|
      t.string :trnx_id
      t.string :trnx_type
      t.decimal :amount
      t.string :network
      t.boolean :status
      t.boolean :is_reversal
      t.string :mobile_number
      t.string :merchant_number

      t.timestamps null: false
    end
  end
end
