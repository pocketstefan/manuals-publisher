require "spec_helper"
require "marked_section_deleter"
require "services"

describe MarkedSectionDeleter do
  subject {
    described_class.new(StringIO.new)
  }

  let(:publishing_api) { double(:publishing_api) }

  before {
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
  }

  context "when edition is marked for deletion but isn't in publishing api" do
    let!(:edition) {
      FactoryBot.create(:section_edition, title: 'xx-to-be-deleted')
    }

    before {
      allow(publishing_api).
        to receive(:get_content).
        with(edition.section_uuid).
        and_raise(GdsApi::HTTPNotFound.new(nil))
    }

    it "deletes the edition" do
      subject.execute(dry_run: false)

      expect(SectionEdition.count).to eql(0)
    end
  end

  context "when edition is marked for deletion and is in publishing api" do
    let!(:edition) {
      FactoryBot.create(:section_edition, title: 'xx-to-be-deleted')
    }

    before {
      allow(publishing_api).
        to receive(:get_content).
        with(edition.section_uuid).
        and_return(double(:gds_api_response))
      allow(publishing_api).
        to receive(:discard_draft).
        with(edition.section_uuid)
    }

    it "deletes the edition" do
      subject.execute(dry_run: false)

      expect(SectionEdition.count).to eql(0)
    end

    it 'discards the draft from the publishing api' do
      expect(publishing_api).
        to receive(:discard_draft).
        with(edition.section_uuid)

      subject.execute(dry_run: false)
    end
  end

  context "when edition isn't marked for deletion" do
    let!(:edition) {
      FactoryBot.create(:section_edition, title: 'not-to-be-deleted')
    }

    it "doesn't delete any editions" do
      subject.execute(dry_run: false)

      expect(SectionEdition.count).to eql(1)
    end
  end

  context "when executed in dry run mode" do
    let!(:edition) {
      FactoryBot.create(:section_edition, title: 'xx-to-be-deleted')
    }

    before {
      allow(publishing_api).to receive(:get_content)
    }

    it "doesn't delete any editions" do
      subject.execute(dry_run: true)

      expect(SectionEdition.count).to eql(1)
    end

    it "doesn't discard any drafts from the publishing api" do
      expect(publishing_api).to_not receive(:discard_draft)

      subject.execute(dry_run: true)
    end
  end
end
