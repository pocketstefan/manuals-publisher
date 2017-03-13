require "new_manual_document_attachment_service"

class ManualDocumentAttachmentsController < ApplicationController
  def new
    service = NewManualDocumentAttachmentService.new(
      repository,
      # TODO: This be should be created from the document or just be a form object
      Attachment.method(:new),
      self,
    )
    manual, document, attachment = service.call

    render(:new, locals: {
      manual: ManualViewAdapter.new(manual),
      document: ManualDocumentViewAdapter.new(manual, document),
      attachment: attachment,
    })
  end

  def create
    manual, document, _attachment = services.create(self).call

    redirect_to edit_manual_document_path(manual, document)
  end

  def edit
    manual, document, attachment = services.show(self).call

    render(:edit, locals: {
      manual: ManualViewAdapter.new(manual),
      document: ManualDocumentViewAdapter.new(manual, document),
      attachment: attachment,
    })
  end

  def update
    manual, document, attachment = services.update(self).call

    if attachment.persisted?
      redirect_to(edit_manual_document_path(manual, document))
    else
      render(:edit, locals: {
        manual: ManualViewAdapter.new(manual),
        document: ManualDocumentViewAdapter.new(manual, document),
        attachment: attachment,
      })
    end
  end

private

  def services
    if current_user_is_gds_editor?
      gds_editor_services
    else
      organisational_services
    end
  end

  def gds_editor_services
    ManualDocumentAttachmentServiceRegistry.new
  end

  def organisational_services
    OrganisationalManualDocumentAttachmentServiceRegistry.new(
      organisation_slug: current_organisation_slug,
    )
  end

  def repository
    if current_user_is_gds_editor?
      gds_editor_repository
    else
      organisational_repository
    end
  end

  def gds_editor_repository
    ManualDocumentAttachmentServiceRegistry.new.repository
  end

  def organisational_repository
    OrganisationalManualDocumentAttachmentServiceRegistry.new(
      organisation_slug: current_organisation_slug,
    ).repository
  end
end
