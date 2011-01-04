# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

def language_options
  languages_to_remove = ["Afar", "Abkhazian", "Akan", "Aragonese", "Avaric", "Avestan", "Aymara", "Bashkir",
                        "Bambara", "Bislama", "Chamorro", "Chechen", "Slavic", "Chuvash", "Cornish", "Cree", 
                        "Divehi", "Dzongkha", "Esperanto", "Ewe", "Frisian", "Fulah", "Gallegan", "Manx", 
                        "Guarani", "Hausa", "Herero", "Igbo", "Ido", "Yi", "Inuktitut", "Interlingue", 
                        "Interlingua", "Inupiaq", "Kalaallisut", "Kanuri", "Kikuyu", "Kinyarwanda", 
                        "Kirghiz", "Komi", "Kuanyama", "Limburgish", "Lingala", "Letzeburgesch", 
                        "Luba-Katanga", "Ganda", "Marshall", "Malagasy", "Nauru", "Navajo", "Ndebele", 
                        "Ndebele", "Ndonga", "Chichewa; Nyanja", "Occitan", "Ojibwa", "Oromo", 
                        "Ossetian; Ossetic", "Pali", "Quechua", "Raeto-Romance", "Sango", "Shona", 
                        "Sotho", "Swati", "Tonga", "Tswana", "Tsonga", "Twi", "Uighur", "Venda", "Volapük",
                        "Wolof", "Xhosa", "Zhuang"]
  full_languages_to_remove = ["Achinese", "Acoli", "Adangme", "Adyghe; Adygei", "Afrihilivalue",
                              "Ainu - Japan", "Akkadian", "Aleut", "Altai - Southern", "Aramaic",
                              "Aramaic - Samaritan", "Arapaho", "Araucanian", "Arawak", "Assamese", 
                              "Asturian; Bable", "Awadhi", "Baluchi", "Basa - Cameroon", "Beja", "Bemba - Zambia", 
                              "Bhojpuri", "Bikol", "Bini", "Blin; Bilin", "Braj", "Buginese", "Buriat", "Caddo", 
                              "Cebuano", "Chagatai", "Cherokee", "Cheyenne", "Chibcha", "Chinook jargon", "Chipewyan", 
                              "Choctaw", "Chuukese", "Creek", "Crimean Turkish; Crimean Tatar", "Dakota", "Dargwa", 
                              "Delaware", "Dinka", "Dogri - generic", "Dogrib", "Duala", 
                              "Dutch - Middle (ca.1050-1350)", "Dyula", "Efik", "Egyptian - Ancient", "Ekajuk", 
                              "Elamite", "English - Middle (1100-1500)", "English - Old (ca.450-1100)", "Erzya", 
                              "Ewondo", "Fang - Equatorial Guinea", "Fanti", "Filipino; Pilipino", "Fon", 
                              "French - Middle (ca.1400-1600)", "French - Old (842-Ca.1400)", "Friulian", 
                              "Ga", "Gaelic - Scots", "Gayo", "Gbaya - Central African Republic", "Geez", 
                              "German - Old High (ca.750-1050)", "German - Middle High (ca.1050-1500)","Gilbertese", 
                              "Gondi", "Gorontalo", "Gothic", "Grebo", "Greek - Ancient (to 1453)", 
                              "Greek - Modern (1453-)", "Gwich´in", "Haida", "Haitian; Haitian Creole", "Hawaiian", 
                              "Hiligaynon", "Hiri Motu", "Hittite", "Hmong", "Hupa", "Iban", "Iloko", "Ingush", 
                              "Irish - Middle (900-1200)", "Irish - Old (to 900)","Judeo-Arabic", "Judeo-Persian", 
                              "Kabardian", "Kabyle", "Kachin", "Kalmyk; Oirat", "Kamba - Kenya", "Kara-Kalpak", 
                              "Karachay-Balkar", "Kashubian", "Kawi", "Khasi", "Khotanese", "Kimbundu", 
                              "Klingon; tlhIngan-Hol", "Kongo", "Konkani - generic", "Kosraean", "Kpelle", "Kumyk", 
                              "Kurukh", "Kutenai", "Ladino", "Lahnda", "Lamba", "Latin", "Lezghian", "Lojban", 
                              "Low German; Low Saxon", "Lozi", "Luba-Lulua", "Luiseno", "Lule Sami", "Lunda", 
                              "Luo - Kenya and Tanzania", "Lushai", "Madurese", "Magahi", "Maithili", "Makasar", 
                              "Manchu", "Mandar", "Mandingo", "Manipuri", "Mari - Russia", "Marwari", "Masai", 
                              "Mende - Sierra Leone", "Micmac", "Minangkabau", "Mirandese", "Mohawk", "Moksha", 
                              "Mongo", "Mossi", "Multiple globalize_languages", "Neapolitan", 
                              "Newari - Classical; Old Newari", "Newari", "Nias", "Niuean", "Nogai", "Norse - Old", 
                              "Northern Sami", "Nyamwezi", "Nyankole", "Nyoro", "Nzima", "Osage", "Pahlavi", "Palauan", 
                              "Pampanga", "Pangasinan", "Papiamento", "Persian - Old (ca.600-400 B.C.)", "Phoenician", 
                              "Pohnpeian", "Provençal - Old (to 1500)", "Rapanui Romany", "Rundi", "Sandawe", 
                              "Sanskrit", "Santali", "Sasak", "Scots", "Selkup", "Serer", "Shan", "Sidamo", "Siksika", 
                              "Skolt Sami", "Slave - Athapascan", "Sogdian", "Soninke", "Sorbian - Upper", 
                              "Sorbian - Lower", "Southern Sami", "Sukuma", "Sumerian", "Susu", "Tamashek", 
                              "Tereno", "Tetum", "Tigre", "Timne", "Tiv", "Tlingit", "Tok Pisin", "Tokelau", 
                              "Tsimshian", "Tumbuka", "Turkish - Ottoman (1500-1928)", "Tuvinian", "Udmurt", 
                              "Ugaritic", "Umbundu", "Undetermined", "Vai", "Votic", "Walamo", "Walloon", 
                              "Waray - Philippines", "Washo", "Yao", "Yapese", "Yoruba", "Zapotec", "Zenaga", "Zuni"]

  all_languages = Globalize::Language.find(:all, :conditions => 'iso_639_2 is not null')
  english       = all_languages.select {|l| format_language(l) == "English" }
  removed_languages = all_languages.select {|l| full_languages_to_remove.include?(format_language(l)) }
  return (english + (all_languages - english - removed_languages).
          delete_if {|l| languages_to_remove.include?(l.english_name)}.
          sort{|x, y| x.to_s <=> y.to_s}).
          map{|l| name=format_language(l); "<option value=\"#{l.iso_639_2}\">#{name}</option>"}.
          join('')
