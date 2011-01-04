class CreateOpenIdMappings < ActiveRecord::Migration
  class OpenIdMapping < ActiveRecord::Base
    has_one :property_type
  end

  class PropertyType < ActiveRecord::Base
    acts_as_tree :order => 'order_by ASC'#:counter_cache => true
    belongs_to :user
    after_create :set_order_by
    has_many :properties, :dependent => :delete_all
    belongs_to  :open_id_mapping

    validates_presence_of :title
    validates_presence_of :short_name
  end

  def self.up
    create_table :open_id_mappings do |t|
      t.column :short_name, :string
    end
    add_column :property_types, :open_id_mapping_id, :integer

    open_id_mappings = { 'openid.sreg.country'  => 'address_home_country',
                         'openid.sreg.dob'      => 'dob',
                         'openid.sreg.email'    => 'contact_email_personal', 
                         'openid.sreg.fullname' => 'full_name', 
                         'openid.sreg.gender'   => 'gender', 
                         'openid.sreg.language' => 'language', 
                         'openid.sreg.nickname' => 'nickname', 
                         'openid.sreg.postcode' => 'address_home_postal_code', 
                         'openid.sreg.timezone' => 'timezone', }
    open_id_mappings.each do |open_id_short_name, property_type_short_name|
      property_type   = PropertyType.find_by_short_name(property_type_short_name)
      rollback("Could not find property type: #{property_type_short_name}.") unless property_type

      open_id_mapping = OpenIdMapping.create(:short_name => open_id_short_name)
      open_id_mapping.property_type = property_type
      rollback("Could not save open_id_mapping: #{open_id_mapping.short_name}.") unless open_id_mapping.save
    end
  end

  def self.down
    remove_column :property_types, :open_id_mapping_id
    drop_table :open_id_mappings
  end

  def self.rollback(message)
    self.down
    raise message + ' The migration has been rolled back.'
  end
end
