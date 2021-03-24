json.extract! recipient_group, :id, :group_desc, :client_code, :approver_code, :status, :created_at, :updated_at
json.url recipient_group_url(recipient_group, format: :json)
