output "stack_version" {
  value = local.stack_version
}

output "compute_nodes" {
  value = module.compute.compute_nodes
}
