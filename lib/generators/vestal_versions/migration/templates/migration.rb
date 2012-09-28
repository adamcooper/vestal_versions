class CreateVestalVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.belongs_to :versioned, :polymorphic => true
      t.belongs_to :user, :polymorphic => true
      t.string :user_name
      t.string :reason_for_update
      t.text :modifications
      # note: number is reserved word in oracle, so use the global option
      # VestalVersions::Version.config.number_column_name to set alternate column name
      t.integer :number
      t.integer :reverted_from
      t.string  :tag
      t.string  :commit_label
      t.timestamps
    end

    change_table :versions do |t|
      t.index [:versioned_id, :versioned_type]
      t.index [:user_id, :user_type]
      t.index :user_name
      # see note above about number being a reserved word in oracle
      t.index :number
      t.index :tag
      t.index :commit_label
      t.index :created_at
    end
  end

  def self.down
    drop_table :versions
  end
end
