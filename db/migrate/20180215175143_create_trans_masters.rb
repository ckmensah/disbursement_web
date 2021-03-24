class CreateTransMasters < ActiveRecord::Migration
  def change
    create_table :trans_masters do |t|
      t.string :main_trans_id
      t.boolean :final_status
      t.boolean :is_reversal

      t.timestamps null: false
    end
  end
end
