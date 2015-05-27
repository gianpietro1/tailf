class Device

  require 'rest-client'
  require 'json'
  require 'ipaddress'

  def self.base_url
    'http://admin:admin@10.133.6.202:8080/api/running/devices'
  end

  # list of device names
  def self.all
    data = RestClient.get (base_url + '?format=json')
    data_parsed = JSON.parse(data)
    data_parsed["tailf-ncs:devices"]["device"].map do |device|
      device["name"]
    end
  end

  # Get device OS
  def self.ios(hostname)
    data = RestClient.get (base_url + '/device/' + hostname + '/device-type/cli/ned-id?format=json')
    data_parsed = JSON.parse(data)
    if data_parsed["tailf-ncs:ned-id"] == "cisco-ios-xr-id:cisco-ios-xr"   
      'cisco-ios-xr'
    elsif data_parsed["tailf-ncs:ned-id"] == "ios-id:cisco-ios"  
      'cisco-ios'
    elsif data_parsed["tailf-ncs:ned-id"] == "alu-sr-id:alu-sr"  
      'alu-sr'
    end
  end

  # Get interfaces & IPs hash
  def self.interfaces(hostname)

    # variables
      ip_addresses = {}
      intname_array = []
      intnum_array = []
      intport_array = []
      ip_array = []
      mask_array = []
      description_array = []
      ios = self.ios(hostname)

    # interfaces name and number
      if ios == 'cisco-ios-xr'
        data = RestClient.get (base_url + '/device/' + hostname + '/config/cisco-ios-xr:interface?format=json&deep')
      elsif ios == 'cisco-ios'
        data = RestClient.get (base_url + '/device/' + hostname + '/config/ios:interface?format=json&deep')
      elsif ios == 'alu-sr'
        data = RestClient.get (base_url + '/device/' + hostname + '/config/alu:router/Base/interface?format=json&deep')
      end

    # data parsing
      data_parsed = JSON.parse(data)

      if ios == 'alu-sr'
        data_parsed["collection"]["tailf-ned-#{ios}:interface"].map do |interface|
            intport_array << interface['port']
            description_array << interface['description']
            if interface["address"]
              ip = (IPAddress.parse interface["address"]).address
              mask = (IPAddress.parse interface["address"]).netmask
              ip_array << ip
              mask_array << mask
            else
              ip_array << '-'
              mask_array << '-'
            end
            intname_array << interface['interface-name']
        end
      
      else
        data_parsed["tailf-ned-#{ios}:interface"].map do |item|
          data_parsed["tailf-ned-#{ios}:interface"][item[0]].map do |interface|
            if ios == 'cisco-ios-xr'
              intnum_array << interface['id']
              description_array << interface['description']
              if interface["ipv4"]["address"]
                ip_array << interface["ipv4"]["address"]["ip"]
                mask_array << interface["ipv4"]["address"]["mask"]
              else
                ip_array << '-'
                mask_array << '-'
              end
            elsif ios == 'cisco-ios'
              intnum_array << interface['name']
              description_array << interface['description']
              if interface["ip"]["address"]
                ip_array << interface["ip"]["address"]["primary"]["address"]
                mask_array << interface["ip"]["address"]["primary"]["mask"]
              else
                ip_array << '-'
                mask_array << '-'
              end
            end            
            intname_array << item[0]
          end
        end
      end

    # interface merge & ip addresses
      for i in 0..intname_array.count
        intname = intname_array[i].to_s
        intnum = intnum_array[i].to_s
        ip_address = ip_array[i].to_s
        mask_address = mask_array[i].to_s
        description = description_array[i].to_s
        if intport_array[i]
          port = intport_array[i].to_s
        else
          port = ''
        end
        ip_addresses[intname] = [intnum, ip_address, mask_address, description, port]
      end
      
      return ip_addresses

  end

  # Change IP Address
  def self.change_ip(hostname, interface, ip_address, mask)

    int_number = interface[interface.index(/\d+/)..interface.length]
    int_name = interface
    int_name.slice! int_number
    int_number_array = int_number.split("/")
    int_number_string = int_number_array.join("%2F")

    if ios(hostname) == 'cisco-ios-xr'
      ipaddress_changer = Nokogiri::XML::Builder.new do |xml|
          xml.address('xmlns' => "http://tail-f.com/ned/cisco-ios-xr", 'xmlns:y' => "http://tail-f.com/ns/rest", 'xmlns:cisco-ios-xr' => "http://tail-f.com/ned/cisco-ios-xr", 'xmlns:ncs' => "http://tail-f.com/ns/ncs") do
            xml.ip ip_address
            xml.mask mask
          end
      end
      ipaddress_url = "/config/cisco-ios-xr:interface/#{int_name}/#{int_number_string}/ipv4/address?format=xml"

    elsif ios(hostname) == 'cisco-ios'
      ipaddress_changer = Nokogiri::XML::Builder.new do |xml|
          xml.primary('xmlns' => "urn:ios", 'xmlns:y' => "http://tail-f.com/ns/rest", 'xmlns:ios' => "urn:ios", 'xmlns:ncs' => "http://tail-f.com/ns/ncs") do
            xml.address ip_address
            xml.mask mask
          end
      end
      ipaddress_url = "/config/ios:interface/#{int_name}/#{int_number_string}/ip/address/primary?format=xml"
    
    elsif ios(hostname) == 'alu-sr'
      ipaddress_changer = Nokogiri::XML::Builder.new do |xml|
          xml.address('xmlns' => "http://tail-f.com/ned/alu-sr", 'xmlns:y' => "http://tail-f.com/ns/rest", 'xmlns:alu' => "http://tail-f.com/ned/alu-sr", 'xmlns:ncs' => "http://tail-f.com/ns/ncs"){
          xml.text (ip_address + "/" + IPAddr.new(mask).to_i.to_s(2).count("1").to_s)
        }
      end
      ipaddress_url = "/config/alu:router/Base/interface/#{int_name}/address?format=xml"

    end
    
    final_url = (base_url + '/device/' + hostname + ipaddress_url)

    RestClient.patch (final_url), ipaddress_changer.to_xml, :content_type => 'application/vnd.yang.data+xml'

    transaction_data = {interface: (int_name + URI.unescape(int_number_string)), url: URI.unescape(final_url).to_str, xml: ipaddress_changer.to_xml}

    return transaction_data

  end

  def self.sync_from(hostname)
    xml = Nokogiri::XML::Builder.new
    RestClient.post((base_url + '/device/' + hostname + '/sync-from'), xml, :content_type => 'application/vnd.yang.data+xml')
  end

end