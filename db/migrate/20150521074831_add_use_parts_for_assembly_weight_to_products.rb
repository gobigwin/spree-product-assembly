class AddUsePartsForAssemblyWeightToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :use_parts_for_assy_weight, :boolean, :default: true, null: false
  end
end
