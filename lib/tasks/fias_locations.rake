namespace :fias_locations do
  desc "Task for importing all disctricts for selected region"
  task import_dictricts_for_region: :environment do
    region_code = (1..99).include?(ENV["REGION_CODE"].to_i) ? ENV["REGION_CODE"].to_i : 61

    db_crendetials = YAML.load_file(Rails.root.join("config", "database.yml"))[Rails.env]
    rails "Only sqlite3 and postgresql adapters available" unless ["sqlite3", "postgresql"].include? db_crendetials["adapter"]

    ActiveRecord::Base.configurations['fias'] = if db_crendetials["adapter"] == "sqlite3"
      {
        adapter: 'sqlite3',
        database: ':memory:'
      }
    else
      db_crendetials
    end

    Fias::AddressObject.establish_connection :fias

    fias = Fias::DbfWrapper.new(ENV["FIAS_PATH"].presence || 'tmp/fias')
    importer = Fias::Importer.build(
      adapter: db_crendetials["adapter"], connection: Fias::AddressObject.connection.raw_connection
    )
    tables = fias.tables(:address_objects)

    Fias::AddressObject.connection.instance_exec do
      eval(importer.schema(tables))
    end

    district_ids = []
    region_id = nil

    importer.import(tables) do |name, record, index|
      if record["REGIONCODE"].to_i == region_code
        case record["AOLEVEL"].to_i
        when 1
          region = Location.create title: record["OFFNAME"], location_type: :region
          region_id = region.id
        when 3
          location = Location.create title: record["OFFNAME"], location_type: :district
          if region_id.present?
            location.update_attributes(location_id: region_id) 
          else
            district_ids << location.id
          end
        end
      end
    end

    Location.where(id: district_ids).update_all(location_id: region_id)

  end
end
