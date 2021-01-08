# ruby 1.8.7/1.9 compat

Range.class_eval do

  unless method_defined?(:cover?)
    def cover?(elem)
      include?(elem)
    end
  end

end

# Some utility methods for taking a collection code and
# LCC call number, and coming up with an MSE floor/level
# to add in. May be expanded to add in other extra locational
# information for other libraries. 
class LCCToExtraLabel
  # From Horizon collection code to our internal set ==>
  # right now just MSE, but could be expanded. 
  cattr_accessor :collection_code_to_set    
  @@collection_code_to_set = {}
  ['emain', 'emainnc', 'eanal', 'eanalnc', 'ecl87', 'eclass',
  'ecirla', 'ecirlnc', 'eolsc', 'eolser', 'eolserb'].each do |id|
    self.collection_code_to_set[id] = :msel
  end  
  
  
  # from a 'set' code returned by collection_code_to_set
  # to a hash whose keys are ranges of LC prefixes,
  # and values are floor/level display strings.
  # ranges should use two dots for INCLUSIVE ranges usually.
  # this works because ascii sort order works for determining
  # our LC prefix ranges. Note "A" < "AA" and "A" < "AB", great.
  # If you only have one two letter combo, just make a range
  # anyhow ('BF'..'BF)
  cattr_accessor :set_to_map
  @@set_to_map = {}
  msel = @@set_to_map[:msel] = {}
  
  [("K".."KZ"),('A'..'AZ')].each do |range|
    msel[range] = "A Level"
  end
  
  [('B'..'BD'), ('BH'..'BX'), ('C'..'CZ'), ('D'..'DZ'), 
    ('E'..'EZ'), ('F'..'FZ'), ('G'..'GA'), ('GF'..'GV'), ('H'..'HZ'),
    ('J'..'JZ'), ('L'..'LZ'), ('M'..'MZ')].each do |range|
    msel[range] = "B Level"
  end
  
  [('BF'..'BF'), ('GB'..'GE'), ('Q'..'QZ'), ('R'..'RZ'), ('S'..'SZ'), 
   ('T'..'TZ'), ('U'..'UZ'), ('V'..'VZ'), ('Z'..'ZZ')].each do |range|
    msel[range] = "C Level"
  end
  
  [('N'..'NZ'), ('P'..'PZ')].each do |range|
    msel[range] = "D Level"
  end
  
  
  # Pass in internal Horizon collection_code, and call number.
  # returns a floor label like "A Level", or nil if it can't find one. 
  def self.translate(coll_code, lcc)
    map = self.set_to_map[ self.collection_code_to_set[coll_code] ]
    
    return nil unless map # not a coll_code that we map to floor
    
    # pull the first thing that looks like it could be an LCC
    # 1-3 letter prefix out of the string. Try to take account
    # of weird stuff, this may have false positives, better than
    # false negatives. 
    if lcc =~ /(^|[^a-zA-Z])([a-zA-Z]{1,3})([^a-zA-Z]|$)/
      prefix = $2.upcase
      
      map.each_pair do |range, label|
        # === works for checking in range or checking string equality,
        # so long as our range/string is left-hand side. 
        if (range.cover? prefix)
          return label
        end
      end      
    end
    
    # If the regex didn't match and we coudln't even get a prefix,
    # or if the prefix wasn't in the map. 
    return nil    
  end
  
end
