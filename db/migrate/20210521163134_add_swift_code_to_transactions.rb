class AddSwiftCodeToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :swift_code, :string
  end
end
