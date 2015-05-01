Spree::Product.class_eval do

  has_and_belongs_to_many  :assemblies, :class_name => "Spree::Product",
        :join_table => "spree_assemblies_parts",
        :foreign_key => "part_id", :association_foreign_key => "assembly_id"

  has_and_belongs_to_many  :parts, :class_name => "Spree::Product",
        :join_table => "spree_assemblies_parts",
        :foreign_key => "assembly_id", :association_foreign_key => "part_id"

  scope :individual_saled, where(["spree_products.individual_sale = ?", true])

  scope :active, lambda { |*args|
    not_deleted.individual_saled.available(nil, args.first)
  }

  attr_accessible :can_be_part, :individual_sale

  # returns the number of inventory units "on_hand" for this product
  def on_hand_with_assembly(reload = false)
    if Spree::Config[:track_inventory_levels] && self.assembly?
      parts(reload).map{|v| v.on_hand / self.count_of(v) }.min
    else
      on_hand_without_assembly
    end
  end
  alias_method_chain :on_hand, :assembly unless method_defined?(:on_hand_without_assembly)

  alias_method :orig_on_hand=, :on_hand= unless method_defined?(:orig_on_hand=)
  def on_hand=(new_level)
    self.orig_on_hand=(new_level) unless self.assembly?
  end

  alias_method :orig_has_stock?, :has_stock? unless method_defined?(:orig_has_stock?)

  def has_stock?
    if Spree::Config[:track_inventory_levels] && self.assembly?
      !parts.detect{|v| self.count_of(v) > v.on_hand}
    else
      self.orig_has_stock?
    end
  end

  def add_part(part, count = 1)
    ap = Spree::AssembliesPart.get(self.id, part.id)
    if ap
      ap.count += count
      ap.save
    else
      self.parts << part
      set_part_count(part, count) if count > 1
    end
  end

  def remove_part(part)
    ap = Spree::AssembliesPart.get(self.id, part.id)
    unless ap.nil?
      ap.count -= 1
      if ap.count > 0
        ap.save
      else
        ap.destroy
      end
    end
  end

  def set_part_count(part, count)
    ap = Spree::AssembliesPart.get(self.id, part.id)
    unless ap.nil?
      if count > 0
        ap.count = count
        ap.save
      else
        ap.destroy
      end
    end
  end

  def assembly?
    parts.present?
  end

  def part?
    assemblies.present?
  end

  def count_of(part)
    ap = Spree::AssembliesPart.get(self.id, part.id)
    ap ? ap.count : 0
  end

end
