# Note: This is a 'frozen' copy of the Blacklight distro user.rb
# model.  Future changes to BL distro user.rb may have to be manually
# merged into here. "Freezing" a copy of the model was the only way
# I could figure out to change the validation rules that came with the
# BL distro user.rb -- we do not want to validate password or email,
# as neither are required in our JHED and Horizon based auth implementation.
class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User
  # Connects this user object to Blacklights Bookmarks and Folders. 
  include Blacklight::Folders::User
  #include Blacklight::User::UserGeneratedContent

  #
  # Does this user actually exist in the db?
  #
  def is_real?
    self.class.count(:conditions=>['id = ?',self.id]) == 1
  end
      
  def to_s; login; end  
    
end