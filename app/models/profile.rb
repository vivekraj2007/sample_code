class Profile < ActiveRecord::Base
  
   belongs_to :user

   
  file_column :profile_image, :magick => {
   :versions => {:main => "104x104!",:thumbnail => "51x51!", :submain => "171x171!"}  
  }
  
  #validations
#validates_filesize_of :profile_image, :in => 0..100.megabytes
validates_filesize_of :profile_image, :in => 1.kilobytes..3.megabyte
validates_file_format_of :profile_image, :in => ["gif", "png", "jpg"]
#validates_file_format_of :profile_image, :in => ["image/jpeg"]

attr_accessor :total_languages

 LANGUAGES = ["Afrikaans"," Ainu"," Albania", "Amharic", "Amo", "Arabic", "Armenian"," Aymara", 
                      "Azerbaijani", "Azeri", "Bahasa", "Basque", "Batak", "Batak toba", "Belarusian", 
                      "Bengali", "Bihari", "Bosnian", "Breton", "Bulgarian", "Catalan", "Cherokee", 
                      "Chinese (Simplified)", "Chinese (Traditional)", "Cornish"," Corsican", " Cree", 
                      "Croatian", "Czech", "Danish", "Dutch","Edo ","English (UK)"," English (US)", 
                      "Esperanto"," Estonian", "Faroese",
                      "Fijian",  "Filipino",  "Finnish"," French", "Frisian", " Gaelic" ,"Galician" ,"Gascon" ,
                      "Georgian"," Greek", "Guarani", "German","Hanuno’o", "Hausa", "Hawaiian","Hebrew",  "Hindi","Hmong", 
                      "Hopi","Hungarian","Ibibio", "Icelandic",  "Indonesian",  "Ingush",  "Interlingua", "Inuktitut",
                      "Inupiaq",  "Irish", " Italian ", "Japanese",  "Javanese",  "Kannada",  "Kanuri", " Karelian",
                      " Khasi",  "Kirghiz",  "Komi  ","Korean",  "Kurdish", " Kyrgyz",  "Laothian ", "Lapp", " Latin",
                      " Latvian ", "Lithuanian"  ,"Lushootseed", " Luxemburgish",  "Macedonian", " Malay",  "Malayalam",
                      "Maltese",  "Marathi" ,"Mari", " Mongolian", " Naga", " Navajo", " Nepali",  "Norwegian",
                      "Norwegian (Nynorsk)","Occitan"  ,"Oriya",  "Pashto",  "Persian" ," Pig Latin","Polish ","Portuguese" ,
                      "Portuguese (Brazil)","Povencal","Prussian","Punjabi" ,"Quechua","Romanian", "Romansh", " Romany" ,
                      "Russian","Sami" ,"Scots Gaelic","Serbian", " Serbo-Croatian", " Sesotho"," Shona",  "Sindhi",
                      "Sinhalese", "Slovak",  "Slovenian",  "Somali", " Spanish", " Sudanese",  "Swahili",  "Swedish", 
                      "Tagbanwa",  "Tahitian",  "Tajik",  "Tamazight", "Tamil",  "Telugu",  "Thai",  "Tigrinya",  "Turkish",
                      " Turkmen",  "Twi", "Udmurt", "Uighur",  "Ukrainian",  "Urdu",  "Uzbek",  "Vietnamese", "Welsh",
                      "Xhosa", "Yi","Yiddish", " Yoruba",  "Zulu"]     
        
def total_languages
  languages = ""
if !self.language_1.blank?
   languages << language_1
   languages << ", "
end
if !self.language_2.blank?
   languages << language_2
   languages << ", "
 end 
 if !self.language_3.blank?
   languages << language_3
 end
 
   if !languages.blank?
     return languages.chomp(", ") 
   end
end
        
        
        
        
        
        
        
        
        

end
