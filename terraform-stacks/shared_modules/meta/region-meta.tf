# fetch the metadata of regionInfo from IMDS
data "external" "instance_regionInfo" {
  program = ["bash", "-c", "r=$(curl -s --connect-timeout 5 --max-time 10 -H 'Authorization: Bearer Oracle' http://169.254.169.254/opc/v2/instance/regionInfo 2>/dev/null); case \"$r\" in \\{*) echo \"$r\";; *) echo '{}';; esac"]
}

locals {
  region_metadata    = try(data.external.instance_regionInfo.result, {})
  metadata_available = lookup(local.region_metadata, "realmDomainComponent", "error") != "error"
}
