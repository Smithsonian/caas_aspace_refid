require 'spec_helper'

describe 'ArchivalObject model' do
  let(:resource) { create_resource({ ead_id: 'my.eadid' }) }
  let(:resource_json) { Resource.to_jsonmodel(resource.id) }

  context 'when the next_refid endpoint responds' do
    let(:response) { instance_double(Net::HTTPResponse) }
    let(:caas_next_refid) do
      JSONModel(:caas_next_refid).from_hash({ resource_id: resource.id,
                                              next_refid: 41 })
    end

    before do
      allow(Net::HTTP).to receive(:start).and_return(response)
      allow(response).to receive(:body).and_return(caas_next_refid.to_json)
    end

    describe '#generate_ref_id' do
      it 'returns a value one less than the next_refid' do
        expect(generate_ref_id(resource_json)).to eq(40)
      end
    end

    describe '#auto_generate' do
      context 'when the archival object is new' do
        let(:archival_object) do
          create_archival_object({ ref_id: nil,
                                    resource: { ref: "/repositories/2/resources/#{resource.id}" } })
        end

        it 'calls the caas_next_refid endpoint' do
          archival_object

          expect(Net::HTTP).to have_received(:start)
        end

        it 'auto generates the ref_id' do
          expect(archival_object.ref_id).to eq('my.eadid_ref40')
        end
      end

      context 'when an existing archival object is updated with caas_regenerate_ref_id set to true' do
        let(:archival_object) do
          create_archival_object({ ref_id: '123',
                                    caas_regenerate_ref_id: true,
                                    resource: { ref: "/repositories/2/resources/#{resource.id}" } })
        end

        it 'calls the caas_next_refid endpoint' do
          archival_object

          expect(Net::HTTP).to have_received(:start)
        end

        it 'auto generates ref_id' do
          archival_object.save

          expect(archival_object.ref_id).to eq('my.eadid_ref40')
        end
      end
    end
  end

  context 'when the next_refid endpoint fails to return a ref_id' do
    let(:refid_fallback) { DateTime.now.strftime('%s')[0..-2] }

    before do
      allow(Net::HTTP).to receive(:start).and_call_original
    end

    describe '#generate_ref_id' do
      it 'returns a unique date string' do
         expect(generate_ref_id(resource_json)).to start_with(refid_fallback)
       end
    end

    describe '#auto_generate' do
      context 'when archival object is new' do
        let(:archival_object) do
          create_archival_object({ ref_id: nil,
                                  resource: { ref: "/repositories/2/resources/#{resource.id}" } })
        end

        it 'calls the caas_next_refid endpoint' do
          archival_object

          expect(Net::HTTP).to have_received(:start)
        end

        it 'auto generates ref_id from the unique date string' do
          expect(archival_object.ref_id).to start_with("my.eadid_ref#{refid_fallback}")
        end
      end

      context 'when an existing archival object is updated with caas_regenerate_ref_id set to true' do
        let(:archival_object) do
          create_archival_object({ caas_regenerate_ref_id: true,
                                   resource: { ref: "/repositories/2/resources/#{resource.id}" } })
        end

        it 'calls the caas_next_refid endpoint' do
          archival_object

          expect(Net::HTTP).to have_received(:start)
        end

        it 'auto generates ref_id' do
          expect(archival_object.ref_id).to start_with("my.eadid_ref#{refid_fallback}")
        end
      end
    end
  end
end
