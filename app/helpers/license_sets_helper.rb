module LicenseSetsHelper
  def page_entries_info_modified(collection, options = {})
    entry_name = options[:entry_name] || collection.entry_name
    entry_name = entry_name.pluralize unless collection.total_count == 1

    if collection.total_pages < 2
      t('helpers.page_entries_info.one_page.display_entries', :entry_name => entry_name, :count => collection.total_count)
    else
      first = collection.offset_value + 1
      last = collection.last_page? ? collection.total_count : collection.offset_value + collection.limit_value
      "#{first}-#{last} of #{collection.total_count}"
    end.html_safe
  end
end
