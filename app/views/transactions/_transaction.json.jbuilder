json.extract! transaction, :id, :mobile_number, :amount, :trans_type, :status, :network, :transaction_ref_id, :balance, :trnx_type, :err_code, :nw_resp, :user_id, :is_reversal, :voucher_code, :created_at, :updated_at
json.url transaction_url(transaction, format: :json)
