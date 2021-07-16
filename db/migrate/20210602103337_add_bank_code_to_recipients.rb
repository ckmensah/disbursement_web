class AddBankCodeToRecipients < ActiveRecord::Migration[5.2]
  def change
    add_column :recipients, :bank_code, :string
  end
end
