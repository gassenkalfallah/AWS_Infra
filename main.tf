provider "aws" {
  region = "eu-west-3"
  
}
# terraform {
#   backend "http" {
#     address = "https://gitlab.spark.local/api/v4/projects/infra%2FStagiaires%2Faws/terraform/state/terraform.tfstate"
    
#     username = "gitlab"
#     password = "****************"
#   }
# }

data "aws_availability_zones" "azs" {}

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  

  name            = "myapp-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}
data "aws_eks_cluster" "myapp-cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "myapp-cluster" {
  name = module.eks.cluster_id
}
provider "kubernetes" {
  #config_path             = var.kubeconfig
  host                    = data.aws_eks_cluster.myapp-cluster.endpoint
  token                   = data.aws_eks_cluster_auth.myapp-cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority.0.data)
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.4.0"
  cluster_name    = "myapp-eks-cluster"
  cluster_version = "1.22"
  subnets = module.myapp-vpc.private_subnets
  vpc_id  = module.myapp-vpc.vpc_id
  tags = {}
  worker_groups = [
    {
      name_prefix      = "eks-worker"
      instance_type    = "t2.medium"
      asg_desired_size = 2
      asg_max_size     = 2
    }
  ]
}

# data "aws_ecr_repository" "example" {
#   name = aws_ecr_repository.example.name
# }

# resource "null_resource" "ecr-registry-secret" {

#   provisioner "local-exec" {

#     command = <<EOF

#     aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin ***********************
#     kubectl create secret docker-registry ecr-registry --docker-server=949351973512.dkr.ecr.eu-west-3.amazonaws.com --docker-username=AWS --docker-password="$(aws ecr get-login-password --region eu-west-3)" --docker-email=unusedb

#     EOF

#   }

# }
resource "aws_ecr_repository" "example" {
  name                 = "example"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

provider "helm" {
  kubernetes {
    config_path             = var.kubeconfig
    host                    = data.aws_eks_cluster.myapp-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority.0.data)
  }
}



# module "velero" {
#   source  = "terraform-module/velero/kubernetes"
#   version = "~> 1"

#   count = 1

#   namespace_deploy            = true
#   app_deploy                  = true
#   cluster_name                = "myapp-eks-cluster"
#   openid_connect_provider_uri = data.aws_eks_cluster.myapp-cluster.identity.0.oidc.0.issuer
#   bucket                      = "ghassentestvelerobucket1"
  
#   tags = {}

#   values = [<<EOF
#   configuration:
#   backupStorageLocations:
#     - name: default
#     - provider: aws
#     - objectStorage:
#       - bucket: "ghassenfinal"
#       - region: "eu-west-3"

#   volumeSnapshotLocations:
#     - name: default
#     - provider: aws
#     - config:
#         region: "eu-west-3"

# credentials:
#   useSecret: false

# initContainers:
#   - name: velero-plugin-for-aws
#     image: velero/velero-plugin-for-aws:v1.2.0
#     volumeMounts:
#       - mountPath: /target
#         name: plugins

# serviceAccount:
#   server:
#     annotations:
#       eks.amazonaws.com/role-arn: "arn:aws:iam::949351973512:role/velero"
#     EOF
#     ]
    
# }

# module "velero" {
#   source  = "terraform-module/velero/kubernetes"
#   version = "1.1.1"
#   namespace_deploy            = true
#   app_deploy                  = true
#   bucket                      = "ghassenfinal"
#   cluster_name                = "myapp-eks-cluster"
#   openid_connect_provider_uri = data.aws_eks_cluster.myapp-cluster.identity.0.oidc.0.issuer
#   values = [<<EOF

# image:
#   repository: velero/velero
#   tag: v1.8.1

# initContainers:
#   - name: velero-plugin-for-aws
#     image: velero/velero-plugin-for-aws:v1.4.1
#     imagePullPolicy: IfNotPresent
#     volumeMounts:
#       - mountPath: /target
#         name: plugins
# installCRDs: true
# securityContext:
#   fsGroup: 1337
# configuration:
#   provider: aws
#   backupStorageLocation:
#     name: default
#     provider: aws
#     bucket: "ghassenfinal"
#     config:
#       region: "eu-west-3"
#   volumeSnapshotLocation:
#     name: default
#     provider: aws
#     config:
#       region: eu-west-3
#   backupSyncPeriod: 24h
#   resticTimeout:
#   restoreResourcePriorities:
#   restoreOnlyMode:

