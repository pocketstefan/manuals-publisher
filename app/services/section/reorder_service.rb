require "adapters"

class Section::ReorderService
  def initialize(user:, manual_id:, section_order:)
    @user = user
    @manual_id = manual_id
    @section_order = section_order
  end

  def call
    manual.draft
    update
    persist
    export_draft_manual_to_publishing_api

    [manual, sections]
  end

private

  attr_reader :user, :manual_id, :section_order

  def update
    manual.reorder_sections(section_order)
  end

  def persist
    manual.save(user)
  end

  def sections
    manual.sections
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def export_draft_manual_to_publishing_api
    Adapters.publishing.save(manual, include_sections: false)
  end
end
