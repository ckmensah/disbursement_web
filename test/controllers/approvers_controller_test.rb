require 'test_helper'

class ApproversControllerTest < ActionController::TestCase
  setup do
    @approver = approvers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:approvers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create approver" do
    assert_difference('Approver.count') do
      post :create, approver: { approver_code: @approver.approver_code, category_id: @approver.category_id, changed_status: @approver.changed_status, status: @approver.status, user_approver_id: @approver.user_approver_id, user_id: @approver.user_id }
    end

    assert_redirected_to approver_path(assigns(:approver))
  end

  test "should show approver" do
    get :show, id: @approver
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @approver
    assert_response :success
  end

  test "should update approver" do
    patch :update, id: @approver, approver: { approver_code: @approver.approver_code, category_id: @approver.category_id, changed_status: @approver.changed_status, status: @approver.status, user_approver_id: @approver.user_approver_id, user_id: @approver.user_id }
    assert_redirected_to approver_path(assigns(:approver))
  end

  test "should destroy approver" do
    assert_difference('Approver.count', -1) do
      delete :destroy, id: @approver
    end

    assert_redirected_to approvers_path
  end
end
