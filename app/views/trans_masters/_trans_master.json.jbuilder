json.extract! trans_master, :id, :main_trans_id, :final_status, :is_reversal, :created_at, :updated_at
json.url trans_master_url(trans_master, format: :json)
