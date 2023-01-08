#!/usr/bin/ruby


require 'net/http'
require 'nokogiri'
require 'json'
require 'pg'


def fetch_capacity_items(uri_str)
  res = Net::HTTP.get_response(URI(uri_str))

  case res
  when Net::HTTPOK, Net::HTTPSuccess
    doc = Nokogiri::HTML.parse(res.body)
    items = doc.xpath("//bath-capacity-item")
  
    units = {}
    items.each do |item|
      units[item.attributes['organization-unit-id'].content] = item.attributes['bath-name'].content
    end

    units
  else
    raise "Unable to fetch #{uri_str}"
  end
end


def fetch_capacity(items)
  uri = URI('https://functions.api.ticos-systems.cloud/')
  tenant_id = 69

  now = Time.new.to_i
  capacity = {}


  Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|

    items.each do |unit_id, unit_name|
      req = Net::HTTP::Get.new("/api/gates/counter?organizationUnitIds=#{unit_id}")
      req['abp-tenantid'] = tenant_id

      res = http.request(req)

      case res
      when Net::HTTPSuccess
        unit = JSON.parse(res.body)[0]
        capacity[unit_id] = unit
        capacity[unit_id]['requestTime'] = now
        capacity[unit_id]['organizationUnitName'] = unit_name
        capacity[unit_id]['utilizationPercent'] = (unit['personCount'].to_f / unit['maxPersonCount'].to_f * 100.0).to_i
      else
        raise "Unable to fetch capacity of unit #{id}"
      end
    end
  }

  capacity
end


def pg_table_exist?(conn, table, schema = 'public')
  res = conn.exec "SELECT to_regclass('#{schema}.#{table}');"
  if res.getvalue(0,0) == table
    true
  else
    false
  end
end


def pg_update(pg_login, capacity)
  conn = PG.connect(pg_login)
 
  unless pg_table_exist?(conn, 'units')
    conn.exec 'CREATE TABLE units (unit_id INT PRIMARY KEY, unit_name VARCHAR(127), kind_of VARCHAR(63))'
  end

  units = conn.exec('SELECT unit_id, unit_name FROM units')

  capacity.each do |unit_id, data|
    table = "unit_#{unit_id}"

    unless pg_table_exist?(conn, table)
      conn.exec "CREATE TABLE #{table} (timestamp TIMESTAMPTZ PRIMARY KEY, unit_id INT NOT NULL, utilization_percent INT, person_count INT, max_person_count INT)"
    end

    conn.exec "INSERT INTO #{table} (timestamp, unit_id, utilization_percent, person_count, max_person_count) VALUES ( to_timestamp(#{data['requestTime']}), #{data['organizationUnitId']}, #{data['utilizationPercent']}, #{data['personCount']}, #{data['maxPersonCount']} )"

    unit = units.select {|row| row['unit_id'] == unit_id.to_s }
    if unit.size == 1
      unless unit[0]['unit_name'] == data['organizationUnitName']
        conn.exec "UPDATE units SET unit_name = \'#{data['organizationUnitName']}\' WHERE unit_id = #{unit_id}"
      end
    else
      conn.exec "INSERT INTO units (unit_id, unit_name) VALUES (#{data['organizationUnitId']}, \'#{data['organizationUnitName']}\')"
    end
  end
end

items = fetch_capacity_items('https://www.swm.de/baeder/schwimmen-sauna/auslastung')
#puts items

capacity = fetch_capacity(items)
#puts JSON.pretty_generate(capacity)


pg_login = {
  dbname:   ENV['PG_DBNAME']   || 'swmcapacity',
  host:     ENV['PG_HOST']     || nil,
  user:     ENV['PG_USER']     || nil,
  password: ENV['PG_PASSWORD'] || nil,
}
pg_update(pg_login, capacity)

