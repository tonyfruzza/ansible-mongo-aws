#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'aws-sdk'

class Ec2Tag2Instance
  def initialize
    @region = Net::HTTP.get('169.254.169.254', '/latest/meta-data/placement/availability-zone').gsub(/[a-z]$/, '')
    @ec2 = Aws::EC2::Client.new(region: @region)
    sleep 1 while !are_tags_available?
  end

  def region
    @region
  end

  def get_instance_id
   return Net::HTTP.get('169.254.169.254', '/latest/meta-data/instance-id')
  end

  def get_instance_desc(instance = nil)
    limit_instance = [ instance ] if instance
    @ec2.describe_instances({instance_ids: limit_instance})
  end

  def are_tags_available?
    return true if get_instance_desc.to_h[:reservations].first[:instances].first[:tags].find{|tag| tag[:key] == 'Name' && !tag[:value].empty?}
  end

  def get_mongo_machines
    get_instance_desc.to_h[:reservations].select do |i|
      i[:instances].first[:tags].find{|tag| tag[:key] == 'Role' && tag[:value] == 'mongo'}
    end
  end

  # based on the tag DNS-Name
  def what_should_my_dns_be?
    get_instance_desc(get_instance_id).to_h[:reservations].first[:instances].first[:tags].find{|tag| tag[:key] == 'DNS-Name'}[:value]
  end

  def whats_my_ip?
    return Net::HTTP.get('169.254.169.254', '/latest/meta-data/local-ipv4')
  end
end

class R53Change
  def initialize(region, zone_id, assume_role = nil)
    if assume_role
      sts = Aws::STS::Client.new(region: region)
      resp = sts.assume_role({
        duration_seconds: 900,
        role_arn: assume_role,
        role_session_name: 'ansible-r53-mongo-change'
      })
      creds = resp.credentials.to_h
      creds.delete(:expiration)
      @r53 = Aws::Route53::Client.new(region: region,
        credentials: Aws::Credentials.new(
          creds[:access_key_id],
          creds[:secret_access_key],
          creds[:session_token]
        ))
    else
      @r53 = Aws::Route53::Client.new(region: region)
    end
    @zid = zone_id
  end

  def update_record(name, ip)
    @r53.change_resource_record_sets({
      change_batch: {
        changes: [
          {
            action: "UPSERT",
            resource_record_set: {
              name: name,
              resource_records: [{ value: ip }],
              ttl: 60,
              type: 'A'
            }
          }
        ],
        comment: "Mongo internal address",
      },
      hosted_zone_id: @zid,
    })
  end
end

File.open(ARGV[0]) do |fh|
  data = JSON.parse(fh.read)
  unless data['hosted_zone_id']
    return JSON.dump({
      failed: true,
      msg: 'set hosted_zone_id value'
    })

  etags = Ec2Tag2Instance.new
  ret = {
    dns_cname: e_tags.what_should_my_dns_be?,
    dns_ip: e_tags.whats_my_ip?
  }

  r = R53Change.new(
    etags.region,
    data['hosted_zone_id'],
    nill unless data['assume_role_arn']
  )
  r.update_record(etags.what_should_my_dns_be?, etags.whats_my_ip?)

  print JSON.dump(ret)
end
