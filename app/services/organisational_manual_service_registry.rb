class OrganisationalManualServiceRegistry < AbstractManualServiceRegistry
  def initialize(organisation_slug:)
    @organisation_slug = organisation_slug
  end

  attr_reader :organisation_slug
end
