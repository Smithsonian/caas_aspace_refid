class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/plugins/caas_next_refid')
    .description("Get next ref_id for provided resource")
    .params(["resource_id", Integer, "The resource id", :required => "true"])
    .permissions([])
    .returns([200, "{'resource_id', 'ID', 'next_refid', N}"]) \
  do
    current_refid = CaasAspaceRefid.find(resource_id: params[:resource_id])
    incremented_id = !current_refid.nil? ? current_refid.next_refid + 1 : 1
    if !current_refid.nil?
      new_refid_record = current_refid.update(next_refid: incremented_id)
      json = CaasAspaceRefid.to_jsonmodel(new_refid_record.id)
      handle_update(CaasAspaceRefid, current_refid.id, json)
    else
      CaasAspaceRefid.create_from_json(JSONModel(:caas_next_refid).from_hash({:resource_id => params[:resource_id],
                                                                              :next_refid => incremented_id }))
    end

    json_response(:resource_id => params[:resource_id], :next_refid => incremented_id)
  end

  Endpoint.get('/plugins/caas_next_refid/find_by_uri')
    .description("Get the next_refid for a specific resource")
    .params(["resource_uri", String, "The uri of the desired resource.", :required => "true"])
    .permissions([:administer_system])
    .returns([200, (:caas_next_refid)]) \
  do
    resource_id = JSONModel.parse_reference(params[:resource_uri])&.fetch(:id)
    current_refid = CaasAspaceRefid.find(resource_id: resource_id)

    if current_refid
      json = CaasAspaceRefid.to_jsonmodel(current_refid.id)

      json_response(json)
    else
      raise NotFoundException.new("CaasAspaceRefid was not found for resource #{params[:resource_id]}")
    end
  end

  Endpoint.post('/plugins/caas_next_refid/set_by_uri')
    .description("Manually set next ref_id for provided resource")
    .params(["resource_uri", String, "The uri of the desired resource.", :required => "true"],
            ["next_refid", Integer, :next_refid, :required => "true"])
    .permissions([:administer_system])
    .returns([200, :updated]) \
  do
    resource_id = JSONModel.parse_reference(params[:resource_uri])&.fetch(:id)
    current_refid = CaasAspaceRefid.find(resource_id: resource_id)
    new_refid = params[:next_refid]
    if current_refid
      if current_refid.next_refid >= params[:next_refid]
        raise BadParamsException.new(next_refid: "Cannot set a next_refid that is less than or equal to the current refid: #{current_refid.next_refid}")
      end
      new_refid_record = current_refid.update(next_refid: new_refid)
      json = CaasAspaceRefid.to_jsonmodel(new_refid_record.id)
      handle_update(CaasAspaceRefid, current_refid.id, json)
    else
      CaasAspaceRefid.create_from_json(JSONModel(:caas_next_refid).from_hash({:resource_id => resource_id,
                                                                              :next_refid => new_refid }))
    end

    json_response(:resource_uri => params[:resource_uri], :next_refid => new_refid)
  end
end
