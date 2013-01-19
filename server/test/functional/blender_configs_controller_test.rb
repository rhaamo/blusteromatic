require 'test_helper'

class BlenderConfigsControllerTest < ActionController::TestCase
  setup do
    @blender_config = blender_configs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:blender_configs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create blender_config" do
    assert_difference('BlenderConfig.count') do
      post :create, blender_config: { description: @blender_config.description, name: @blender_config.name }
    end

    assert_redirected_to blender_config_path(assigns(:blender_config))
  end

  test "should show blender_config" do
    get :show, id: @blender_config
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @blender_config
    assert_response :success
  end

  test "should update blender_config" do
    put :update, id: @blender_config, blender_config: { description: @blender_config.description, name: @blender_config.name }
    assert_redirected_to blender_config_path(assigns(:blender_config))
  end

  test "should destroy blender_config" do
    assert_difference('BlenderConfig.count', -1) do
      delete :destroy, id: @blender_config
    end

    assert_redirected_to blender_configs_path
  end
end
