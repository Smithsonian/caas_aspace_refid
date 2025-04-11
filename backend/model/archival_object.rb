require 'ashttp'
require 'date'

def generate_ref_id(resource, repo_id)
  begin
    url = URI.parse(AppConfig[:backend_url] + "/plugins/caas_next_refid?resource_id=#{resource.id}&repo_id=#{repo_id}")
    request = Net::HTTP::Post.new(url.to_s)
    response = ASHTTP.start_uri(url, open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end
    JSON(response.body)['next_refid'] - 1
  rescue
    return DateTime.now.strftime('%Q')
  end
end

rule_template = ERB.new("<%= resource['ead_id'] %>_ref<%= generate_ref_id(resource, repo_id) %>")

ArchivalObject.auto_generate(property: :ref_id,
                             generator: proc do |json|
                               # handling for newly created aos and ao's with caas_regenerate_ref_id set to true
                               if json['ref_id'].nil? || json['caas_regenerate_ref_id']
                                 repo_id = RequestContext.get(:repo_id)
                                 resource = Resource.to_jsonmodel(JSONModel::JSONModel(:resource).id_for(json['resource']['ref']))
                                 rule_template.result(binding())
                               # handling for caas_regenerate_ref_id set to false, including bulk update flow
                               elsif json['caas_regenerate_ref_id'] === false
                                 json[:ref_id] = ArchivalObject.to_jsonmodel(JSONModel::JSONModel(:archival_object).id_for(json['uri']))['ref_id']
                               end
                             end)
