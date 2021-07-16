class AddSortCodeToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :sort_code, :string
  end
end
