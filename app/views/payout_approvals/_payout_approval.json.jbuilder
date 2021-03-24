json.extract! payout_approval, :id, :payout_id, :approver_code, :approved, :status, :notified, :level, :created_at, :updated_at
json.url payout_approval_url(payout_approval, format: :json)
