require 'test_helper'
require 'ostruct'

class SfxServicePresenterTest < ActiveSupport::TestCase
    def setup
        @service_type = 'getFullTxt'
        @service_type_abstract = 'getAbstract'
        @service_type_toc = 'getTOC'
    end

    test 'that we can translate SFX service codes to human-readable text' do
        assert_equal SfxServicePresenter.new(service_type: @service_type).service, 'Full text available from '
        assert_equal SfxServicePresenter.new(service_type: @service_type_abstract).service, 'Abstract available from '
        assert_equal SfxServicePresenter.new(service_type: @service_type_toc).service, 'Table of contents available from '
    end
end
