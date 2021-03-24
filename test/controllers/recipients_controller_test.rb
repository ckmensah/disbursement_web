require 'test_helper'

class RecipientsControllerTest < ActionController::TestCase
  setup do
    @recipient = recipients(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:recipients)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create recipient" do
    assert_difference('Recipient.count') do
      post :create, recipient: { amount: @recipient.amount, changed_status: @recipient.changed_status, disburse_status: @recipient.disburse_status, fail_reason: @recipient.fail_reason, group_id: @recipient.group_id, mobile_number: @recipient.mobile_number, network: @recipient.network, status: @recipient.status, transaction_id: @recipient.transaction_id, user_id: @recipient.user_id }
    end

    assert_redirected_to recipient_path(assigns(:recipient))
  end

  test "should show recipient" do
    get :show, id: @recipient
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @recipient
    assert_response :success
  end

  test "should update recipient" do
    patch :update, id: @recipient, recipient: { amount: @recipient.amount, changed_status: @recipient.changed_status, disburse_status: @recipient.disburse_status, fail_reason: @recipient.fail_reason, group_id: @recipient.group_id, mobile_number: @recipient.mobile_number, network: @recipient.network, status: @recipient.status, transaction_id: @recipient.transaction_id, user_id: @recipient.user_id }
    assert_redirected_to recipient_path(assigns(:recipient))
  end

  test "should destroy recipient" do
    assert_difference('Recipient.count', -1) do
      delete :destroy, id: @recipient
    end

    assert_redirected_to recipients_path
  end
end
