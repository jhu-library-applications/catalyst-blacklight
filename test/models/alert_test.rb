require 'test_helper'

class AlertTest < ActiveSupport::TestCase
  test "valid alert" do
    alert = Alert.new(
      alert_type: 'banner',
      level: 'info',
      title: 'Alert Title',
      description: 'Alert description',
      url: '',
      start_at: Time.now - 15,
      end_at: Time.now + 15,
    )
    assert alert.valid?
  end

  test "invalid without alert_type" do
    alert = Alert.new(
      alert_type: '',
      level: 'info',
      title: 'Alert Title',
      description: 'Alert description',
      url: '',
      start_at: Time.now - 15,
      end_at: Time.now + 15,
    )
    assert alert.invalid?
  end

  test "invalid without level" do
    alert = Alert.new(
      alert_type: 'banner',
      level: '',
      title: 'Alert Title',
      description: 'Alert description',
      url: '',
      start_at: Time.now - 15,
      end_at: Time.now + 15,
    )
    assert alert.invalid?
  end
end
