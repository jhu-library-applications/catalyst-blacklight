module MarcDisplay
  module OpenUrlDefaultMappings
    extend MarcDisplayLogic::MarcLogicProcs



    def self.produce!
      mappings = {}


      # For author, prefer 100's, if no 100's then take 245$c
      mappings[:au_first_choice] = {
        :source => ["100abcdfgjklmnopqrstu", "110abcdfgjklmnopqrstu", "111acdefgklnpqstu"],
        :formatter => marc_logic(:format_strip_edge_punctuation)
      }
      mappings[:au_second_choice] = {
        :source => { :load_marc => "245c",
          :formatter => lambda do |value|
            # Trying to get an author name out of a 245c is lame, but
            # we'll use a few tricks that'll help.
            value.gsub(/^\s*\[?by\]?\s*/, '').gsub(/\=.*$/, '')
            # In case we got a REALLY long one, we chop it please.
            if value.split(/\s/).length > 8 # more than 8 words?
              value = value.split(/\s/)[0,8].join(" ")
            end
            value
          end
        }
      }
      # should be output as jtitle for journals, btitle for books.
      mappings[:title] = {
        :source => ["245afgbk"],
        :formatter => marc_logic(:format_strip_edge_punctuation)
      }
      # from 260c now. Should date1 or date2 be included?
      mappings[:date] = {
        :source => ["260c"],
        :formatter => lambda do |value|
          # if we got four digits in 260c, take the first. Otherwise,
          # give up.
          if value =~ /(\d\d\d\d)/
            $1
          end
        end
      }
      mappings[:issn] = {
         :source => ["022a","022y", "022l","490x","440x"],
         :formatter => lambda do |value|
           #remove all non-digit/X please
           value.gsub(/[^\dX]/, '')
         end
      }
      mappings[:isbn] = {
        :source => ["020ab", "534z"],
        :formatter => lambda do |value|
          #remove all non-digit/X
          value = value.upcase

          # try to get out the ISBN from the marc field
          # that mixes ISBN followed by weirdness, for instance
          # in a problematic case: "0809103419 (v. 1)"
          if (value =~ /^ *([\d X\-]+)/)
            $1.gsub(/[^\dX]/, '')
          else
            value.gsub(/[^\dX]/, '')
          end
        end
      }
      mappings[:lccn_uri] = {
        :source => ["010a"],
        :formatter => lambda do |value|
          "info:lccn/" + MarcDisplayLogic.instance.format_lccn_normalize(value)
        end
      }
      mappings [:oclcnum_uri] = {
        :source => ["035a"],
        :delete_if_filter => lambda do |field|
          ! (field['a'][0..6] == "(OCoLC)" ||
          field['a'][0..2] == "ocm" ||
          field['a'][0..2] == "ocn" ||
          field['a'][0..1] == "on")
        end,
        :formatter => lambda do |value|
          "info:oclcnum/" + value.sub(/^(ocm)|(ocn)|(on)|(\(OCoLC\))/,'').gsub(/[^\d]/, '')
        end
      }

      #book-only mappings
      mappings[:place] = {
        :source => ["260a"],
        :formatter => marc_logic(:format_strip_edge_punctuation)
      }
      mappings[:pub] = {
        :source => ["260b"],
        :formatter => marc_logic(:format_strip_edge_punctuation)
      }
      mappings[:edition] = {
        :source => ["250ab"],
        :formatter => marc_logic(:format_strip_edge_punctuation)
      }
      mappings[:tpages] = {
        :source => ["300a"],
        :formatter => lambda do |value|
          # pull pages out of a 300a, not that fun, rough approximation.
          parts = value.split(",")
          found_pages = ""
          parts.reverse_each do |p|
            if p =~ /\s*([^\s]*)\s*(p\.?)|(pages)\s*$/
              found_pages = $1
              break
            end
          end
          found_pages
        end
      }
      mappings[:doi_uri] = {
        :source => "024-7*a",
        :delete_if_filter => lambda do |marc_line|
          marc_line["2"] != "doi"
        end,
        :formatter => lambda do |value|
          cleaned_value = value.gsub(/^\s(doi\:)?/, '').gsub('\s$', '')
          "info:doi/#{cleaned_value}"
        end

      }

      return mappings
    end
  end
end

