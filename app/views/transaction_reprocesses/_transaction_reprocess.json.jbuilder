json.extract! transaction_reprocess, :id, :old_trnx_id, :new_trnx_id, :amount, :status, :auto, :err_code, :user_id, :nw_resp, :created_at, :updated_at
json.url transaction_reprocess_url(transaction_reprocess, format: :json)
