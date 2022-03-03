require 'yaml'

class SubjectOverriderTerms
  attr_accessor :terms
  attr_reader :overrides

  def initialize(terms:)
    @terms = terms

    @overrides = YAML.load(File.open(Rails.root.join('config', 'translation_maps', 'subject_overrides.yml').to_s))
  end

  def translated_terms
    terms.map { |term| @overrides[term_as_key(term)] || term  }
  end

  def term_as_key(term)
    term.strip.tr('\"', '')
  end
end