#   extraEnvVars:
#     AWS_CLUSTER_NAME: "myapp-eks-cluster"

#   logLevel: info


# rbac:
#   create: true
#   clusterAdministrator: true

# credentials:

#   useSecret: false

# backupsEnabled: true
# snapshotsEnabled: true
# deployRestic: false
# EOF
#   ]
   

# }
################################################################################



# data "aws_caller_identity" "this" {}

# data "aws_eks_cluster" "this" {
#   name = "myapp-eks-cluster"
# }
# data "aws_secretsmanager_secret_version" "tls_cert_secret" {

# }
# data "tls_certificate" "this" {
#   cert_pem = data.aws_secretsmanager_secret_version.tls_cert_secret.secret_string
# }

# locals {
#   openid_connect_provider_uri = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
# }

# resource "aws_iam_openid_connect_provider" "this" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprin]
#   url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
# }

# module "velero" {
#   source  = "terraform-module/velero/kubernetes"
#   version = "~> 1"

#   count = 1

#   namespace_deploy            = true
#   app_deploy                  = true
#   cluster_name                = "myapp-eks-cluster"
#   openid_connect_provider_uri = local.openid_connect_provider_uri
#   bucket                      = "my-cluster-name"
#   app = {
#     name          = "velero"
#     version       = "2.29.4"
#     chart         = "velero"
#     force_update  = false
#     wait          = true
#     recreate_pods = true
#     deploy        = false
#     max_history   = 1
#     image         = null
#     tag           = null
#   }
#   tags = {}

#   values = [<<EOF
# # https://github.com/vmware-tanzu/helm-charts/tree/master/charts/velero

# image:
#   repository: velero/velero
#   tag: v1.8.1

# # https://aws.amazon.com/blogs/containers/backup-and-restore-your-amazon-eks-cluster-resources-using-velero/
# # https://github.com/vmware-tanzu/velero-plugin-for-aws
# initContainers:
#   - name: velero-plugin-for-aws
#     image: velero/velero-plugin-for-aws:v1.4.1
#     imagePullPolicy: IfNotPresent
#     volumeMounts:
#       - mountPath: /target
#         name: plugins

# # Install CRDs as a templates. Enabled by default.
# installCRDs: true

# # SecurityContext to use for the Velero deployment. Optional.
# # Set fsGroup for `AWS IAM Roles for Service Accounts`
# # see more informations at: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
# securityContext:
#   fsGroup: 1337
#   # fsGroup: 65534

# ##
# ## Parameters for the `default` BackupStorageLocation and VolumeSnapshotLocation,
# ## and additional server settings.
# ##
# configuration:
#   provider: aws

#   backupStorageLocation:
#     name: default
#     provider: aws
#     bucket: "ghassentestvelerobucket"
#     prefix: "velero/sandbox/myapp-eks-cluster"
#     config:
#       region: eu-west-3

#   volumeSnapshotLocation:
#     name: default
#     provider: aws
#     # Additional provider-specific configuration. See link above
#     # for details of required/optional fields for your provider.
#     config:
#       region: eu-west-3

#   # These are server-level settings passed as CLI flags to the `velero server` command. Velero
#   # uses default values if they're not passed in, so they only need to be explicitly specified
#   # here if using a non-default value. The `velero server` default values are shown in the
#   # comments below.
#   # --------------------
#   # `velero server` default: 1m
#   backupSyncPeriod:
#   # `velero server` default: 1h
#   resticTimeout:
#   # `velero server` default: namespaces,persistentvolumes,persistentvolumeclaims,secrets,configmaps,serviceaccounts,limitranges,pods
#   restoreResourcePriorities:
#   # `velero server` default: false
#   restoreOnlyMode:

#   extraEnvVars:
#     AWS_CLUSTER_NAME: myapp-eks-cluster

#   # Set log-level for Velero pod. Default: info. Other options: debug, warning, error, fatal, panic.
#   logLevel: info

# ##
# ## End of backup/snapshot location settings.
# ##

# ##
# ## Settings for additional Velero resources.
# ##
# rbac:
#   create: true
#   clusterAdministrator: true

# credentials:
#   # Whether a secret should be used as the source of IAM account
#   # credentials. Set to false if, for example, using kube2iam or
#   # kiam to provide IAM credentials for the Velero pod.
#   useSecret: false

# backupsEnabled: true
# snapshotsEnabled: true
# deployRestic: false
# EOF
#   ]
# }
