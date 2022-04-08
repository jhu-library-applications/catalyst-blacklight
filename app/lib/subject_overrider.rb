require 'yaml'

class SubjectOverrider
  attr_accessor :line, :part
  attr_reader :overrides

  def initialize(line:, part:)
    @line = line
    @part = part

    @overrides = YAML.load(File.open(Rails.root.join('config', 'translation_maps', 'subject_overrides.yml').to_s))
  end

  def translated_subject
    @overrides[part.formatted_value.to_s] || part.formatted_value.to_s
  end
end


