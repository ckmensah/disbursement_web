json.extract! recipient, :id, :mobile_number, :network, :amount, :group_id, :status, :changed_status, :created_at, :updated_at
json.url recipient_url(recipient, format: :json)
