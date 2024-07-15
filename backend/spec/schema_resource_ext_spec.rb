require 'spec_helper'

describe 'Resource schema extension' do
  subject { JSONModel(:resource).schema['properties'] }

  it { is_expected.to include('caas_next_refid') }
end
