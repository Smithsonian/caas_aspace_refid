require 'spec_helper'

describe 'CAAS ref id plugin' do
  describe 'POST /plugins/caas_next_refid' do
    context 'when no resource_id is provided' do
      it 'throws an error' do
        post '/plugins/caas_next_refid', params = { }

        expect(last_response).not_to be_ok
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('error')
      end
    end

    context 'when a resource_id is provided' do
      let(:resource) { create_resource }

      it 'creates a next_refid' do
        post '/plugins/caas_next_refid', params = { "resource_id" => resource.id}

        expect(last_response).to be_ok
        expect(last_response.status).to eq(200)
      end
    end
  end

  describe 'GET /plugins/caas_next_refid/find_by_uri' do
    context 'when a bad resource_uri is provided' do
      let(:resource_uri) { "/repositories/2/resources/#{rand(100)}" }

      it 'throws an error' do
        get "/plugins/caas_next_refid/find_by_uri?resource_uri=#{resource_uri}"

        expect(last_response).not_to be_ok
        expect(last_response.status).to eq(404)
        expect(last_response.body).to include('CaasAspaceRefid was not found')
      end
    end

    context 'when an existing resource_uri is provided' do
      let(:resource) { create_resource }

      before do
        post '/plugins/caas_next_refid', params = { resource_id: resource.id}
      end

      it 'returns the next_refid' do
        get '/plugins/caas_next_refid/find_by_uri', params = { resource_uri: resource.uri }

        expect(last_response).to be_ok
        expect(last_response.status).to eq(200)
        expect(last_response.body).to match(/"next_refid":1/)
      end


      context 'when a user without administer system permissions' do
        before do
          make_test_user('archivist')
        end

        it 'denies access' do
          as_test_user('archivist') do
            get '/plugins/caas_next_refid/find_by_uri', params = { resource_uri: resource.uri }

            expect(last_response).not_to be_ok
            expect(last_response.status).to eq(403)
            expect(last_response.body).to match(/Access denied/)
          end
        end
      end

    end
  end

  describe 'POST /plugins/caas_next_refid/set_by_uri' do
    context 'when a bad resource_uri is provided' do
      let(:resource_uri) { "/repositories/2/resources/#{rand(100)}" }

      it 'throws an error' do
        post '/plugins/caas_next_refid/set_by_uri', params = { resource_uri: resource_uri,
                                                               next_refid: 300 }

        expect(last_response).not_to be_ok
        expect(last_response.status).to eq(400)
        expect(last_response.body).to match(/Database integrity constraint conflict/)
      end
    end

    context 'when an existing resource_uri is provided' do
      let(:resource) { create_resource }

      before do
        post '/plugins/caas_next_refid/set_by_uri', params = { resource_uri: resource.uri}
      end

      it 'updates the next_refid to the provided value' do
        post "/plugins/caas_next_refid/set_by_uri", params = { resource_uri: resource.uri,
                                                               next_refid: 300}

        expect(last_response).to be_ok
        expect(last_response.status).to eq(200)
        expect(last_response.body).to match(/"next_refid":300/)
      end

      context 'when a next_refid less than the current ref_id is provided' do
        before do
          model = instance_double(CaasAspaceRefid)
          allow(CaasAspaceRefid).to receive(:find).with(resource_id: resource.id).and_return(model)
          allow(model).to receive(:next_refid).and_return(300)
        end

        it 'throws an error' do
          post "/plugins/caas_next_refid/set_by_uri", params = { resource_uri: resource.uri,
                                                                 next_refid: 1 }

          expect(last_response).not_to be_ok
          expect(last_response.status).to eq(400)
          expect(last_response.body).to include('Cannot set a next_refid that is less than or equal to the current refid')
        end
      end

      context 'when a user without administer system permissions' do
        before do
          make_test_user('archivist')
        end

        it 'denies access' do
          as_test_user('archivist') do
            post '/plugins/caas_next_refid/set_by_uri', params = { resource_uri: resource.uri,
                                                                   next_refid: 300}

            expect(last_response).not_to be_ok
            expect(last_response.status).to eq(403)
            expect(last_response.body).to match(/Access denied/)
          end
        end
      end
    end
  end
end
