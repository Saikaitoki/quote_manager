require "test_helper"

class QouteControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get qoute_new_url
    assert_response :success
  end
end
