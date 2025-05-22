resource "helm_release" "summary_inference_service" {
  count = local.create_summary ? 1 : 0

  depends_on = [helm_release.summary_model_pv]

  name       = "${var.summary_internal.service}-inference"
  namespace  = var.app_internal.namespace

  chart      = "${local.module_path}/summary/inference/helm_chart"

  timeout    = 1800

  values = [
    yamlencode({
      busybox             = var.app_internal.busybox
      createSymlink       = local.is_openshift ? false : true
      dependencies        = {
        cache             = "${local.cache_settings.addr} ${local.cache_settings.port}"
      }
      image               = {
        pull              = var.summary_internal.inference.image.pull
        repository        = "${var.app_internal.repo_url}/${var.summary_internal.inference.image.repository}${local.op_container_suffix}"
        tag               = var.summary_internal.inference.image.tag
      }
      local               = var.cluster.environment == "local"
      nodeSelector        = {
        node              = local.node_assignment.summary_inference
      }
      tolerations         = [
        {
          key              = "node"
          value            = local.node_assignment.summary_inference
          effect           = "NoSchedule"
        }
      ]
      pv                  = {
        access            = var.summary_internal.inference.pv.access
        capacity          = var.summary_internal.inference.pv.capacity
        name              = "${var.summary_internal.service}-model"
      }
      replicas            = {
        cooldown          = var.summary_resources.inference.replicas.cooldown
        max               = local.replicas.summary.inference.max
        min               = local.replicas.summary.inference.min
        threshold         = var.summary_resources.inference.replicas.threshold
      }
      resources           = var.summary_resources.inference.resources
      securityContext     = {
        fsGroup           = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
        runAsUser         = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
        runAsGroup        = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
      }
      service = {
        name              = "${var.summary_internal.service}-inference"
        namespace         = var.app_internal.namespace
        version           = var.summary_internal.version
      }
      waitForDependencies = true
    })
  ]
}