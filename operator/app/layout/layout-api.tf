resource "helm_release" "layout_api_service" {
  name       = "${var.layout_internal.service}-api"
  namespace  = var.app_internal.namespace

  chart      = "${local.module_path}/layout/api/helm_chart"

  values = [
    yamlencode({
      busybox         = var.app_internal.busybox
      dependencies    = {
        cache         = "${local.cache_settings.addr} ${local.cache_settings.port}"
      }
      image           = {
        pull          = var.layout_internal.api.image.pull
        repository    = "${var.app_internal.repo_url}/${var.layout_internal.api.image.repository}${local.container_suffix}"
        tag           = var.layout_internal.api.image.tag
      }
      local           = var.cluster.environment == "local"
      nodeSelector    = {
        node          = local.node_assignment.layout_api
        tolerations   = [
          {
            key    = "node"
            value  = local.node_assignment.layout_api
            effect = "NoSchedule"
          }
        ]
      }
      replicas        = {
        cooldown      = var.layout_resources.api.replicas.cooldown
        max           = local.replicas.layout.api.max
        min           = local.replicas.layout.api.min
        threshold     = var.layout_resources.api.replicas.threshold
      }
      resources       = var.layout_resources.api.resources
      securityContext = {
        runAsUser     = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
      }
      service         = {
        name          = "${var.layout_internal.service}-api"
        namespace     = var.app_internal.namespace
        version       = var.layout_internal.version
      }
    })
  ]
}