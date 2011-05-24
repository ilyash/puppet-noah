Puppet::Parser::Functions::newfunction(:noah_put, :doc => "
Updates values to  Noah. Takes a Noah URL, request type and data and returns data from a running Noah instance:

    noah_put($noah_url, $type, $data)

Where `$noah_url` is the URL of a valid Noah server, `$type` is one of application, host, configuration or service and `$data` is the name of the data type to return.

    noah_put('http://localhost:9292', host, $hostname)

This will retrieve the host information for the `$hostname` variable from the Noah server at `http://localhost:9292`.  
") do |args|

  request_types = ["host", "service", "application", "configuration"]
  begin
    require 'rest-client'
    require 'uri'
  rescue LoadError => detail
    Puppet.info "noah_put(): You need to install the rest-client gem to use the noah function"
  end

  raise ArgumentError, ("noah_put(): wrong number of arguments (#{args.length}; must be 3)") if args.length != 3

  noah_url, request, data = URI.parse(args[0]), args[1], args[2]

  raise ArgumentError, ("noah_put(): request type #{request} invalid. Valid request types are #{request_types.join(',')}") unless request_types.include?(request)

  case request
  when "host"
    resource = "/hosts/#{data}"
  when "application"
    resource = "/applications/#{data}"
  when "service"
    resource = "/services/#{data}"
  when "configuration"
    resource = "/configurations/#{data}"
  end

  RestClient.put("#{noah_url}#{resource}"){ |response, request, result, &block|
    case response.code
    when 200
      Puppet.debug "noah_put(): Returned #{request} #{data} from Noah server #{noah_url}"
      response
    when 404
      Puppet.info "noah_put(): No #{data} of type #{request} available on Noah server #{noah_url}"
    when 500
      Puppet.info "noah_put(): Noah server #{noah_url} returned error"
    else
      response.return!(request, result, &block)
    end
  }
end
