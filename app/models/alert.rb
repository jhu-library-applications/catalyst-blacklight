class Alert < ApplicationRecord
  scope :active, -> { where("start_at < ?", Time.now).where("end_at > ?",  Time.now) }
end
