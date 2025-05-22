resource "helm_release" "pre_process_service" {
  name       = var.pre_process_internal.service
  namespace  = var.app_internal.namespace
  chart      = "${local.module_path}/pre-process/helm_chart"

  values = [
    yamlencode({
      busybox         = var.app_internal.busybox
      dependencies    = {
        groundx       = "${var.groundx_internal.service}.${var.app_internal.namespace}.svc.cluster.local"
      }
      image           = {
        pull          = var.pre_process_internal.image.pull
        repository    = "${var.app_internal.repo_url}/${var.pre_process_internal.image.repository}${local.container_suffix}"
        tag           = var.pre_process_internal.image.tag
      }
      local           = var.cluster.environment == "local"
      nodeSelector    = {
        node          = local.node_assignment.pre_process
        tolerations   = [
          {
            key    = "node"
            value  = local.node_assignment.pre_process 
            effect = "NoSchedule"
          }
        ]
      }
      replicas        = {
        cooldown      = var.pre_process_resources.replicas.cooldown
        max           = local.replicas.pre_process.max
        min           = local.replicas.pre_process.min
        threshold     = var.pre_process_resources.replicas.threshold
      }
      resources       = var.pre_process_resources.resources
      securityContext = {
        runAsUser     = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
        runAsGroup    = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
        fsGroup       = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
      }
      service         = {
        name          = var.pre_process_internal.service
        namespace     = var.app_internal.namespace
        version       = var.pre_process_internal.version
      }
    })
  ]
}