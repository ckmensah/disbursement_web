class AddReferenceToCsvUploads < ActiveRecord::Migration[5.2]
  def change
    add_column :csv_uploads, :reference, :string, :limit => 255
  end
end
