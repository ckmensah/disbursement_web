require 'test_helper'

class ApproversCategoriesControllerTest < ActionController::TestCase
  setup do
    @approvers_category = approvers_categories(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:approvers_categories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create approvers_category" do
    assert_difference('ApproversCategory.count') do
      post :create, approvers_category: { category_name: @approvers_category.category_name, changed_status: @approvers_category.changed_status, client_code: @approvers_category.client_code, status: @approvers_category.status, user_id: @approvers_category.user_id }
    end

    assert_redirected_to approvers_category_path(assigns(:approvers_category))
  end

  test "should show approvers_category" do
    get :show, id: @approvers_category
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @approvers_category
    assert_response :success
  end

  test "should update approvers_category" do
    patch :update, id: @approvers_category, approvers_category: { category_name: @approvers_category.category_name, changed_status: @approvers_category.changed_status, client_code: @approvers_category.client_code, status: @approvers_category.status, user_id: @approvers_category.user_id }
    assert_redirected_to approvers_category_path(assigns(:approvers_category))
  end

  test "should destroy approvers_category" do
    assert_difference('ApproversCategory.count', -1) do
      delete :destroy, id: @approvers_category
    end

    assert_redirected_to approvers_categories_path
  end
end
