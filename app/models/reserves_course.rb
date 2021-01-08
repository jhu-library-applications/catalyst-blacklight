class ReservesCourse < ApplicationRecord
  self.primary_key = :course_id
  
  has_many :bib_ids, :class_name => 'ReservesCourseBib', :primary_key => :course_id
  has_many :instructors, :class_name => 'ReservesCourseInstructor', :primary_key => :course_id

  #default_scope :include => [:bib_ids]
  scope :location, lambda {|l| {:conditions => ['location_code = ?', l]  }}
  
  def initialize(hash)
    super(hash)
    self.course_id = hash[:course_id]
  end
  
  
end
