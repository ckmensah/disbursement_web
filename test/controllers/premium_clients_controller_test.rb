require 'test_helper'

class PremiumClientsControllerTest < ActionController::TestCase
  setup do
    @premium_client = premium_clients(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:premium_clients)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create premium_client" do
    assert_difference('PremiumClient.count') do
      post :create, premium_client: { client_code: @premium_client.client_code, client_id: @premium_client.client_id, client_key: @premium_client.client_key, company_name: @premium_client.company_name, contact_number: @premium_client.contact_number, email: @premium_client.email, secret_key: @premium_client.secret_key }
    end

    assert_redirected_to premium_client_path(assigns(:premium_client))
  end

  test "should show premium_client" do
    get :show, id: @premium_client
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @premium_client
    assert_response :success
  end

  test "should update premium_client" do
    patch :update, id: @premium_client, premium_client: { client_code: @premium_client.client_code, client_id: @premium_client.client_id, client_key: @premium_client.client_key, company_name: @premium_client.company_name, contact_number: @premium_client.contact_number, email: @premium_client.email, secret_key: @premium_client.secret_key }
    assert_redirected_to premium_client_path(assigns(:premium_client))
  end

  test "should destroy premium_client" do
    assert_difference('PremiumClient.count', -1) do
      delete :destroy, id: @premium_client
    end

    assert_redirected_to premium_clients_path
  end
end
