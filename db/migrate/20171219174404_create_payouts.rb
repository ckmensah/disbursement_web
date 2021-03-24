class CreatePayouts < ActiveRecord::Migration
  def change
    create_table :payouts do |t|
      t.string :title
      t.boolean :approval_status
      t.string :approver_cat_id
      t.text :comment
      t.boolean :processed
      t.integer :group_id
      t.boolean :needs_approval
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
