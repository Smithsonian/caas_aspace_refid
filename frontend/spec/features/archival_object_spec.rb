require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'ArchivalObject form', js: true do

  before(:all) do
    @repo = create(:repo, repo_code: "ao_form_test_#{Time.now.to_i}")
    set_repo(@repo)
    @resource = create(:resource)
    @ao = create(:json_archival_object,
                 :resource => {'ref' => @resource.uri})
    PeriodicIndexer.new.run_index_round
  end

  before(:each) do
    login_admin
  end

  after(:each) do
    wait_for_ajax
    Capybara.reset_sessions!
  end

  context 'when logged in as an admin', js: true do
    it 'should show regenerate refid checkbox' do
      edit_resource(@resource)
      find(:xpath, "//a[@href='#tree::archival_object_#{@ao.id}']").click

      expect(page).to have_text 'Regenerate Ref ID?'
    end
  end
end
