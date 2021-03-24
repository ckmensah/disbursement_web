json.extract! payout, :id, :title, :approval_status, :approver_cat_id, :comment, :processed, :created_at, :updated_at
json.url payout_url(payout, format: :json)
