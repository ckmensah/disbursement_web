json.extract! user, :id, :email, :username, :role_id, :lastname, :other_names, :mobile_number, :client_code, :active_status, :created_at, :updated_at
json.url user_url(user, format: :json)
