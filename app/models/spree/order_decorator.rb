Spree::Order.class_eval do

  def add_variant(variant, quantity = 1, ad_hoc_option_value_ids=[], product_customizations=[], assembly_variants=[])
    current_item = contains?(variant, ad_hoc_option_value_ids, product_customizations)
    if current_item and matching_assembly_parts?(current_item, assembly_variants)
      current_item.quantity += quantity
      current_item.save
    else
      current_item = Spree::LineItem.new(:quantity => quantity)
      current_item.variant = variant

      # add the product_customizations, if any
      # TODO: is this an unnecessary step?
      product_customizations.map(&:save) # it is now safe to save the customizations we created in the OrdersController.populate

      current_item.product_customizations = product_customizations

      # find, and add the configurations, if any.  these have not been fetched from the db yet.              line_items.first.variant_id
      # we postponed it (performance reasons) until we actaully knew we needed them
      povs=[]
      ad_hoc_option_value_ids.each do |cid|
        povs << Spree::AdHocOptionValue.find(cid)
      end
      current_item.ad_hoc_option_values = povs

      current_item.price   = variant.price + povs.map(&:price_modifier).compact.sum + product_customizations.map {|pc| pc.price(variant)}.sum
      self.line_items << current_item
    end
    current_item
  end

  def matching_assembly_parts?(item, assembly_variants)
    return true if !item.variant.product.assembly?
    return true if item.assembly_variants.empty? && assembly_variants.empty?

    !assembly_variants.present? or item.assembly_variants.map(&:variant_id).sort == assembly_variants.map{|v| v.to_i}.sort
  end

end
