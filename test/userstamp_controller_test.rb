$:.unshift(File.dirname(__FILE__))

require 'helpers/functional_test_helper'
require 'controllers/userstamp_controller'
require 'controllers/users_controller'
require 'controllers/posts_controller'
require 'models/user'
require 'models/person'
require 'models/post'
require 'models/comment'

Rails.application.routes.draw do
  match ':controller((/:id)/:action)', via: [:get, :post]
end

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  fixtures :users, :people, :posts, :comments

  def test_update_post
    post url_for(controller: 'posts', action: 'update', id: 1), :params => {:post => {:title => 'Different'}, :session => {:person_id => 1}}
    assert_response :success
    assert_equal    'Different', assigns["post"].title
    assert_equal    @delynn, assigns["post"].updater
  end
end

class UsersControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :people, :posts, :comments

  def test_update_user
    post url_for(controller: 'users', action: 'update', id: 2), :params => {:user => {:name => 'Different'}, :session => {:user_id => 2}}
    assert_response :success
    assert_equal    'Different', assigns["user"].name
    assert_equal    @hera, assigns["user"].updater
  end
end
