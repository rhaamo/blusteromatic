require 'test_helper'

class Api::NodeControllerTest < ActionController::TestCase
  test "should get heartbeat" do
    get :heartbeat
    assert_response :success
  end

  test "should get get_jobs" do
    get :get_jobs
    assert_response :success
  end

  test "should get assign_job" do
    get :assign_job
    assert_response :success
  end

  test "should get update_job" do
    get :update_job
    assert_response :success
  end

  test "should get finish_job" do
    get :finish_job
    assert_response :success
  end

end
