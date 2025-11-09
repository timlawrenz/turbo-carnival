class CreatePipelines < ActiveRecord::Migration[8.0]
  def change
    create_table :pipelines do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :pipelines, :name
  end
end
