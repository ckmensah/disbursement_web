class CreateRecipientGroups < ActiveRecord::Migration
  def change
    create_table :recipient_groups do |t|
      t.string :group_desc
      t.string :client_code
      t.string :approver_code
      t.boolean :status
      t.integer :approver_cat_id

      t.timestamps null: false
    end
  end
end
