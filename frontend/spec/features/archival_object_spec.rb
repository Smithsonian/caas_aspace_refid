require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'ArchivalObject form', js: true do

  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "ao_form_test_#{@now}")
    set_repo(@repo)
    @resource = create(:resource)
    @ao = create(:json_archival_object,
                 resource: {'ref' => @resource.uri},
                 dates: [])
  end

  before(:each) do
    visit '/logout'
    login_admin
    select_repository(@repo)
  end

  context 'when logged in as an admin', js: true do
    it 'should show regenerate refid checkbox' do
      visit '/'
      visit "resources/#{@resource.id}/edit#tree::archival_object_#{@ao.id}"

      wait_for_ajax

      expect(page).to have_text 'Regenerate Ref ID?'
    end

    it 'can update the ao without changing the ref_id' do
      visit '/'
      visit "resources/#{@resource.id}/edit#tree::archival_object_#{@ao.id}"

      form = find('#form_archival_object')
      expect(form).to have_text @ao.title
      expect(form).to have_text @ao.ref_id

      fill_in 'archival_object_title_', with: "Updated Archival Object Title #{@now}"
      find('button', text: 'Save Archival Object', match: :first).click

      expect(page).to have_text "Archival Object Updated Archival Object Title #{@now} updated"
      heading = find('h2')
      expect(heading.text).to include "Updated Archival Object Title #{@now}"
      expect(form).to have_text @ao.ref_id
    end
  end
end
