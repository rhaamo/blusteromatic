require 'test_helper'

class NodesControllerTest < ActionController::TestCase
  test "should get activate" do
    get :activate
    assert_response :success
  end

  test "should get deactivate" do
    get :deactivate
    assert_response :success
  end

  test "should get pause" do
    get :pause
    assert_response :success
  end

end
