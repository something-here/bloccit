class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :post
  after_save :update_post

  validates :value, inclusion: { in: [-1, 1], message: "%{value} is not a valid vote." }, presence: true

  include StreamRails::Activity
  as_activity

  def activity_should_sync?
    self.post.topic.nil?
  end

  def activity_notify
    if self.value == 1
      [StreamRails.feed_manager.get_notification_feed(self.post.user_id)]
    end
  end

  def activity_object
    self
  end

  after_create do
    self.user.like(self.post)
  end

  after_update do
    self.value == -1 ? self.user.unlike(self.post) : self.user.like(self.post)
  end

  before_destroy do
    feed = StreamRails.feed_manager.get_user_feed(self.user.id)
    feed.remove_activity("Vote:#{self.id}", foreign_id=true)
  end

  private

  def update_post
    post.update_rank
  end
end
