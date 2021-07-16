class AddBankCodeToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :bank_code, :string
  end
end
