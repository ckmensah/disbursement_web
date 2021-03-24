class CreateApprovers < ActiveRecord::Migration
  def change
    create_table :approvers do |t|
      t.integer :user_id
      t.integer :category_id
      t.boolean :status
      t.boolean :changed_status
      t.string :approver_code
      t.integer :user_approver_id

      t.timestamps null: false
    end
  end
end
