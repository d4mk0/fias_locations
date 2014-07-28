class Location < ActiveRecord::Base
  has_many :sublocations, class_name: 'Location', foreign_key: "location_id"

  belongs_to :parent_location, class_name: 'Location', foreign_key: "location_id"

  enum location_type: [:region, :district, :city, :admin_area, :non_admin_area, :street, :address, :landmark]

  before_save :set_translit

  # recursively collect all parent location nodes and return them in array
  def self.parent_locations(l, memo = [])
    if l.parent_location
      memo << l.parent_location
      Location.parent_locations(l.parent_location, memo)
    else
      return memo
    end
  end

  def parent?
    location_type == 'region'
  end

  private

    def set_translit
      self.translit = Translit.convert self.title, :english
    end

end
