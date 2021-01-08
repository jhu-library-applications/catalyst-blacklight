module HoldingsHelper
  # Provides a user-displayable label for a Holding::Run#marc_type.
  # Can return nil if no label is desired. 
  def run_type_label_for(run_type)
    case run_type
      when "866" then 'Includes' # 'main run'. we could return nil for no label.
      when '867' then 'With Supplements'
      when '868' then 'With Indexes'
      else 'Other'
    end      
  end
end
