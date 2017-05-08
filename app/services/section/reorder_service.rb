class Section::ReorderService
  def initialize(context:)
    @context = context
  end

  def call
    manual.draft
    update
    persist
    export_draft_manual_to_publishing_api

    [manual, sections]
  end

private

  attr_reader :context

  def update
    manual.reorder_sections(section_order)
  end

  def persist
    manual.save(context.current_user)
  end

  def sections
    manual.sections
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def section_order
    context.params.fetch("section_order")
  end

  def export_draft_manual_to_publishing_api
    PublishingApiDraftManualExporter.new.call(manual)
  end
end