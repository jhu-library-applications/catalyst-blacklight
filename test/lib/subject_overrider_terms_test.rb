# This tests the SubjectOverriderTerm's ability
# to override strings when given a YML config file

require 'test_helper'
require 'ostruct'

class SubjectOverriderTermsTest < ActiveSupport::TestCase

  def setup
    terms = ['Zzzzzzxyyyyyyy']
    @subject_overrider_terms = SubjectOverriderTerms.new(terms: terms)
  end

  test 'that we can get a translated term' do
    assert_equal @subject_overrider_terms.translated_terms, ['Z']
  end

  test 'that we can get a clean string to use a key for the map' do
    assert_equal @subject_overrider_terms.term_as_key('"term"'), 'term'
  end
end
