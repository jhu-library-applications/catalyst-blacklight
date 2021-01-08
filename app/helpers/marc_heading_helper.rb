# encoding: UTF-8

module MarcHeadingHelper
  extend ActionView::Helpers::TextHelper
  extend MarcDisplayLogic::MarcLogicProcs
  # definitions for MarcDisplayLogic::Presenter
  FieldDescriptions = {
    :title => { :source => "245akn", :formatter=> marc_logic(:format_strip_edge_punctuation) },

    :sub_title => {:source => "245bfps", :formatter=> marc_logic(:format_strip_edge_punctuation)},

    # subfields need to match how author solr field is indexed. 
    :main_entry => {:source => [
      {:load_marc => "100abcdfgjklmnopqrstu",
       :link => {:query_field => "author", :phrase_search => true, :subfields => "abcdq" }
      }, 
      { :load_marc => "110abcdfgjklmnopqrstu",
        :link => {:query_field => "author", :phrase_search => true, :subfields => "abcdgnu" }
      },
      { :load_marc => "111acdfgklnpqstu",
        :link => {:query_field => "author", :phrase_search => true, :subfields => "acdenqu" }
      }
      ]
    },
    

    :type => { :source => { :solr_field => "format", 
                            :delete_if_filter => lambda do |a, line|
                              line.raw_data == "Other"
                            end
                          }
              },

    :backup_type => { :source => "245h",
                      :formatter => marc_logic(:format_245h)
                   },
  
    :lang => { :source => {:solr_field => "language_facet", 
                           :delete_if_filter =>
                              lambda do |a, line|
                                line.raw_data == "Unknown"
                              end
                          }
             },

    :pub_date => {:source => {:solr_field => "pub_date"}},

  }


  # Returns titles based on any linked 880's for the 245.
  # Too hard to do this with MarcPresenter, we do it by hand, sorry
  # it results in confusing code. 
  def heading_linked_titles(document)
    marc = document_to_marc(document)
    
    return linked_marc_fields(marc, marc['245']).collect do |field|
      title =  field.find_all do |subfield|
        "a".include?( subfield.code)
      end.collect {|sv| sv.value}.join(" ")  

      subtitle = field.find_all do |subfield|
      "bfnps".include?(subfield.code)
      end.collect {|sv| sv.value}.join(" ")

      
      strip_edge_punctuation( title ) + 
      (subtitle.empty? ? "" : ":") + 
      strip_edge_punctuation( subtitle )
    end    
  end

  # Returns statements of responsibility based on any linked 880's for
  # the 245. Too hard to use MarcPresenter for this, we do it by hand. 
  def heading_linked_stmt_resp(document)
    marc = document_to_marc(document)
    
    return linked_marc_fields(marc, marc['245']).collect do |field|
      strip_edge_punctuation(field['c']) 
    end.compact
  end
  

  
  def heading_type_str(document)
      lines = marc_presenter(document, :type).lines
      if lines.length == 0
        lines.concat( marc_presenter(document, :backup_type).lines )
      end
      
      
      join_marc_lines(lines, :seperator => ", ")
    
  end
  

  def heading_language_str(document)
    presenter = marc_presenter(document, :lang)

    join_marc_lines(presenter.lines, :seperator => ", ")

  end

  def heading_pub_date_str(document)
    first_line = marc_presenter(document, :pub_date).lines[0]

    render_marc_line(first_line)
  end

  def heading_title(document)
    render_marc_line( marc_presenter(document, :title).lines[0]  )
  end

  def heading_subtitle(document)
    render_marc_line( marc_presenter(document, :sub_title).lines[0] )
  end

  # 245c, optionally truncated. easier to do without marcpresenter
  def heading_stmt_resp(document, options = {})
    marc = document_to_marc(document)

    stmt = marc['245'].try {|f| f['c']}

    if options[:truncate] && stmt.present?
      stmt = truncate(stmt, :length => 90, :omission => "… ", :separator => " ")
    end
    
    return stmt
  end

  def heading_main_entry(document)
    # doing weird manual things with our MarcDisplay framework, sorry
    # the framework is breaking down and was clearly a mistake.     
    line =  marc_presenter(document, :main_entry).lines[0]

    return "" unless line.present?

    # Our weird things are mostly because we want to surround it in parens
    txt = line.join
    #txt = txt.chomp(".") # trailing periods not helpful when we're surrounding with parens

    #link_to "(#{txt})", line.link.hash_for_url 
    link_to txt, line.link.hash_for_url 
  end

  protected

  def strip_edge_punctuation(*args)
    MarcDisplayLogic::DisplaySingleton.instance.format_strip_edge_punctuation(*args)
  end

  def marc_presenter(document, key)
  
    descr = FieldDescriptions[key]

    # if we don't have a local one, look in the default marc_display stuff
    if (descr == nil)
      descr = MarcDisplay.default_presenter_config_list.find {|h| h[:id] == key}
    end
    
    raise Exception.new("No description found for FieldDescriptions[#{key}]") if descr.nil?
    
    MarcDisplay::FieldPresenter.new(document, document.to_marc, descr)
  end
  
  def join_marc_lines(lines, options = {})
    options[:seperator] ||= ", "

    return nil if lines.length == 0

    return lines.collect {|l| render_marc_line(l)}.join(html_escape(options[:seperator])).html_safe
    
  end

  
  # Returns nil if no loine. Otherwise renders marc_line with line, and
  # removes some inconvenient HTML whitespace.
  def render_marc_line(line)        
    return nil if line.nil?

    return render(:partial => "marc_display/marc_line", :locals => {:line => line}).sub(/^(\n|\s)+/,'').sub(/(\n|\s)+$/, '').html_safe
  end

  ## Helpers for the index action
  #
  
  def marc_index_title(document)
    title_line = marc_presenter(document, :title).lines[0]
    subtitle_line = marc_presenter(document, :sub_title).lines[0]

    title = (title_line ? title_line.join : "Unknown")
    subtitle = (subtitle_line ? subtitle_line.join : nil)

    if subtitle
      title = title + ": " + subtitle
    end
    return title
  end

  # for index action, all subjects rendered seperated by commas
  def all_subject_lines(document)      
  
    return [marc_presenter(document, :subjects), marc_presenter(document, :medical_subjects), marc_presenter(document, :local_subjects)].collect {|p| p.lines}.flatten
  end
    
  

  # Finds a 'summary' from a marc record, but makes sure it's no longer
  # than a certain number of chars, for index page, truncating on whitespace. 
  def shortened_summary(document)
    max_chars = 280
    
    summary_presenter = marc_presenter(document, :summary)
    
    return nil unless summary_presenter.lines.length > 0

    # just the first line, grab the text
    text = summary_presenter.lines[0].join

    # and truncate if needed
    if (text.length > max_chars)
       truncate_at = text.rindex(" ", max_chars)
       text = html_escape(text[0..truncate_at-1]) + "&#8230".html_safe # elipsis
    end

    return text
  end

  # Takes ToC but limits to so many chars for index page. Truncates
  # on complete entry seperated by "--" if possible. 
  def shortened_contents(document)
    max_chars = 280

    contents_presenter = marc_presenter(document, :contents)

    return nil unless contents_presenter.lines.length > 0

    line = contents_presenter.lines[0]
    text = line.join
        
    if text.length > max_chars
      truncate_at = text.rindex("--", max_chars)
      truncate_at = text.rindex(" ", max_chars) unless truncate_at
      text = html_escape(text[0..truncate_at-2]) + "&#8230;".html_safe # elipsis    
    end
    return text
  end

end
