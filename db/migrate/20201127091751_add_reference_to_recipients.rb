class AddReferenceToRecipients < ActiveRecord::Migration[5.2]
  def change
    add_column :recipients, :reference, :string
  end
end
