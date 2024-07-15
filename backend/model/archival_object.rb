require 'net/http'
require 'date'

def generate_ref_id(resource_id)
  begin
    url = URI.parse(AppConfig[:backend_url] + "/plugins/caas_next_refid?resource_id=#{resource_id}")
    request = Net::HTTP::Post.new(url.to_s)
    response = Net::HTTP.start(url.host, url.port) do |http|
      http.request(request)
    end
    refid = JSON(response.body)['next_refid']
  rescue
    refid = DateTime.now.strftime('%Q')
  end
  refid
end

ArchivalObject.auto_generate(property: :ref_id,
                             generator: proc do |json|
                               resource = Resource.to_jsonmodel(JSONModel::JSONModel(:resource).id_for(json['resource']['ref']))
                               "#{resource['ead_id']}_ref#{generate_ref_id(resource['id'])}"
                             end,
                             only_on_create: true)

ArchivalObject.auto_generate(property: :ref_id,
                             generator: proc do |json|
                               resource = Resource.to_jsonmodel(JSONModel::JSONModel(:resource).id_for(json['resource']['ref']))
                               "#{resource['ead_id']}_ref#{generate_ref_id(resource['id'])}"
                             end,
                             only_if: proc { |json| json['caas_regenerate_ref_id'] })
