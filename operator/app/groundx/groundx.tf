resource "helm_release" "groundx_service" {
  name       = var.groundx_internal.service
  namespace  = var.app_internal.namespace
  chart      = "${local.module_path}/groundx/helm_chart"
  timeout = 600
  values = [
    yamlencode({
      busybox         = var.app_internal.busybox
      dependencies    = {
        cache         = "${local.cache_settings.addr} ${local.cache_settings.port}"
        database      = "${local.db_endpoints.ro} ${local.db_endpoints.port}"
        file          = "${local.file_settings.dependency} ${local.file_settings.port}"
        search        = "${local.search_settings.base_domain} ${local.search_settings.port}"
        stream        = "${local.stream_settings.base_domain} ${local.stream_settings.port}"
      }
      image           = {
        pull          = var.groundx_internal.image.pull
        repository    = "${var.app_internal.repo_url}/${var.groundx_internal.image.repository}${local.container_suffix}"
        tag           = var.groundx_internal.image.tag
      }
      ingestOnly      = local.ingest_only
      local           = var.cluster.environment == "local"
      nodeSelector = {
        node = local.node_assignment.groundx
      }
      tolerations = [
        {
          key    = "node"
          value  = local.node_assignment.groundx
          effect = "NoSchedule"
        }
      ]
      replicas        = {
        cooldown      = var.groundx_resources.replicas.cooldown
        max           = local.replicas.groundx.max
        min           = local.replicas.groundx.min
        threshold     = var.groundx_resources.replicas.threshold
      }
      resources       = var.groundx_resources.resources
      securityContext = {
        runAsUser     = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
        runAsGroup    = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
        fsGroup       = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
      }
      service = {
        name          = var.groundx_internal.service
        namespace     = var.app_internal.namespace
      }
    })
  ]
}