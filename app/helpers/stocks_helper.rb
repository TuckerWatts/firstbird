module StocksHelper
  def page_entries_info(collection)
    return unless collection.total_pages > 0
    
    entry_name = 'item'
    if entry_name.respond_to? :model_name
      entry_name = entry_name.model_name.human.downcase
    end
    
    if collection.total_pages < 2
      t('helpers.page_entries_info.one_page.display_entries', 
        entry_name: entry_name.pluralize(collection.total_count), 
        count: collection.total_count)
    else
      first = collection.offset_value + 1
      last = [collection.offset_value + collection.limit_value, collection.total_count].min
      
      t('helpers.page_entries_info.more_pages.display_entries', 
        entry_name: entry_name.pluralize(collection.total_count),
        first: first,
        last: last,
        total: collection.total_count)
    end
  end
end
