variable "cluster_name" {
  default = "TPM-Beta-Demo"
}

variable "vpc_flow_logs_s3_arn" {
  description = "S3 ARN for VPC Flow Logs. If provided, VPC Flow Logs will be enabled"
  type        = string
  default     = ""
}

provider "aws" {
  region = "us-east-1" # Change as needed
}

# --- VPC ---
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# --- Public Subnets ---
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.141.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name                   = "${var.cluster_name}-public-subnet-1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.142.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name                   = "${var.cluster_name}-public-subnet-2"
    "kubernetes.io/role/elb" = "1"
  }
}

# --- Private Subnet ---
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.143.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Name                   = "${var.cluster_name}-private-subnet"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# --- Public Route Table ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name = "${var.cluster_name}-public-route-table"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# --- NAT Gateway for Private Subnet ---
resource "aws_eip" "nat_eip" {}

resource "aws_nat_gateway" "eks_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "${var.cluster_name}-nat-gateway"
  }
}

# --- Private Route Table ---
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_nat.id
  }
  tags = {
    Name = "${var.cluster_name}-private-route-table"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  version  = "1.31"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id,
      aws_subnet.private_subnet.id
    ]
  }

  tags = {
    Name = var.cluster_name
  }
}

# --- IAM Role for EKS Cluster ---
resource "aws_iam_role" "eks_role" {
  name = "${var.cluster_name}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS Node Group with t3.small and Illumio Labels ---
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.worker_nodes.arn
  subnet_ids      = [aws_subnet.private_subnet.id]
  instance_types  = ["t3.medium"]
  disk_size       = 100  # disk size in GB

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  labels = {
    "illumio.com/env"        = "production"
    "illumio.com/app"        = "wordpress"
    "illumio.com/role"       = "worker-node"
    "illumio.com/owner"      = "TPM"
    "illumio.com/namespace"  = "default"
    "illumio.com/region"     = "us-east-1"
  }

  tags = {
    Name = "${var.cluster_name}-EKS-Nodes"
  }
}

# --- IAM Role for Worker Nodes ---
resource "aws_iam_role" "worker_nodes" {
  name = "${var.cluster_name}-worker-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.worker_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_cni_policy" {
  role       = aws_iam_role.worker_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "worker_ec2_policy" {
  role       = aws_iam_role.worker_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --- VPC Flow Logs (Optional) ---
resource "aws_flow_log" "vpc_flow_log" {
  count                = var.vpc_flow_logs_s3_arn != "" ? 1 : 0
  log_destination      = var.vpc_flow_logs_s3_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}-vpc-flow-logs"
  }
}

