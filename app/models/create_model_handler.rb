class CreateModelHandler
  def call(event)
    puts event.inspect

    resource_type = event.data[:resource_type]
    resource = event.data[:resource]
    attributes = event.data[:definition][:attributes]
    record = resource_type.constantize.create!(attributes)
    resource["id"] = record.id
  end
end
