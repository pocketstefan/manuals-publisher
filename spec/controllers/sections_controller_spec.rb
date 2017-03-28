require "spec_helper"

describe SectionsController, type: :controller do
  describe "#withdraw" do
    context "for a user that cannot withdraw" do
      let(:manual_id) { "manual-1" }
      let(:section_id) { "section-1" }
      before do
        login_as_stub_user
        allow_any_instance_of(PermissionChecker).to receive(:can_withdraw?).and_return(false)
        post :withdraw, manual_id: manual_id, id: section_id
      end

      after do
        GdsApi::GovukHeaders.clear_headers
      end

      it "redirects to the section's show page" do
        expect(response).to redirect_to manual_section_path(manual_id: manual_id, id: section_id)
      end

      it "sets a flash message" do
        expect(flash[:error]).to include("You don't have permission to")
      end

      it "sets the authenticated user header" do
        expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to match(/uid-\d+/)
      end
    end
  end

  describe "#destroy" do
    let(:manual_id) { "manual-1" }
    let(:section_id) { "section-1" }
    let(:service) { spy(RemoveSectionService) }
    before do
      login_as_stub_user
      allow_any_instance_of(PermissionChecker).to receive(:can_withdraw?).and_return(false)
      allow(RemoveSectionService).to receive(:new).and_return(service)
      delete :destroy, manual_id: manual_id, id: section_id
    end

    after do
      GdsApi::GovukHeaders.clear_headers
    end

    it "redirects to the section's show page" do
      expect(response).to redirect_to manual_section_path(manual_id: manual_id, id: section_id)
    end

    it "sets a flash message" do
      expect(flash[:error]).to include("You don't have permission to")
    end

    it "does not withdraw the manual" do
      expect(service).not_to have_received(:call)
    end

    it "sets the authenticated user header" do
      expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to match(/uid-\d+/)
    end
  end
end