require 'test_helper'

class UsersHelperTest < ActionView::TestCase

  test 'relative_due_date - date today' do
    due_date = relative_due_date(Date.today)
    assert_equal(due_date, "today")
  end

  test 'relative_due_date - time today' do
    due_date = relative_due_date(Time.now)
    assert_match /hour/, due_date
  end

  test 'relative_due_date - date tomorrow' do
    due_date = relative_due_date(Date.today + 1)
    assert_equal(due_date, "tomorrow")
  end

  test 'relative_due_date - week out' do
    due_date = relative_due_date(Date.today + 1.week)
    assert_equal(due_date, "7 days")
  end
end
