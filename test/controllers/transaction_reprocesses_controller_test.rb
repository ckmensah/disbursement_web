require 'test_helper'

class TransactionReprocessesControllerTest < ActionController::TestCase
  setup do
    @transaction_reprocess = transaction_reprocesses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:transaction_reprocesses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create transaction_reprocess" do
    assert_difference('TransactionReprocess.count') do
      post :create, transaction_reprocess: { amount: @transaction_reprocess.amount, auto: @transaction_reprocess.auto, err_code: @transaction_reprocess.err_code, new_trnx_id: @transaction_reprocess.new_trnx_id, nw_resp: @transaction_reprocess.nw_resp, old_trnx_id: @transaction_reprocess.old_trnx_id, status: @transaction_reprocess.status, user_id: @transaction_reprocess.user_id }
    end

    assert_redirected_to transaction_reprocess_path(assigns(:transaction_reprocess))
  end

  test "should show transaction_reprocess" do
    get :show, id: @transaction_reprocess
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @transaction_reprocess
    assert_response :success
  end

  test "should update transaction_reprocess" do
    patch :update, id: @transaction_reprocess, transaction_reprocess: { amount: @transaction_reprocess.amount, auto: @transaction_reprocess.auto, err_code: @transaction_reprocess.err_code, new_trnx_id: @transaction_reprocess.new_trnx_id, nw_resp: @transaction_reprocess.nw_resp, old_trnx_id: @transaction_reprocess.old_trnx_id, status: @transaction_reprocess.status, user_id: @transaction_reprocess.user_id }
    assert_redirected_to transaction_reprocess_path(assigns(:transaction_reprocess))
  end

  test "should destroy transaction_reprocess" do
    assert_difference('TransactionReprocess.count', -1) do
      delete :destroy, id: @transaction_reprocess
    end

    assert_redirected_to transaction_reprocesses_path
  end
end
