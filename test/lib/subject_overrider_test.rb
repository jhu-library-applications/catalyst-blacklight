# This tests the SubjectOverrider's ability
# to override strings when given a YML config file
# that has a translation map
# like this:


# ---
# Override term: 'translated term'
require 'test_helper'
require 'ostruct'

class SubjectOverriderTest < ActiveSupport::TestCase

  def setup
    line = OpenStruct.new
    part = OpenStruct.new(formatted_value: 'Zzzzzzxyyyyyyy')
    @subject_overrider = SubjectOverrider.new(line: line, part: part)
  end

  test 'that we can get a translated term' do
    assert_equal @subject_overrider.translated_subject, 'Z'
  end
end
