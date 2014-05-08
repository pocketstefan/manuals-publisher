require "fast_spec_helper"

require "manual_repository"

describe ManualRepository do
  subject(:repo) {
    ManualRepository.new(
      collection: record_collection,
      factory: manual_factory,
    )
  }

  let(:record_collection) {
    double(:record_collection,
      find_or_initialize_by: nil,
    )
  }

  let(:manual_factory)  { double(:manual_factory, call: nil) }
  let(:manual_id) { double(:manual_id) }

  let(:manual)    { double(:manual, manual_attributes) }

  let(:manual_attributes) {
    {
      id: manual_id,
      title: "title",
      summary: "summary",
    }
  }

  let(:manual_record) {
    double(
      :manual_record,
      manual_id: manual_id,
      new_or_existing_draft_edition: nil,
      latest_edition: nil,
      save!: nil,
    )
  }

  let(:edition) { double(:edition, edition_messages) }
  let(:edition_messages) {
    edition_attributes.merge(
      :attributes= => nil,
    )
  }
  let(:edition_attributes) {
    {
      title: "title",
      summary: "summary",
      updated_at: "yesterday",
    }
  }

  describe "#store" do
    let(:draft_edition) { double(:draft_edition, :attributes= => nil) }

    before do
      allow(record_collection).to receive(:find_or_initialize_by)
        .and_return(manual_record)

      allow(manual_record).to receive(:new_or_existing_draft_edition)
        .and_return(edition)
    end

    it "retrieves the manual record from the record collection" do
      repo.store(manual)

      expect(record_collection).to have_received(:find_or_initialize_by)
        .with(manual_id: manual_id)
    end

    it "retrieves a new or existing draft edition from the record" do
      repo.store(manual)

      expect(manual_record).to have_received(:new_or_existing_draft_edition)
    end

    it "updates the edition with the attributes from the object" do
      repo.store(manual)

      expect(edition).to have_received(:attributes=)
        .with(manual_attributes.slice(:title, :summary))
    end

    it "saves the manual (with a bang)" do
      repo.store(manual)

      expect(manual_record).to have_received(:save!)
    end
  end

  describe "#fetch" do
    before do
      allow(record_collection).to receive(:find_by).and_return(manual_record)
      allow(manual_record).to receive(:latest_edition).and_return(edition)
    end

    it "finds the manual record by manual id" do
      repo.fetch(manual_id)

      expect(record_collection).to have_received(:find_by)
        .with(manual_id: manual_id)
    end

    it "builds a new manual from the latest edition" do
      repo.fetch(manual_id)

      factory_arguments = edition_attributes.merge(id: manual_id)

      expect(manual_factory).to have_received(:call)
        .with(factory_arguments)
    end

    it "returns the built manual" do
      allow(manual_factory).to receive(:call).and_return(manual)

      expect(repo.fetch(manual_id)).to be(manual)
    end
  end

  describe "#all" do
    before do
      allow(record_collection).to receive(:all).and_return([manual_record])
      allow(manual_record).to receive(:latest_edition).and_return(edition)
    end

    it "retrieves all records from the collection" do
      repo.all

      expect(record_collection).to have_received(:all)
    end

    it "builds a manual for each record" do
      repo.all.to_a

      factory_arguments = edition_attributes.merge(id: manual_id)

      expect(manual_factory).to have_received(:call).with(factory_arguments)
    end

    it "builds lazily" do
      repo.all

      expect(manual_factory).not_to have_received(:call)
    end

    it "returns the built manuals" do
      allow(manual_factory).to receive(:call).and_return(manual)

      expect(repo.all.to_a).to eq([manual])
    end
  end
end
