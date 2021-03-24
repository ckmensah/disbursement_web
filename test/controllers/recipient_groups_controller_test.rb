require 'test_helper'

class RecipientGroupsControllerTest < ActionController::TestCase
  setup do
    @recipient_group = recipient_groups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:recipient_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create recipient_group" do
    assert_difference('RecipientGroup.count') do
      post :create, recipient_group: { approver_cat_id: @recipient_group.approver_cat_id, approver_code: @recipient_group.approver_code, client_code: @recipient_group.client_code, group_desc: @recipient_group.group_desc, status: @recipient_group.status }
    end

    assert_redirected_to recipient_group_path(assigns(:recipient_group))
  end

  test "should show recipient_group" do
    get :show, id: @recipient_group
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @recipient_group
    assert_response :success
  end

  test "should update recipient_group" do
    patch :update, id: @recipient_group, recipient_group: { approver_cat_id: @recipient_group.approver_cat_id, approver_code: @recipient_group.approver_code, client_code: @recipient_group.client_code, group_desc: @recipient_group.group_desc, status: @recipient_group.status }
    assert_redirected_to recipient_group_path(assigns(:recipient_group))
  end

  test "should destroy recipient_group" do
    assert_difference('RecipientGroup.count', -1) do
      delete :destroy, id: @recipient_group
    end

    assert_redirected_to recipient_groups_path
  end
end
