json.extract! approver, :id, :user_id, :category_id, :status, :changed_status, :approver_code, :user_approver_id, :created_at, :updated_at
json.url approver_url(approver, format: :json)
