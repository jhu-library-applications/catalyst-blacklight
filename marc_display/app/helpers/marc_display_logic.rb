# encoding: UTF-8

require 'singleton'
require 'jh_config'
require 'marc_display/code_maps'
require 'marc_display/util'

# Contains a bunch of methods for slicing and dicing info typically found in
# Marc in standard ways.
# While this module can possibly be used as a normal action view helper,
# it's methods do not (and must not) depend on ANY assumed state from
# an assumed controller.
# It's actually intended to be used in a singleton version as DisplaySingleton,
# and with the MarcLogicProcs module to conveniently create Method/Proc
# handles to individual methods, to use in FieldPresenter config.
#
# for instance, to pass the #format_260c method as an argument in FieldPresenter
# instructions:
#  include MarcDisplayLogic::MarcLogicProcs
#  marc_logic(:format_260c)
#
# Or, to include the #format_strip_edge_punctuation method as a proc
# with some options
# set:
#   marc_logic(:format_strip_edge_punctuation, :remove_leading => false)
module MarcDisplayLogic
    # Just a shortcut for MarcDisplayLogic::DisplaySingleton.instance.
    # instead: MarcDisplayLogic.instance
    def self.instance
      return DisplaySingleton.instance
    end


    # replace c1990 and p1990 with copyright and phonogram symbol
    def format_260c(value)
      value.gsub(/c(\d)/, "\302\251\\1").gsub(/p(\d)/, "\u2117\\1")
    end

    def format_strip_edge_punctuation(value, options = {})
      options = {:remove_leading => true,
       :remove_trailing => true}.merge(options)


      return nil if value.nil?

      value = value.sub(/[\/ ,\;\:\=\.]+$/, '') if options[:remove_trailing]
      value = value.sub(/^[\/ ,\;\:\=\.]+/, '') if options[:remove_leading]

      value
    end


    def format_instr_048(value)
      instrument = MarcDisplay::CodeMaps::INSTRUMENTATION[value[0..1]]
        number = value[2..3]
        number = number.to_i if number
        number = nil if number == 0
        if instrument
          instrument +
            (number ? " (#{number})" : "") +
            "."
        else
          nil
        end
    end

    def format_aacr2_abbrev(value)
      value = value.clone
      value.gsub!(/(\d+)\s+(v\.)|(vol\.)/, '\1 volume(s).')
      value.gsub!(/(\d+)\s+p\./, '\1 pages')
      value.gsub!(/(^|[^\w])(illus|ill)\.([^\w]|$)/, '\1illustrations\4')
      value.gsub!(/(^|[^\w])port\.([^\w]|$)/, '\1portrait\2')
      value.gsub!(/(^|[^\w])ports\.([^\w]|$)/, '\1portraits\2')
      value.gsub!(/(^|[^\w])facsim\.([^\w]|$)/, '\1facsimile\2')
      value.gsub!(/(^|[^\w])facsims\.([^\w]|$)/, '\1facsimiles\2')
      value.gsub!(/(^|[^\w])col\.([^\w]|$)/, '\1colored\2')
      value.gsub!(/(^|[^\w])sd\.([^\w]|$)/, '\1sound\2')
      value.gsub!(/s\.n\./i, "no publisher")
      value.gsub!(/s\.l\./i, "place unknown")

      value
    end

    def format_marc_lang(value)
      if (value && value.length > 0)
        MarcDisplay::CodeMaps::LANGUAGE[value]
      else
        nil
      end
    end

    def format_245h(value)
      value.sub(/^\s*\[/, '').sub(/[\]: ,\.\/\=\;]+$/, '').capitalize
    end

    def format_url_to_anchor(value)
      urls = %r{(?:https?)://\S+}i
      value.gsub urls, '<a href="\0">\0</a>'
    end

    # LCCN normalization rules at http://www.loc.gov/marc/lccn-namespace.html
    def format_lccn_normalize(value)
      # 1. Remove all blanks.
      value = value.gsub(/\s/, '')
      # 2. If there is a forward slash (/) in the string, remove it, and remove all characters to the right of the forward slash.
      value = value.sub(/\/.*$/, '')
      ## 3. # If there is a hyphen in the string:
      # * Remove it.
      # * Inspect the substring following (to the right of) the (removed) hyphen. Then (and assuming that steps 1 and 2 have been carried out):
      #   o All these characters should be digits, and there should be six or less.
      #   o If the length of the substring is less than 6, left-fill the substring with zeros until the length is six.
      value = value.sub(/\-(\d{1,6})/) do |match|
        ('0' * (6 - $1.length)) + $1
      end
      value
    end


    # Prefix suitable for a variety of 'heading' fields (inc 100, 110,
    # 700, 710, etc) that use subfields $3, $e, and $4 consistently.
    # Will add a prefix based on part-of-work ($3) and
    # relator ($e or $4).
    #
    # To change or blank subfields used, use prepare_marc_logic
    # with options.
    def prefix_heading(field, options = {})
      options = {:materials => "3",
          :uncontrolled_relator => "e",
          :controlled_relator => "4",
          :default_relator_logic => true}.merge(options)

      materials = options[:materials] ? field[options[:materials]] : nil
      relator = if (options[:controlled_relator] &&
                    controlled = MarcDisplay::CodeMaps::RELATOR[field[options[:controlled_relator]]])
                  controlled
                elsif (options[:uncontrolled_relator] &&
                      uncontrolled= field[options[:uncontrolled_relator]])
                      format_strip_edge_punctuation(uncontrolled).capitalize
                elsif options[:default_relator_logic] &&
                      (field.tag == '100' || field.tag == '110' || field.tag == "111" ||
                      (field.indicator2 == '2' &&
                       (field.tag == '700' || field.tag == '710' || field.tag == '711')))
                  'Contributor'
                else
                  nil
                end
      if ( materials || relator )
        # combine materials and relator as necessary
        (materials ? materials : "") +
         (( materials && relator ) ? ", " : "") +
         (relator ? relator : "")
      else
         nil
      end
    end

    def prefix_760(field)
      field.indicator1 != '8' ? 'Main series' : nil
    end

    def prefix_762(field)
      field.indicator1 != '8' ? 'Has subseries' : nil
    end

    # looks for a 246$i, strips it's trailing punct if neccesary (sometimes it
    # has it, sometimes it doesn't).
    def prefix_246(field)
      display_text = MarcDisplay::Util.h_esc(field["i"])
      display_text = format_strip_edge_punctuation(display_text) if display_text
      return display_text
    end

    # Applies prefix from first indicator for 024 std numbers
    def prefix_024(field)
      case field.indicator1
        when '0' then "ISRC"
        when '1' then "UPC"
        when '2' then "ISMN"
        when '3' then "EAN"
        when '4' then "SICI"
        when '7' then field["2"]
        else nil
      end
    end

    # A standard marc convention is to include "materials this applies to"
    # in a subfield 3. This prefix logic will turn that $3 into a line
    # prefix, if present.
    # options can be set by using marc_logic_prepare to include other
    # verbiage in addition to the $3, and how.
    # :prefix -> additional prefix to put before the $4
    # :force_prefix -> use :prefix even if no $3 is present
    # :linking_text -> add in between :prefix and $3 when both are present.
    def prefix_with_3(field, options = {})
      value = ""
      if ( options[:prefix] &&
          (options[:force_prefix] || field['3']))
          value << options[:prefix]
      end

      if (field['3'] && options['prefix'])
        value << ' '
        value << options[:linking_text] if optionsp[:linking_text]
      end

      value << MarcDisplay::Util.h_esc(field['3']) if field['3']

      value = nil if value == ""

      value
    end


    def prefix_785(field)
      case field.indicator2
        when "0" then "Continued by"
        when "1" then "Continued in part by"
        when "2" then "Superseded by"
        when "3" then "Superseded in part by"
        when "4" then "Absorbed by"
        when "5" then "Absorbed in part by"
        when "6" then "Split into"
        when "7" then "Merged"
        when "8" then "Changed back to"
        else nil
      end
    end

    def prefix_780(field)
      case field.indicator2
        when "0" then "Continues"
        when "1" then "Continues in part"
        when "2" then "Supercedes"
        when "3" then "Supercedes in part"
        when "4" then "Merged from"
        when "5" then "Absorbed"
        when "6" then "Absorbed in part"
        when "7" then "Seperated from"
      end
    end

    # Add a prefix based on 521 indicator 1
    def prefix_521(field)
      {"0" => "Reading grade level", "1" => "Interest age
      level", "2" => "Interest grade level"}[field.indicator1]
    end

    # Add a prefix based on 545 indicator 1, default to
    # "Historical Information"
    def prefix_545(field)
      case field.indicator1
        when "0" then "Biograpical sketch"
        when "1" then "Administrative history"
        else "Historical information"
      end
    end

    def delete_if_no_t(marc_field)
      marc_field['t'].nil?
    end

    # Methods to return map hashes. don't need to be lambda-ized, call
    # with marc_logic_map
    def map_prefix_lcsh
      unless(@map_prefix_lcsh)
        @map_prefix_lcsh = {}
        ["600", "650", "610", "611", "630", "651", "655", "690"].each do |tag|
          ["v", "x", "y", "z"].each do |subfield|
            @map_prefix_lcsh["#{tag}#{subfield}"] = " — "
          end
        end
      end
      @map_prefix_lcsh
    end

    ## custom LINK procs, take two arguments, the MarcDisplay::Link object,
    # and the link hash as calculated so far by the Link object.
    # Return a hash, possibly by modifying hash passed in.


    # Link out from an LCSH heading, making each seperate subdivision
    # a phrase search. Harder than you'd think because LCSH subdivisions
    # can cross MARC sub-fields. Specify search field in the display config
    # as normal, this just changes the query to be phrase searches.
    def link_lcsh_subd(link, hash, options ={})

      # seperate into an array of strings, one string per subdivision, knowing
      # that subdivisions break on certain subfield codes.
      subdivisions =
      link.line.marc_field.subfields.inject([""]) do |subdivisions, subfield|
        if ["v", "x", "y", "z"].include? subfield.code
          subdivisions.push("")
        end
        subdivisions.last << (" " + subfield.value)

        subdivisions
      end

      # now we have subdivisions, normalize em a bit removing trailing
      # punctuation, and phrase quote em if they still need it.
      terms = subdivisions.collect do |subdivision|
        subdivision = subdivision.strip.chomp(".").chomp(",")
        (subdivision =~ /[^[:alnum:]]/) ? ('"' + subdivision.gsub('"', '') + '"') : subdivision
      end

      # and join our seperate terms into one query
      hash[:q] = terms.join(" ")

      return hash
    end

    # Used for links from 240 etc uniform titles, add the main entry if present.
    # Optional third argument of options which can be curried by marc_logic:
    #   :marc_source =>  array of marc source spec that can be passed to a FieldPresenter to find main entry. Defaults to all fields from 100, 110, 111.
    #   :phrase_search => once found, should main entry be enclosed in phrase quotes? Defaults to true.
    def link_add_main_entry(link, hash, options = {})
      #default options
      options = {:phrase_search => true,
                 :marc_source => ["100abcdfgjklmnopqrstu", "110abcdfgjklmnopqrstu", "111acdefgklnpqstu"]
                }.merge(options)

      marc = link.line.marc_record

      # Add 1xx main entry to query, to get the right thing identified
      # By this uniform title. We'll use a FieldPresenter right here
      # to pull out the main entry fields for us.
      presenter = MarcDisplay::FieldPresenter.new(nil, marc, { :source => options[:marc_source]})

      # none?
      return hash unless presenter.lines.length > 0

      # we've got a main entry, get it and add it on to the query
      main_entry_terms = link.clean_query( presenter.lines[0].join )
      if options[:phrase_search]
        main_entry_terms = '"' + main_entry_terms.gsub('"', '') + '"'
      end

      hash[:q] = main_entry_terms + " " + hash[:q]

      return hash
    end

    # utility method used by link_* logic for constructing outgoing
    # links based on 7xx fields that have subfields with common semantics,
    # including 700, 710, 711, 730, 740, and 7xx 'linking fields'
    #http://www.oclc.org/bibformats/en/7xx/76x-78x.shtm
    # pass in a Marc::Field
    # gives you back a hash with possible keys :title, :author, :isbn, :issn, :lccn, :oclcnum
    def extract_7xx_pieces(marc_line)
      pieces = {}

      pieces[:author] = case marc_line.tag
        when "730" then nil
        when "740" then nil
        else [marc_line['a'], marc_line['d']].reject(&:blank?).join(' ')
      end

      pieces[:title] = case marc_line.tag
          when "700" then [marc_line['t'], marc_line['m'], marc_line['n']].reject(&:blank?).join(' ')
          when "711" then marc_line["t"]
          when "730" then marc_line["a"]
          when "740" then marc_line["a"]
          else marc_line["s"] || marc_line["t"]
      end

      pieces[:issn] = marc_line['x'] if marc_line['x']
      pieces[:isbn] = marc_line['z'] if marc_line['z']


      # LCCN or OCLCnum need to be parsed out, bah
      std_num = marc_line["0"] || marc_line["w"]

      lccn = (std_num =~ /\(DLC\) *(.*)$/)  ? $1 : nil
      pieces[:lccn] = lccn if lccn

      oclcnum = (std_num =~ %r|\(OCoLC\) *(.*)$|) ? $1 : nil
      pieces[:oclcnum] = oclcnum if oclcnum

      return pieces
    end

    # Takes a 7xx field of a type with common sub-field semantics
    # that can be parsed by extract_7xx_pieces above, and tries
    # to construct a search link to find that related title.
    # If ISSN or ISBN is found, a search based ONLY on one of
    # those will be used -- including author/title lowers precision
    # too much, and if we have the record it probably has an ISSN or ISBN
    # on it. The same can't be said of lccn or oclcnum, we may have the record
    # but without the lccn or oclcnum listed. So in those cases, we just
    # search on author-title, keeping it a simple any fields search on both,
    # see how that approach works. Ignoring oclcnum or lccn.
    #
    # An additional enhancement could be to actually search for
    # author:A AND title:B
    # instead of glomming them into one 'any field' search. That would require
    # using CQL or possibly advanced search functionality (once advanced search
    # can handle phrase quotes).
    def link_7xx(link, hash, options={})
      options = {
      :isbn_field => "number",
      :issn_field => "number"
      }.merge(options)

      parts = extract_7xx_pieces(link.line.marc_field)

      if parts[:isbn]
        # phrase quoting is good for isbn and issn, becuase it allows
        # solr analyzers to normalize issn/isbn to work, even if there's
        # a space used in the issn or isbn.
        hash[:q] = '"' + parts[:isbn] + '"'
        hash[:search_field] = options[:isbn_field]
      elsif parts[:issn]
        hash[:q] = '"' + parts[:issn] + '"'
        hash[:search_field] = options[:issn_field]
      elsif parts[:author] || parts[:title]
        hash[:q] = ""
        hash[:q] << %|"#{parts[:author].gsub('"', '')}" | if parts[:author]
        hash[:q] << %|"#{parts[:title].gsub('"', '')}"| if parts[:title]
      else
        # no linking!
        hash = false
      end
      return hash
    end


    # EXPERIMENTAL.
    # Takes 7xx linking field, with common subfields for those,
    # ( http://www.oclc.org/bibformats/en/7xx/76x-78x.shtm ), as well
    # as handling 700, 710,
    # Turns into a complex boolean expression based
    # on various attributes in it. BL normally can't support
    # the kind of expression we need, but CQL plugin can, so
    # you need that installed. search_field key for cql default 'cql',
    # or pass in as options[:search_field]
    def link_cql_7xx(link, hash, options = {})
      options = {
        :search_field => "cql",
        :cql_author => "author",
        :cql_title => "title",
        :cql_issn => "issn",
        :cql_isbn => "isbn",
        :cql_lccn => "lccn",
        :cql_oclcnum => "oclcnum"
      }.merge(options)

      marc_line = link.line.marc_field

      parts = extract_7xx_pieces(marc_line)

      or_clauses = []

      if (options[:cql_author] && parts[:author]) || (options[:cql_title] && parts[:title])
        and_clauses = []
        and_clauses << %|#{options[:cql_author]} = "#{parts[:author]}"| if parts[:author]
        and_clauses << %|#{options[:cql_title]} ="#{parts[:title]}"  | if parts[:title]
        or_clauses <<  "( " + and_clauses.join(" AND ") + " )"
      end

      if options[:cql_issn] && parts[:issn]
        or_clauses << %| #{options[:cql_issn]} = "#{parts[:issn]}" |
      end

      if options[:cql_isbn] && parts[:isbn]
        or_clauses << %|#{options[:cql_isbn]} = "#{parts[:isbn]}"|
      end

      if options[:cql_lccn] && parts[:lccn]
        or_clauses << %|#{options[:cql_lccn]} = "#{parts[:lccn]}"|
      end

      if options[:cql_oclcnum] && parts[:oclcnum]
        or_clauses << %|#{options[:cql_oclcnum]} = "#{parts[:oclcnum]}"|
      end

      if or_clauses.length > 0
        hash[:search_field] = options[:search_field]
        hash[:q] = or_clauses.join(" OR ")
        return hash
      else
        return false
      end

    end

    # clean up 800$d date field
    def clean_up_8xx_d(link, hash, options={})
      hash[:q] = hash[:q].gsub(/-/, ' ')
      return hash
    end

  # Singleton class which provides all the methods
  # in MarcDisplayLogic via a singleton object.
  # Access with:
  # MarcDisplayLogic::DisplaySingleton.instance.some_method
  #
  # More typically, and the point of this, is to get a Method handle
  # to an individual method like so:
  # MarcDisplayLogic::DisplaySingleton.instance.method(:some_method)
  #
  # Or as a convenient shortcut, just:
  # include MarcDisplayLogic::MarcLogicProcs
  # marc_logic(:some_method)
  class DisplaySingleton
    include Singleton
    include MarcDisplayLogic
  end


  module MarcLogicProcs
    # Returns a Proc or Method object where calling #call on it will
    # call the logic defined by method named in :method ref.
    # If extra *args are given, the original method is 'curried'
    # with those args, to still produce a one-arg Proc with
    # the extra args hard-coded.
    def marc_logic(method_ref, *args)
      if (args.length == 0)
        # No 'setup arguments', can just return a reference to the Method
        # itself, no need to 'curry' args
        MarcDisplayLogic::DisplaySingleton.instance.method(method_ref)
      else
        # Perhaps too-clever thing to 'curry' (CS term) a method to
        # produce a proc that takes one arg, with the others hard-coded.
        lambda do |actual_arg|
          MarcDisplayLogic::DisplaySingleton.instance.method(method_ref).call(actual_arg, *args)
        end
      end
    end

    def marc_logic_map(name)
      MarcDisplayLogic::DisplaySingleton.instance.method(name).call
    end


  end

end
