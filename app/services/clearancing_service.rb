require 'csv'
require 'ostruct'
class ClearancingService

  def process_file(uploaded_file)
    clearancing_status = create_clearancing_status

    CSV.foreach(uploaded_file, headers: false) do |row|
      potential_item_id = row[0].to_i
      clearancing_error = get_errors(potential_item_id)
      if clearancing_error
        clearancing_status.errors << clearancing_error
      else
        clearancing_status.item_ids_to_clearance << potential_item_id
      end
    end

    clearance_items!(clearancing_status)
  end

private

  # only get items once
  # this should clearance items not statuses?
  def clearance_items!(clearancing_status)
    if clearancing_status.item_ids_to_clearance.any?
      clearancing_status.clearance_batch.save!
      clearancing_status.item_ids_to_clearance.each do |item_id|
        item = Item.find(item_id)
        item.clearance!
        clearancing_status.clearance_batch.items << item
      end
    end
    clearancing_status
  end

  def get_errors(potential_item_id)
    if potential_item_id.blank? || potential_item_id == 0 || !potential_item_id.is_a?(Integer)
      return "Item with id: #{potential_item_id} is not valid"
    end

    item = Item.where(id: potential_item_id).first

    if item.blank?
      return "Item with id: #{potential_item_id} could not be found"
    elsif !(item.status == "sellable")
      return "Item with id: #{potential_item_id} could not be clearanced"
    elsif !(item.acceptably_clearance_priced?)
      return "Item with id: #{potential_item_id} does not the minimum clearance pricing criteria"
    end
  end

  def create_clearancing_status
    OpenStruct.new(
      clearance_batch: ClearanceBatch.new,
      item_ids_to_clearance: [],
      errors: [])
  end

end
