class SourceJournalDetail < ActiveRecord::Base
  include SecondDatabase
  set_table_name :journal_details

  belongs_to :journal, :class_name => 'SourceJournal', :foreign_key => 'journal_id'
  
  def self.migrate
    all.each do |source_journal_detail|

      jd = JournalDetail.create(source_journal_detail.attributes)
	  new_journal_id = RedmineMerge::Mapper.get_new_journal_id(source_journal_detail.journal_id)
      jd.journal = Journal.find(new_journal_id) if new_journal_id
      next if jd.journal.nil?

      # Need to remap propery keys to their new ids
      if source_journal_detail.prop_key.include?('_id')
        property_name = source_journal_detail.prop_key.to_s.gsub(/\_id$/, "").to_sym
        association = Issue.reflect_on_all_associations.detect {|a| a.name == property_name }
        
        if association
          jd.old_value = RedmineMerge::Mapper.find_id_by_property(association.klass, source_journal_detail.old_value)
          jd.value = RedmineMerge::Mapper.find_id_by_property(association.klass, source_journal_detail.value)
        end
      end
      jd.save()

    end
  end
end
