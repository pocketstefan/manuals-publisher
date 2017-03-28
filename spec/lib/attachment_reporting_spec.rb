require "spec_helper"
require "attachment_reporting"

describe AttachmentReporting, '#create_organisation_attachment_count_hash' do
  let(:start_date) { Date.parse('2015-01-01') }
  let(:last_time_period_days) { 30 }
  let(:attachment_file_extension) { 'pdf' }

  let(:highway_code_manual_slug) { "guidance/the-highway-code" }
  let(:highway_code_organisation_slug) { 'department-for-transport' }
  let!(:highway_code_manual_record) { ManualRecord.create(slug: highway_code_manual_slug, organisation_slug: highway_code_organisation_slug) }

  # one published before the start date with a PDF
  let!(:early_section_edition_with_pdf) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      exported_at: start_date - 1.day,
    ).tap do |section_edition|
      section_edition.attachments.create!(
        filename: 'attachy.pdf',
        file_id: '1'
      )
    end
  end

  # one published before the start date with a non-PDF attachment
  let!(:early_section_edition_with_non_pdf) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      exported_at: start_date - 1.day,
    ).tap do |section_edition|
      section_edition.attachments.create!(
        filename: 'attachy.txt',
        file_id: '2'
      )
    end
  end

  # one only drafted before the start date with a PDF attachment
  let!(:early_section_edition_draft_with_pdf) do
    FactoryGirl.create(
      :section_edition,
      state: "draft",
      exported_at: start_date - 1.day,
    ).tap do |section_edition|
      section_edition.attachments.create!(
        filename: 'attachy.pdf',
        file_id: '3'
      )
    end
  end

  # one created between the start date and the last time period
  let!(:more_recent_section_edition) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      exported_at: (Date.today - last_time_period_days) - 1.day,
    ).tap do |section_edition|
      section_edition.attachments.create!(
        filename: 'attachy.pdf',
        file_id: '4'
      )
    end
  end

  # one created after the last time period
  let!(:very_recent_section_edition) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      exported_at: (Date.today - last_time_period_days) + 1.day,
    ).tap do |section_edition|
      section_edition.attachments.create!(
        filename: 'attachy.pdf',
        file_id: '5'
      )
    end
  end

  let!(:highway_code_manual_edition) {
    highway_code_manual_record.editions.create!(
      state: "published",
      version_number: 1,
      document_ids: [
        early_section_edition_with_pdf.document_id,
        early_section_edition_with_non_pdf.document_id,
        early_section_edition_draft_with_pdf.document_id,
        more_recent_section_edition.document_id,
        very_recent_section_edition.document_id
      ],
    )
  }

  let(:patent_manual_slug) { 'guidance/manual-of-patent-practice' }
  let(:patent_manual_organisation_slug) { 'intellectual-property-office' }
  let!(:patent_manual_record) { ManualRecord.create(slug: patent_manual_slug, organisation_slug: patent_manual_organisation_slug) }

  let!(:very_recent_draft_patent_section_edition) do
    FactoryGirl.create(
      :section_edition,
      state: "draft",
      exported_at: Date.today,
    ).tap do |section_edition|
      section_edition.attachments.create!(
        filename: 'attachy.pdf',
        file_id: '6'
      )
    end
  end

  let!(:patent_practice_manual_edition) {
    patent_manual_record.editions.create!(
      state: "published",
      version_number: 1,
      document_ids: [
        very_recent_draft_patent_section_edition.document_id
      ],
    )
  }

  let(:subject) { described_class.new(start_date, last_time_period_days, attachment_file_extension) }

  it "creates a hash of all specified file type attachment counts within the specified periods" do
    expect(subject.create_organisation_attachment_count_hash).to eq(
      highway_code_organisation_slug.titleize => [3, 2, 1],
      patent_manual_organisation_slug.titleize => [0, 0, 0]
    )
  end
end