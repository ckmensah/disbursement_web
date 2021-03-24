class CreateCsvUploads < ActiveRecord::Migration
  def change
    create_table :csv_uploads do |t|
      t.integer :user_id
      t.string :client_code
      t.string :file_name
      t.string :file_path


      t.timestamps null: false
    end
  end
end
