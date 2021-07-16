class AddSwiftCodeToRecipients < ActiveRecord::Migration[5.2]
  def change
    add_column :recipients, :swift_code, :string
  end
end
