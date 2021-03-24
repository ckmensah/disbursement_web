require 'test_helper'

class NumberValidationsControllerTest < ActionController::TestCase
  setup do
    @number_validation = number_validations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:number_validations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create number_validation" do
    assert_difference('NumberValidation.count') do
      post :create, number_validation: { changed_status: @number_validation.changed_status, client_code: @number_validation.client_code, csv_upload_id: @number_validation.csv_upload_id, group_id: @number_validation.group_id, mobile_number: @number_validation.mobile_number, network: @number_validation.network, recipient_name: @number_validation.recipient_name, status: @number_validation.status, user_id: @number_validation.user_id }
    end

    assert_redirected_to number_validation_path(assigns(:number_validation))
  end

  test "should show number_validation" do
    get :show, id: @number_validation
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @number_validation
    assert_response :success
  end

  test "should update number_validation" do
    patch :update, id: @number_validation, number_validation: { changed_status: @number_validation.changed_status, client_code: @number_validation.client_code, csv_upload_id: @number_validation.csv_upload_id, group_id: @number_validation.group_id, mobile_number: @number_validation.mobile_number, network: @number_validation.network, recipient_name: @number_validation.recipient_name, status: @number_validation.status, user_id: @number_validation.user_id }
    assert_redirected_to number_validation_path(assigns(:number_validation))
  end

  test "should destroy number_validation" do
    assert_difference('NumberValidation.count', -1) do
      delete :destroy, id: @number_validation
    end

    assert_redirected_to number_validations_path
  end
end
