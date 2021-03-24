class CreatePayoutApprovals < ActiveRecord::Migration
  def change
    create_table :payout_approvals do |t|
      t.integer :payout_id
      t.string :approver_code
      t.boolean :approved
      t.boolean :status
      t.boolean :notified
      t.integer :level

      t.timestamps null: false
    end
  end
end
