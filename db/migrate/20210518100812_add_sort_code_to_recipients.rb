class AddSortCodeToRecipients < ActiveRecord::Migration[5.2]
  def change
    add_column :recipients, :sort_code, :string
  end
end
