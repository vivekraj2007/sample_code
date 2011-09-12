class Photo < ActiveRecord::Base
  
  # relations
  belongs_to :photoset
  has_many :user, :through => :photoset
  
  
  #validations
validates_presence_of :image
validates_file_format_of :image, :in => ["gif", "png", "jpg"]
#validates_filesize_of :image, :in => 0..100.megabytes
validates_filesize_of :image, :in => 1.kilobytes..50.megabyte
#validates_file_format_of :image, :in => ["image/jpeg"]

#image resize
file_column :image, :magick => {
  :versions => {:main => "600x450>",:thumbnail => "51x51!", :submain => "104x104!"}
  #:versions => {:main => "560x392>",:thumbnail => "51x51!", :submain => "104x104!"}
  # :versions => {:main => "144x144!",:thumbnail => "45x45!", :submain => "97x97!"}  
  }
  
  
  
    #~ def swfupload_file=(data)
    #~ #data.content_type = MIME::Types.type_for(data.original_filename).to_s
    #~ self.image = data
   #~ end

  
end
