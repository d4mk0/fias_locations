class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :title
      t.string :translit
      t.integer :location_type
      t.integer :location_id
      t.timestamps
    end
    add_index :locations, :location_id, using: 'btree'
    add_index :locations, :location_type, using: 'btree'
  end
end
