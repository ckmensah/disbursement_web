class CreateCallbackResps < ActiveRecord::Migration
  def change
    create_table :callback_resps do |t|
      t.string :trnx_id
      t.string :mm_trnx_id
      t.string :mobile_number
      t.string :resp_code
      t.string :network
      t.boolean :status
      t.string :resp_desc

      t.timestamps null: false
    end
  end
end