end

def gender_options
  return ['Male', 'Female'].map{|g| "<option value=\"#{g}\">#{g}</option>"}.join('')
end

# Displays a Globalize::Language in a user friendly format.
# ====Parameters
# language:: The Globalize::Language to be formatted.
def format_language(language)
  return '' unless language
  return language.to_s + 
         (language.english_name_locale ? " - #{language.english_name_locale}" : '') + 
         (language.english_name_modifier ? " - #{language.english_name_modifier}" : '')
end

def country_options
  countries = TZInfo::Country.all
  countries = countries.sort! {|x, y| x.to_s <=> y.to_s }
  united_states = countries.select {|c| c.code == 'US'}

  (united_states + (countries - united_states)).
    map{|c| name=c.to_s; "<option value=\"#{c.code}\">#{name}</option>"}.
    join('')
end

def time_zone_options
    us_tz = {}
    TZInfo::Timezone.us_zones.each {|tz| us_tz[tz.identifier] = tz.to_s}
    all_tz = TZInfo::Timezone.all.select {|tz| not us_tz.has_key? tz.identifier }

    standard_us_timezones = ['US - Eastern', 'US - Central', 'US - Mountain', 'US - Pacific']
    standard_us_timezones.map! { |tz| "<option value=\"#{tz.downcase.gsub(' - ','_')}\">#{tz}</option>" }

    timezone_options = standard_us_timezones.join
    us_tz.sort.each {|identifier, name| timezone_options << "<option value=\"#{identifier}\">#{name}</option>"}
    all_tz.sort.each {|tz| timezone_options << "<option value=\"#{tz.identifier}\">#{tz.to_s}</option>"}
    return timezone_options
end

begin
  GENDER_OPTIONS_FOR_SELECT = gender_options 
  LANGUAGE_OPTIONS_FOR_SELECT = language_options
  TIME_ZONE_OPTIONS_FOR_SELECT = time_zone_options
  COUNTRY_OPTIONS_FOR_SELECT = country_options
rescue
  STDERR.puts 'Warning: Select Options were not generated.'
end
