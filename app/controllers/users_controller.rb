class UsersController < ApplicationController
  include UsersHelper
  before_action :authenticate_user!, only: [:following, :followers]

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.visible_to(current_user)
    @votes = @user.votes.where(value: 1)
    @comments = @user.comments
    @similar_raters = find_similar_users(@user.similar_raters)[0..2]
    @collection = single_collection(@posts, @votes, @comments)
  end

  def following
    @title = "Following"
    @user  = User.find(params[:id])
    @users = @user.following
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @user  = User.find(params[:id])
    @users = @user.followers
    render 'show_follow'
  end

  def subscriptions
    @title = "Subscriptions"
    @user  = User.find(params[:id])
    @subscriptions = @user.subscriptions
    render 'show_subscriptions'
  end

  def public
    if current_user.update_attributes(private: false)
      flash[:notice] = "Your account is visible to everyone."
      redirect_to current_user
    else
      flash[:alert] = "There was an error making your account public. Please try again."
      redirect_to current_user
    end
  end

  def private
    if current_user.update_attributes(private: true)
      flash[:notice] = "Your account is only visible to you and your followers."
      redirect_to current_user
    else
      flash[:alert] = "There was an error making your account private. Please try again."
      redirect_to current_user
    end
  end

  private

  def single_collection(posts, votes, comments)
    collection = []
    posts.map{ |post| collection << post }
    votes.map{ |vote| collection << vote }
    comments.map{ |comment| collection << comment }

    collection.sort_by do |collection|
      if collection.instance_of?(Post) || collection.instance_of?(Comment)
        collection.created_at
      else
        collection.updated_at
      end
    end.reverse
  end
end
