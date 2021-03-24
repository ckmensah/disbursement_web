class CreateApproversCategories < ActiveRecord::Migration
  def change
    create_table :approvers_categories do |t|
      t.string :category_name
      t.string :client_code
      t.integer :user_id
      t.boolean :status
      t.boolean :changed_status

      t.timestamps null: false
    end
  end
end
