class SfxServicePresenter
  SERVICE_MAP = {
    'getFullTxt' => 'Full text available from ',
    'getTOC' => 'Table of contents available from ',
    'getAbstract' => 'Abstract available from '
  }.freeze

  attr_reader :service_type

  def initialize(service_type:)
    @service_type = service_type
  end

  def service
    return unless service_type.present?

    SERVICE_MAP[service_type]
  end
end
