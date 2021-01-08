module MarcDisplay
  # Normally 'extend'ed into MarcDisplay itself
  # to provide default presenters on MarcDisplay.default_presenter_config_list
  module DefaultPresenters
    # in order to get our nice shortcut `marc_logic` method, we mix in 
    # MarcLogicProcs as class methods, so we can use them in our class var definition.
    extend MarcDisplayLogic::MarcLogicProcs
    

    def suggested_header_presenter_config_list
      SuggestedHeaderPresenterConfigList
    end

      # A couple presenters we show in an earlier part of the screen
      SuggestedHeaderPresenterConfigList = [
          # We supply Title in the heading section, we don't want it here.
          # {
          #  :label => "Title",
          #  #211 212 and 214 were in my legacy mappings, but dont' seem to actually exist   
          #  :source => ["245abcfnps"],
          #  :css_classes => ["demo_title_here"]
          #},
          

          # Includes a bunch of edition-related information too          
          { :label => "Publication",
            :id => :publication,
            :source => ["260abcdefg", "261abedf", "262abckl", "264abc", "562abcde35", "250ab"],
            :prefix_map => 
              { "362" => "Publication history",
                "362e" => "Manufactured",
                "264" => lambda do |field|
                            case field.indicator2
                            when "0" then "Production"
                            when "2" then "Distribution"
                            when "3" then "Manufacture"
                            when "4" then "Copyright Notice"
                            else nil
                            end
                        end,
                "310" => lambda do |field|                                    
                                      "Frequency" +
                                      (field['b'] ? " (#{field['b']})" : "")
                          end,
                "321" => lambda do |field|
                                      "Former frequency" +
                                      (field['b'] ? " (#{field['b']})" : "")
                          end,
                "562" => marc_logic(:prefix_with_3), 
                "533"=> marc_logic(:prefix_with_3,
                        :prefix => "Reproduction", 
                        :force_prefix => true, 
                        :linking_text => " of "),
                "534" => lambda do |field|
                    field['p'].try {|s| s.chomp(":")} || "Reproduced from" 
                end,
                "534z" => "ISBN",
                "534n" => "note"
              },
            :formatter_map => {"260c" => marc_logic(:format_260c), "260a" => marc_logic(:format_aacr2_abbrev), "260b" => marc_logic(:format_aacr2_abbrev), "310a" => marc_logic(:format_strip_edge_punctuation), "321a" => marc_logic(:format_strip_edge_punctuation)}
          },
          # Called "Description" traditionally
          # 306 might be good in here, but that info is always somewhere else
          # in the record already anyway, and I don't feel like formatting it
          # right now. 
          { :label => "Format",
            :id => :format,
            :source => [                  
                  # We don't need to show 245h, it duplicates our own format/genre vocabs
                  # we're generating and showing. 
                  #{:load_marc => "245h"},
                  "300abcefg", 
                  "305abcdef", 
                  "340abcdefhi",
                  "256a",
                  "245k",                
                  "753a", 
                  "516a", 
                  "538ai3"
             ],
            :prefix_map => {  
                "340" => marc_logic(:prefix_with_3),
                "300" => marc_logic(:prefix_with_3),              
                "300e" => "Accompanied by"
            },
            :formatter_map => {
              "300a" => marc_logic(:format_aacr2_abbrev),
              "300b" => marc_logic(:format_aacr2_abbrev),
              "300e" => marc_logic(:format_aacr2_abbrev),
              "245h" => marc_logic(:format_245h) 
            }
          }
      ]    

    def default_presenter_config_list
      MarcDisplay::DefaultPresenters::DefaultPresenterConfigList
    end
      
      DefaultPresenterConfigList =  [
          { :label => "This reproduction",
            :id => :reproduction,
            :source => ["533abcdefmn", "534abcefklmntxz"],
            :prefix_map => {
                "533"=> marc_logic(:prefix_with_3,                        
                  :linking_text => " of "),
                "534" => lambda do |field|
                    field['p'].try {|s| s.chomp(":")} || "Reproduced from" 
                end,
                "534z" => "ISBN",
                "534n" => "note"
            }
          },
          { :label => "Publication history",
            :id => :publication_history,
            :source => ["310a", "321a", "362a"],
            :prefix_map => {
                "310" => lambda do |field|                                    
                                      "Frequency" +
                                      (field['b'] ? " (#{field['b']})" : "")
                          end,
                "321" => lambda do |field|
                                      "Former frequency" +
                                      (field['b'] ? " (#{field['b']})" : "")
                          end,
                "362e" => "Manufactured"
            }
          },
          { :label => "Related Links",
            :id => :links,
            :source => ["856uzy3"],
            :partial => "marc_display/marc_856"
          },
          # 247 should maybe be with 'related titles'. Nah, I don't think so.
          # "Alternate titlet"? "Other titles"? I went with:
          { :label => "Also known as",
            :id => :other_titles,
            :source => [  { :load_marc => "130adfghklmnoprst", # uniform title
                            :link => { :phrase_search => true, 
                                       :query_field => "title"}
                          },
                          {:load_marc => "240adfghklmnoprs", # uniform title
                           :link => 
                              { :phrase_search => true,
                                :custom =>  marc_logic(:link_add_main_entry)
                              }
                           },
                           # collective uniform title. Deprecated: 
                          { :load_marc => "243adfghklmnoprs",
                            :link =>
                              {:phrase_search => true, 
                              :custom => marc_logic(:link_add_main_entry)
                              }
                          },
                          "210ab", # Abbreviated title
                          "222ab", # (Serial) key title
                          "242abcehnp", # Translated title
                          "740-*0ahnp", # Related title, second indicator 0 means 'alternative title'. Deprecated. 
                          {:load_marc => "247abfgnpx", :link => {:query_field => "title", :subfields => "ab"}}, # Former title
                          {:load_marc => "246abfghnp"} # Varying form of title
                       ],
            :prefix_map => {"242" => lambda do |field|
                              MarcDisplayLogic.instance.format_marc_lang( field['y'] )                                      
                            end,
                            "247" => "Former title",
                            "247x" => "ISSN",
                            "246" => marc_logic(:prefix_246),
                            "130" => "Uniform Title",
                            "240" => "Uniform Title",
                            "243" => "Uniform Title"
                            }
          },
          # 100 is unconventionally just grouped with 'related names', we
          # don't really know a 100 is an author. But 100 is used if no 245c
          # is present in top headline. 
          # TO DO. This is a mess. 7xx can be analytic, contributor, or related
          # work. (Analytic is contributor of course). 
          # 4/e ; 3 for 700s
          # Link subfields match subfields in our indexing of author-name facet, 
          # so we're searching on what we think is the 'controlled heading'. 
          { :label => "Related names",
            :id => :related_names,
            :source => [ {  :load_marc => "100abcdfgjklmnopqrstu",
                           :link => {:query_field => "author", :phrase_search => true, :subfields => "abcdq" }
                         }, 
                         { :load_marc => "110abcdfgjklmnopqrstu",
                           :link => {:query_field => "author", :phrase_search => true, :subfields => "abcdgnu" }
                         },
                         { :load_marc => "111acdefgklnpqstu",
                           :link => {:query_field => "author", :phrase_search => true, :subfields => "acdenqu" } 
                         }, 
                         { :load_marc => "700abcdjq",
                           :link => {:query_field => "author", :phrase_search => true, :subfields => "abcdq" }
                         },
                         {  :load_marc => "710abcd",
                            :link => {:query_field => "author", :phrase_search => true, :subfields => "abcdgnu" }
                         }, 
                         {  :load_marc => "711acdenqu",
                            :link => {:query_field => "author", :phrase_search => true, :subfields => "acdenqu" }
                         },
                         {:load_marc => "720a", :link => {:query_field => "author", :phrase_search => true}}, 
                         { :load_marc => "191abcdfgjklmnopqrstu", 
                           :link=> false }
                        ],                       
            :prefix_map => {
              "100" => marc_logic(:prefix_heading, :materials => nil), 
              "110" => marc_logic(:prefix_heading, :materials => nil),
              "111" => marc_logic(:prefix_heading, :materials => nil, :uncontrolled_relator => "j"),
              "700" => marc_logic(:prefix_heading),
              "710" => marc_logic(:prefix_heading),
              "711" => marc_logic(:prefix_heading, :uncontrolled_relator => "j"),
              "720" => marc_logic(:prefix_heading, :materials => nil)                        
            },
            :unique => true
          },
          { :label => "Credits",
            :id => :credits,
            :source => "508a"},
          { :label => "Performers",
            :source => "511a",
            :prefix_map => 
              {"511" =>
                lambda { |field| (field.indicator1 == "1") ? "Cast" : nil }
              }                              
          },
          # Also need to take care of 973. 79x.  
          { :label => "Related titles",
            :id => :related_titles,
            :source => ["700abcdfjklmnoprstux", "710abcdfklmnoprstux", "711abcdfklmnopqrstux", "730adfghklmnoprstx", 
            {:load_marc => "740ahnp",
              # indicator2 == 0 goes with 'also known as'.
              :delete_if_filter => lambda {|field| field.indicator2 == '0'}
            }, "773abcdghikmnoqrstuxyz3", "774abcdghikmnoqrstuxyz3", "786abcdghijkmnoprstuvxyz", "765abcdghikmnorrstuwxyz" "767abcdghikmnorrstuwxyz",
            "787abcdghikmnorstuxyz"],
            :delete_if_filter_map => {"700" => marc_logic(:delete_if_no_t), "710" => marc_logic(:delete_if_no_t), "711" => marc_logic(:delete_if_no_t)},
            :link => {:custom => marc_logic(:link_7xx)}, 
            :prefix_map => {"700x" => "ISSN", "710x" => "ISSN", "711x" => "ISSN",
                            "773x" => "ISSN", "772z" => "ISBN", "774x" => "ISSN",
                            "774z" => "ISBN", "786x" => "ISSN", "786z" => "ISBN",
                            "786y" => "CODEN","767x" => "ISSN", "767z"=>"ISBN",
                            "765x" => "ISSN", "765z" => "ISBN", "787x" => "ISSN", "787z" => "ISBN", "730x" => "ISSN",
                      "700" => lambda {|f| "Includes" if f.indicator2 =='2'},
                      "710" =>  lambda {|f| "Includes" if f.indicator2 =='2'},
                      "711" =>  lambda {|f| "Includes" if f.indicator2 =='2'},
                      "740" =>  lambda {|f| "Includes" if f.indicator2 =='2'},
                      "773" => "In",
                      "774" => "Includes",
                      "786" => "Data source",
                      "767" => "Translation",
                      "765" => "Original language"}                                        
          },
          {:label => "Former title",
           :id => :former_title,
           :source=>"780abcdghikmnorstuxyz",
           :prefix_map => {"780x" => "ISSN", "780z" => "ISBN", 
                           "780e" => "Language",
                           "780" => marc_logic(:prefix_780)
                          },
           :formatter_map => {"780e" => marc_logic(:format_marc_lang) },
           :link => {:custom =>marc_logic(:link_7xx)}
          },                                                  
          {:label => "Later title",
            :id => :later_title,
            :source => ["785abcdghikmnorstuxyz"],
            :prefix_map => {"785x" => "ISSN", "785z" => "ISBN",
                            "785e" => "Language",
                            "785" => marc_logic(:prefix_785)
                            },
            :formatter_map => {"785e" => marc_logic(:format_marc_lang) },
            :link => {:custom =>marc_logic(:link_7xx)}
           },
          { :label => "Subjects",
            :id => :subjects,
            :source => [
                { :load_marc => "600-*0abcdefghjklmnopqrstuvxyz24",
                  :link => {:query_field => "subject", :custom => marc_logic(:link_lcsh_subd)}},
                { :load_marc => "610-*0abcdefghklmnoprstuvxyz24",
                  :link => {:query_field => "subject", :custom => marc_logic(:link_lcsh_subd)}},
                { :load_marc => "611-*0abcdefghklnpqstuvxyz24",
                  :link => {:query_field => "subject", :custom => marc_logic(:link_lcsh_subd)}},
                { :load_marc => "630-*0adfghklmnoprstvxyz2",
                  :link => {:query_field => "subject", :custom => marc_logic(:link_lcsh_subd)}},
                { :load_marc => "650-*0abcdevxyz2",
                  :link => {:query_field => "subject", :custom => marc_logic(:link_lcsh_subd)}},
                { :load_marc => "650-*7abcdevxyz",
                  :link=>{:subfields=>"abcdexyz", :phrase_search=>true, :query_field=>"subject"}},
                { :load_marc => "651-*0avxyz",
                  :link => {:query_field => "subject", :custom => marc_logic(:link_lcsh_subd)}}
            ],
            #emdash for LCSH display, plus handle $3
            :raw_prefix_map => marc_logic_map(:map_prefix_lcsh).merge({
              "600" => marc_logic(:prefix_with_3), 
              "610" => marc_logic(:prefix_with_3), 
              "611" => marc_logic(:prefix_with_3), 
              "630" => marc_logic(:prefix_with_3), 
              "650" => marc_logic(:prefix_with_3), 
              "651" => marc_logic(:prefix_heading, :default_relator_logic => false)}),
          },
          { :label => "Medical Subjects",
            :id => :medical_subjects,
            :link => {:query_field => :subject, :custom => marc_logic(:link_lcsh_subd)},
            :source => "650-*2abcdevxyz23",
            :raw_prefix_map => marc_logic_map(:map_prefix_lcsh)
          },
          { :label => "Local Subjects",
            :id => :local_subjects,
            :link => {:query_field => :subject, :custom => marc_logic(:link_lcsh_subd)},
            :source => [
             "690abcdxyz", "691abxyz", "692abxyz", "693abxyz", "656akvxyz23", "657avxyz23", "652axyz", "653a6", "654abcvyz23", "658abcd26", "650-*4abcdevxyz23", "610-*4abcdefghklmnopqrstuvxyz234", "600-*4abcdefghjklmnopqrstuvxyz234", "611-*4acdefghklnpqstuvxyz234","630-*4adfghklmnoprstvxyz23", "651-*4avxyz236" 
            ],
            #emdash for LCSH-style display, plus handle $3
            :raw_prefix_map => marc_logic_map(:map_prefix_lcsh).merge({
              "600" => marc_logic(:prefix_with_3), 
              "610" => marc_logic(:prefix_with_3), 
              "611" => marc_logic(:prefix_with_3), 
              "630" => marc_logic(:prefix_with_3), 
              "650" => marc_logic(:prefix_with_3), 
              "651" => marc_logic(:prefix_heading, :default_relator_logic => false),
              "654" => marc_logic(:prefix_heading, :default_relator_logic => false),
              "656" => marc_logic(:prefix_with_3),
              "657" => marc_logic(:prefix_with_3)
            })
          },
          # Should we put this in with subjects? I dunno, legacy OPAC
          # had it seperate. 
          { :label => "Genre",
            :id => :genre,
            :source => "655abcvxyz",
            :raw_prefix_map => marc_logic_map(:map_prefix_lcsh).merge({"655" => marc_logic(:prefix_with_3), "6552" => "Source of term"}) #emdash for LCSH display,
            
          },
          # Putting 760 here is unusual, but we do it.
          # TODO: Figure out how to extract 'citation' to link to from 800/810/811/760/762
          { :label => "Series",
            :id => :series,
            :source => [{ :load_marc => "440anpvx", 
                          :link=>{:subfields=>"a", :phrase_search=>true, :query_field=>"series"}},                        
                          { :load_marc => "800abcdeghjklmnopqrstuvx",
                            :link => {:subfields => "abcdt", :query_field=>"series", :phrase_search => true, custom: marc_logic(:clean_up_8xx_d)}
                          },
                          { :load_marc => "400abcdefgklnptuvx",
                            :link => {:query_field=>"series", :subfields => "abcd"} }, # 400 is obsolete version of 800
                          { :load_marc => "810abcdeghklmnoprstuvx",
                            :link => {:query_field=>"series", :subfields => "abcdt", :phrase_search => true} },
                          { :load_marc => "410abcdefghklmnoprstuvx",
                          :link => {:phrase_search => true, :query_field=>"series", :subfields => "abcd"}}, # 410 is obsolete version of 810                          
                          { :load_marc => "811abcdeghklnpqstuvx",
                            :link => {:query_field=>"series", :subfields => "acdeft", :phrase_search => true} },
                          { :load_marc => "411abcdefghklnpqstuvx",
                            :link => {:query_field=>"series", :subfields => "acdef"} }, # 411 is obsolete version of 811
                          { :load_marc => "830adfghklmnoprstvx", 
                          :link=>{:subfields => "adfgklmnoprst", :phrase_search => true, :query_field=>"series"}},
                          "490-0*alvx", # no link on non-controlled field
                          { :load_marc => "760abcdghimnoqstxy",
                            :link => true  },
                          { :load_marc => "762abcdghimnoqstxy",
                            :link => true  }
                          ],
            :prefix_map => {"760" => marc_logic(:prefix_760),
                            "762" => marc_logic(:prefix_762),
                            "800x" => "ISSN",
                            "400x" => "ISSN",
                            "810x" => "ISSN",
                            "410x" => "ISSN",
                            "811x" => "ISSN",
                            "411x" => "ISSN",
                            "830x" => "ISSN"
                  }
          },
          # TODO. Use indicator of summary for label?  
          { :label => "Summary",
            :id => :summary,
            :source => ["520ab"],
            :prefix_map => {"520" => marc_logic(:prefix_with_3)}
          },
          { :label => "Contents",
            :id => :contents,
            :source => ["505agrtu"],
            :partial => "marc_display/marc_contents"
          },
          { :label => "Instrumentation",
            :id => :instrumentation,
            :css_classes => ["ordered_list"],
            :source => "048ab",
            :prefix_map => {"048b" => "Soloist"},
            :formatter_map => {"048a" => marc_logic(:format_instr_048), 
                           "048b" => marc_logic(:format_instr_048)
                           }
          },
          # "Notes"
          # TODO: 754 should be linkable?
          { :label => "Other information",
            :id => :notes,
            :css_classes => ["wider_spaced"],
            :source => ["500a35", "501a5", "502a","504ab", "506abcde", "513ab", "514abcdefghijkmuz", "515a", "518aodp3", "521ab3", "522a", "524a2", "525a", "526abcdixz", "535abcdg3", "546ab3", "547a", "550a", "552abcd", "555au", "507ab", "561a3","255abcdefg", "580a", "581az3", "585a35", "586a3", "530abcdu3", "540abcd5", "567a", "556az", "563a", "541ca3d","754acdz2", "510abcux","565abcde","545abu","584ab",
            #JH local notes
            "590a", "591a", "592a",
            #JH Archives data
            "3513ab"
            ],        
            :prefix_map => {"502a" => "Dissertation",
                          "514" => "Data quality",
                          "510" => marc_logic(:prefix_with_3,
                                :prefix => "Indexed by", 
                                :force_prefix=>true),
                          "510x" => "ISSN",
                          "506" => marc_logic(:prefix_with_3, 
                                    :prefix => "Restrictions", 
                                    :force_prefix => true, 
                                    :linking_text => 'to'),
                          "540" => marc_logic(:prefix_with_3, 
                                    :prefix => "Restrictions", 
                                    :force_prefix => true, 
                                    :linking_text => 'to'),
                          "545" => marc_logic(:prefix_545),
                          "521" => marc_logic(:prefix_521), 
                          "524"  => marc_logic(:prefix_with_3),                          
                          "524a" => "Cite as",
                          "5242" => "Citation from",
                          "525" => "Supplements",
                          "535" => "Custodian",
                          "561" => "Ownership history",
                          "565" => marc_logic(:prefix_with_3,
                              :prefix => "Case file characteristics", :force_prefix => true),
                          "546" => "Language",
                          "550" => "Issued by",
                          "552" => "Data",
                          "555" => "Finding aids note",
                          "586" => "Awards",
                          "563" => marc_logic(:prefix_with_3,
                                      :prefix => "Binding", 
                                      :force_prefix => true, 
                                      :linking_text => "of"),
                          "567" => "Methodology",
                          "556" => "Documentation",
                          "522" => "Geographic coverage",
                          "255" => "Cartographic data",
                          "507" => "Scale",
                          "754" => "Taxonomic Identification",
                          "7542" => "Source taxonomy",
                          "351" => "Organization and arrangement of materials",
                          "584" => marc_logic(:prefix_with_3)
            },
            :formatter_map => {
                '555u' => marc_logic(:format_url_to_anchor),
                '510u' => marc_logic(:format_url_to_anchor)
            }
          },
          #JH local, not sure what it means
          {:label => "Source",
           :source => ["593a"]},
           
           #TODO: Needs to be cleaned up. Grouped with related works. 
           {:label => "Has supplement",
            :id => :supplement,
            :source => "770abcdghikmnoqrstuxyz",
            :prefix_map => {"770" => marc_logic(:prefix_with_3),
                            "770x" => "ISSN",
                            "770z" => "ISBN"},
            :link => {:custom => marc_logic(:link_7xx)}
           },
           {:label => "Supplement to",
            :id => :supplement_to,
            :source => "772abcdghikmnoqrstuxyz",
            :prefix_map => {"772" => marc_logic(:prefix_with_3),
                            "772x" => "ISSN",
                            "772z" => "ISBN"},
            :link => {:custom => marc_logic(:link_7xx)}
           },
           {:label => "Additional form",
            :id => :additional_form,
            :source => "776abcdghikmnoqrstuxwyz",
            :prefix_map => {"776" => marc_logic(:prefix_with_3),
                            "776x" => "ISSN",
                            "776z" => "ISBN"},
            :link => {:custom => marc_logic(:link_7xx)}
           },
           {:label => "Related archival materials",
            :id => :related_archival,
            :source => "544abcde",
            :prefix_map => {"544" => marc_logic(:prefix_with_3)}
           },
          { :label => "Publisher's number",
            :id => :pub_num,
            :source => ["028ba"]
          },
          { :label => "ISBN",
            :id => :isbn,
            :source => ["020ab","776z", "534z"], #776z is questionable but in orig OPAC
            :prefix_map => {"534z" => "Original version", "776z" => "Alternate version"},
            :formatter => marc_logic(:format_strip_edge_punctuation)
          },
          { :label => "ISSN",
            :id => :issn,
            :source => ["022a","022y", "022l", "776x","490x","440x"] #776x is questionable but in orig OPAC mapping. 022y is "incorrect" ISSN, but apparently sometimes used for alternate manifestation ISSNs?
          },
          { :label => "GPO Item Number",
            :id => :gpo_item,
            :source => "079a"
          },
          { :label => "SuDoc Call Number",
            :id => :sudoc_call,
            :source => "086-*1a"
          }, 
           { :label => "Identifying numbers",
            :id => :numbers,
            :source => ["024a", "010a", "010b", 
                        {:load_marc => "035a", 
                        :delete_if_filter => lambda do |field|                                
                          ! (field['a'][0..6] == "(OCoLC)" ||
                          field['a'][0..2] == "ocm" ||
                          field['a'][0..2] == "ocn" ||
                          field['a'][0..1] == "on")                
                        end,
                        :formatter => lambda {|value| value.sub(/^(ocm)|(ocn)|(on)|(\(OCoLC\))/,'')}
                        }
                       ],
           :prefix_map => {"010a" => "LCCN", "035" => "OCLC", "010b" => "NUCMUC number", "024" => marc_logic(:prefix_024)}
          }
           
       ]
      
    
  end  
end
