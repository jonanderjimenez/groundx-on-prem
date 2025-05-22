resource "helm_release" "layout_webhook_service" {
  name       = var.layout_webhook_internal.service
  namespace  = var.app_internal.namespace
  chart      = "${local.module_path}/layout-webhook/helm_chart"

  values = [
    yamlencode({
      busybox         = var.app_internal.busybox
      dependencies    = {
        groundx       = "${var.groundx_internal.service}.${var.app_internal.namespace}.svc.cluster.local"
      }
      image           = {
        pull          = var.layout_webhook_internal.image.pull
        repository    = "${var.app_internal.repo_url}/${var.layout_webhook_internal.image.repository}${local.container_suffix}"
        tag           = var.layout_webhook_internal.image.tag
      }
      local           = var.cluster.environment == "local"
      nodeSelector    = {
        node          = local.node_assignment.layout_webhook
        tolerations   = [
          {
            key    = "node"
            value  = local.node_assignment.layout_webhook
            effect = "NoSchedule"
          }
        ]
      }
      replicas        = {
        cooldown      = var.layout_webhook_resources.replicas.cooldown
        max           = local.replicas.layout_webhook.max
        min           = local.replicas.layout_webhook.min
        threshold     = var.layout_webhook_resources.replicas.threshold
      }
      resources       = var.layout_webhook_resources.resources
      securityContext = {
        runAsUser     = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
        runAsGroup    = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
        fsGroup       = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
      }
      service         = {
        name          = var.layout_webhook_internal.service
        namespace     = var.app_internal.namespace
        version       = var.layout_webhook_internal.version
      }
    })
  ]
}