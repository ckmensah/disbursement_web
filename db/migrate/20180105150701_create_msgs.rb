class CreateMsgs < ActiveRecord::Migration
  def change
    create_table :msgs do |t|
      t.string :msg_id
      t.string :phone_number
      t.text :msg
      t.string :resp_code
      t.string :resp_desc
      t.boolean :status

      t.timestamps null: false
    end
  end
end
