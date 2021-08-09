class Alert < ApplicationRecord

  validates :alert_type, :level, presence: true

  scope :active, -> { where("start_at < ?", Time.now).where("end_at > ?",  Time.now) }
end
