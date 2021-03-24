require 'test_helper'

class TransMastersControllerTest < ActionController::TestCase
  setup do
    @trans_master = trans_masters(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trans_masters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trans_master" do
    assert_difference('TransMaster.count') do
      post :create, trans_master: { final_status: @trans_master.final_status, is_reversal: @trans_master.is_reversal, main_trans_id: @trans_master.main_trans_id }
    end

    assert_redirected_to trans_master_path(assigns(:trans_master))
  end

  test "should show trans_master" do
    get :show, id: @trans_master
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trans_master
    assert_response :success
  end

  test "should update trans_master" do
    patch :update, id: @trans_master, trans_master: { final_status: @trans_master.final_status, is_reversal: @trans_master.is_reversal, main_trans_id: @trans_master.main_trans_id }
    assert_redirected_to trans_master_path(assigns(:trans_master))
  end

  test "should destroy trans_master" do
    assert_difference('TransMaster.count', -1) do
      delete :destroy, id: @trans_master
    end

    assert_redirected_to trans_masters_path
  end
end
