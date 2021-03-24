Rails.application.routes.draw do
  resources :number_validations
  get '/transactions/all_trans_excel' => 'transactions#all_trans_excel', as: :all_trans_excel
  post 'recipients/selected_delete' => 'recipients#selected_delete', as: :selected_delete
  get '/recipients/delete_all' => 'recipients#delete_all', as: :delete_all
  get "/users/sign_up" => redirect("/users/sign_in")

  devise_for :users, controllers: {registrations: 'users/registrations', :passwords => 'passwords'}
  #post "/users" => 'users#create'


  delete '/users/:id' => 'users#destroy'
  get '/users' => 'users#index'
  get '/users/new' => 'users#new', :as => 'new_user'
  get '/users/:id/edit' => 'users#edit', :as => 'edit_user'
  get '/users/:id' => 'users#show', :as => 'user'
  post 'create_user' => 'users#create', as: :create_user
  #put '/users/:id' => 'users#update', :as => 'update_user'
  patch '/users/:id' => 'users#update', :as => 'update_user'

  get 'recipients/sample_csv' => 'recipients#sample_csv', as: :sample_csv
  post '/recipients/recipients_import' => 'recipients#recipients_import', as: :recipients_import
  get '/recipients/failed' => 'recipients#failed', as: :failed


  get '/payouts/disburse' => 'payouts#disburse', as: :disburse

  get '/payouts/set_approver_levels' => 'payouts#set_approver_levels', as: :set_approver_levels
  get '/payouts/:id/approve_payout' => 'payouts#approve_payout', as: :approve_payout

  post 'disburse_callback' => 'payouts#disburse_callback', as: :disburse_callback
  get 'payouts/payout_index' => 'payouts#payout_index', as: :payout_index
  get 'transactions/transaction_index' => 'transactions#transaction_index', as: :transaction_index
  get '/transactions/disburse_money' => 'transactions#disburse_money', as: :disburse_money


  get 'validate_index' => 'number_validations#validate_index', as: :validate_index
  get 'sample_csv_validation' => 'number_validations#sample_csv_validation', as: :sample_csv_validation
  # get 'number_validations/new' => 'number_validations#new'
  get 'validate_all_numbers' => 'number_validations#validate_all_numbers', as: :final_validation
  get 'delete_all' => 'number_validations#delete_all', as: :delete_numbers
  get 'validate_recipient_import' => 'number_validations#validate_recipient_import', as: :import_numbers


  # get 'number_validations/validate_recipient_import' => 'number_validations#validate_recipient_import', as: :validate_recipient_import
  # get '/transactions/disburse_money' => 'transactions#disburse_money', as: :disburse_money




  get 'transactions/edit_trans_recep/:id' => 'transactions#edit_trans_recep', as: :edit_trans_recep
  post 'transactions/update_trans_recep' => 'transactions#update_trans_recep', as: :update_trans_recep
  post 'transactions/new_disbursement' => 'transactions#new_disbursement', as: :new_disbursement
  post 'transactions/trans_recipients_import' => 'transactions#trans_recipients_import', as: :trans_recipients_import


  resources :recipients
  resources :payout_approvals
  resources :approvers_categories
  resources :approvers
  resources :premium_clients
  resources :recipient_groups

  resources :payouts
  resources :transactions
  root 'home#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
