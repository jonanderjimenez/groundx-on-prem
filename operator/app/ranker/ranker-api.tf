resource "helm_release" "ranker_api_service" {
  count      = local.ingest_only ? 0 : 1

  name       = "${var.ranker_internal.service}-api"
  namespace  = var.app_internal.namespace

  chart      = "${local.module_path}/ranker/api/helm_chart"

  values = [
    yamlencode({
      busybox         = var.app_internal.busybox
      dependencies    = {
        cache         = "${local.cache_settings.addr} ${local.cache_settings.port}"
      }
      image           = {
        pull          = var.ranker_internal.api.image.pull
        repository    = "${var.app_internal.repo_url}/${var.ranker_internal.api.image.repository}${local.container_suffix}"
        tag           = var.ranker_internal.api.image.tag
      }
      local           = var.cluster.environment == "local"
      nodeSelector    = {
        node          = local.node_assignment.ranker_api
      }
      tolerations   = [
        {
          key    = "node"
          value  = local.node_assignment.ranker_api
          effect = "NoSchedule"
        }
      ]
      replicas        = {
        cooldown      = var.ranker_resources.api.replicas.cooldown
        max           = local.replicas.ranker.api.max
        min           = local.replicas.ranker.api.min
        threshold     = var.ranker_resources.api.replicas.threshold
      }
      resources       = var.ranker_resources.api.resources
      securityContext = {
        runAsUser     = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
      }
      service         = {
        name          = "${var.ranker_internal.service}-api"
        namespace     = var.app_internal.namespace
        version       = var.ranker_internal.version
      }
    })
  ]
}