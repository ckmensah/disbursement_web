require 'test_helper'

class PayoutApprovalsControllerTest < ActionController::TestCase
  setup do
    @payout_approval = payout_approvals(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:payout_approvals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create payout_approval" do
    assert_difference('PayoutApproval.count') do
      post :create, payout_approval: { approved: @payout_approval.approved, approver_code: @payout_approval.approver_code, level: @payout_approval.level, notified: @payout_approval.notified, payout_id: @payout_approval.payout_id, status: @payout_approval.status }
    end

    assert_redirected_to payout_approval_path(assigns(:payout_approval))
  end

  test "should show payout_approval" do
    get :show, id: @payout_approval
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @payout_approval
    assert_response :success
  end

  test "should update payout_approval" do
    patch :update, id: @payout_approval, payout_approval: { approved: @payout_approval.approved, approver_code: @payout_approval.approver_code, level: @payout_approval.level, notified: @payout_approval.notified, payout_id: @payout_approval.payout_id, status: @payout_approval.status }
    assert_redirected_to payout_approval_path(assigns(:payout_approval))
  end

  test "should destroy payout_approval" do
    assert_difference('PayoutApproval.count', -1) do
      delete :destroy, id: @payout_approval
    end

    assert_redirected_to payout_approvals_path
  end
end
