resource "helm_release" "ranker_inference_service" {
  count      = local.ingest_only ? 0 : 1

  depends_on = [helm_release.ranker_model_pv]

  name       = "${var.ranker_internal.service}-inference"
  namespace  = var.app_internal.namespace

  chart      = "${local.module_path}/ranker/inference/helm_chart"

  timeout    = 1200

  values = [
    yamlencode({
      busybox         = var.app_internal.busybox
      createSymlink   = local.is_openshift ? false : true
      dependencies    = {
        cache         = "${local.cache_settings.addr} ${local.cache_settings.port}"
      }
      image           = {
        pull          = var.ranker_internal.inference.image.pull
        repository    = "${var.app_internal.repo_url}/${var.ranker_internal.inference.image.repository}${local.op_container_suffix}"
        tag           = var.ranker_internal.inference.image.tag
      }
      local           = var.cluster.environment == "local"
      model           = local.ranker_model.version
      nodeSelector    = {
        node          = local.node_assignment.ranker_inference
        tolerations = [
          {
            key    = "node"
            value  = local.node_assignment.ranker_inference
            effect = "NoSchedule"
          }
        ]
      }
      pv              = {
        access        = var.ranker_internal.inference.pv.access
        capacity      = var.ranker_internal.inference.pv.capacity
        name          = "${var.ranker_internal.service}-model"
      }
      replicas        = {
        cooldown      = var.ranker_resources.inference.replicas.cooldown
        max           = coalesce(max(1, ceil(local.baseline_search / local.ranker_model.throughput)), local.replicas.ranker.inference.max)
        min           = coalesce(max(1, ceil(local.baseline_search / local.ranker_model.throughput)), local.replicas.ranker.inference.min)
        threshold     = var.ranker_resources.inference.replicas.threshold
      }
      resources       = var.ranker_resources.inference.resources
      securityContext = {
        runAsUser     = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
      }
      service = {
        name          = "${var.ranker_internal.service}-inference"
        namespace     = var.app_internal.namespace
        version       = var.ranker_internal.version
      }
    })
  ]
}