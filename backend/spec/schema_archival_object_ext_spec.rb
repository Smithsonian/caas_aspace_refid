require 'spec_helper'

describe 'Archival object schema extension' do
  subject(:caas_regenerate_ref_id) { JSONModel(:archival_object).schema['properties'] }

  it { is_expected.to include('caas_regenerate_ref_id') }

  it 'defaults caas_regenerate_ref_id boolean to false' do
    expect(caas_regenerate_ref_id['caas_regenerate_ref_id']['default']).to be(false)
  end
end
