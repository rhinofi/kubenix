{ config, lib, pkgs, kubenix, helm, k8sVersion, ... }:

with lib;
with kubenix.lib;
with pkgs.dockerTools;

let
  corev1 = config.kubernetes.api.resources.core.v1;
  appsv1 = config.kubernetes.api.resources.apps.v1;

  postgresql = pullImage {
    imageName = "docker.io/bitnami/postgresql";
    imageDigest = "sha256:ec16eb9ff2e7bf0669cfc52e595f17d9c52efd864c3f943f404d525dafaaaf96";
    sha256 = "sha256-xdAUnAve0CWgMlEnDo9RzZJdizoFQX1upg8Huf9FWYo=";
    finalImageTag = "11.7.0-debian-10-r55";
  };

  postgresqlExporter = pullImage {
    imageName = "docker.io/bitnami/postgres-exporter";
    imageDigest = "sha256:08ab46104b83834760a5e0329af11de23ccf920b4beffd27c506f34421920313";
    sha256 = "sha256-59ZkRBx4eMHBTloVr4PMbuUagpFZ0gcFBxRKC1Q4URI=";
    finalImageTag = "0.8.0-debian-10-r66";
  };

  minideb = pullImage {
    imageName = "docker.io/bitnami/minideb";
    imageDigest = "sha256:2f430acaa0ffd88454ac330a6843840f1e1204007bf92f8ce7b654fd3b558d68";
    sha256 = "sha256-b6DI1JYpVkgSVA3Ln28E0s82+gEv6LBMLUWCZ9PAGaA=";
    finalImageTag = "buster";
  };
in {
  imports = [ kubenix.modules.test kubenix.modules.helm kubenix.modules.k8s ];

  test = {
    name = "helm-simple";
    description = "Simple k8s testing wheter name, apiVersion and kind are preset";
    assertions = [{
      message = "should have generated resources";
      assertion =
        appsv1.StatefulSet ? "app-psql-postgresql-master" &&
        appsv1.StatefulSet ? "app-psql-postgresql-slave" &&
        corev1.Secret ? "app-psql-postgresql" &&
        corev1.Service ? "app-psql-postgresql-headless" ;
    } {
      message = "should have values passed";
      assertion = appsv1.StatefulSet.app-psql-postgresql-slave.spec.replicas == 2;
    } {
      message = "should have namespace defined";
      assertion =
        appsv1.StatefulSet.app-psql-postgresql-master.metadata.namespace == "test";
    }];
    testScript = ''
      $kube->waitUntilSucceeds("docker load < ${postgresql}");
      $kube->waitUntilSucceeds("docker load < ${postgresqlExporter}");
      $kube->waitUntilSucceeds("docker load < ${minideb}");
      $kube->waitUntilSucceeds("kubectl apply -f ${config.kubernetes.result}");
      $kube->waitUntilSucceeds("PGPASSWORD=postgres ${pkgs.postgresql}/bin/psql -h app-psql-postgresql.test.svc.cluster.local -U postgres -l");
    '';
  };

  kubernetes.version = k8sVersion;

  kubernetes.resources.namespaces.test = {};

  kubernetes.helm.instances.app-psql = {
    namespace = "test";
    chart = helm.fetch {
      repo = "https://charts.bitnami.com/bitnami";
      chart = "postgresql";
      version = "8.6.13";
      sha256 = "pYJuxr5Ec6Yjv/wFn7QAA6vCiVjNTz1mWoexdxwiEzE=";
    };

    values = {
      image = {
        repository = "bitnami/postgresql";
        tag = "10.7.0";
        pullPolicy = "IfNotPresent";
      };
      volumePermissions.image = {
        repository = "bitnami/minideb";
        tag = "latest";
        pullPolicy = "IfNotPresent";
      };
      metrics.image = {
        repository = "wrouesnel/postgres_exporter";
        tag = "v0.4.7";
        pullPolicy = "IfNotPresent";
      };
      replication.enabled = true;
      replication.slaveReplicas = 2;
      postgresqlPassword = "postgres";
      persistence.enabled = false;
    };
  };
}
