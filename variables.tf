variable "name" {
  description = "Name used for resources created within the module"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the NAT instance into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to deploy the NAT instance into"
  type        = string
}

variable "update_route_table" {
  description = "Deprecated. Use update_route_tables instead"
  type        = bool
  default     = false
}

variable "update_route_tables" {
  description = "Whether or not to update the route tables with the NAT instance"
  type        = bool
  default     = false
}

variable "route_table_id" {
  description = "Deprecated. Use route_tables_ids instead"
  type        = string
  default     = null
}

variable "route_tables_ids" {
  description = "Route tables to update. Only valid if update_route_tables is true"
  type        = map(string)
  default     = {}
}

variable "encryption" {
  description = "Whether or not to encrypt the EBS volume"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Will use the provided KMS key ID to encrypt the EBS volume. Uses the default KMS key if none provided"
  type        = string
  default     = null
}

variable "ha_mode" {
  description = "Whether or not high-availability mode should be enabled via autoscaling group"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "Instance type to use for the NAT instance"
  type        = string
  default     = "t4g.micro"
}

variable "ami_id" {
  description = "AMI to use for the NAT instance. Uses fck-nat latest AMI in the region if none provided"
  type        = string
  default     = null
}

variable "ebs_root_volume_size" {
  description = "Size of the EBS root volume in GB"
  type        = number
  default     = 8
}

variable "eip_allocation_ids" {
  description = "EIP allocation IDs to use for the NAT instance. Automatically assign a public IP if none is provided. Note: Currently only supports at most one EIP allocation."
  type        = list(string)
  default     = []
}

variable "attach_ssm_policy" {
  description = "Whether to attach the minimum required IAM permissions to connect to the instance via SSM."
  type        = bool
  default     = true
}

variable "credit_specification" {
  description = "Customize the credit specification of the instance"
  type        = string
  default     = null
}

variable "use_spot_instances" {
  description = "Whether or not to use spot instances for running the NAT instance"
  type        = bool
  default     = false
}

variable "use_cloudwatch_agent" {
  description = "Whether or not to enable CloudWatch agent for the NAT instance"
  type        = bool
  default     = false
}

variable "cloudwatch_agent_configuration" {
  description = "CloudWatch configuration for the NAT instance"
  type = object({
    namespace           = optional(string, "fck-nat"),
    collection_interval = optional(number, 60),
    endpoint_override   = optional(string, "")
  })
  default = {
    namespace           = "fck-nat"
    collection_interval = 60
    endpoint_override   = ""
  }
}

variable "cloudwatch_agent_configuration_param_arn" {
  description = "ARN of the SSM parameter containing the CloudWatch agent configuration. If none provided, creates one"
  type        = string
  default     = null
}

variable "use_default_security_group" {
  description = "Whether or not to use the default security group for the NAT instance"
  type        = bool
  default     = true
}

variable "additional_security_group_ids" {
  description = "A list of identifiers of security groups to be added for the NAT instance"
  type        = list(string)
  default     = []
}

variable "use_ssh" {
  description = "Whether or not to enable SSH access to the NAT instance"
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "Name of the SSH key to use for the NAT instance. SSH access will be enabled only if a key name is provided"
  type        = string
  default     = null
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks to allow SSH access to the NAT instance from"
  type = object({
    ipv4 = optional(list(string), [])
    ipv6 = optional(list(string), [])
  })
  default = {
    ipv4 = [],
    ipv6 = []
  }
}

variable "tags" {
  description = "Tags to apply to resources created within the module"
  type        = map(string)
  default     = {}
}

variable "cloud_init_parts" {
  description = "Cloud-init parts to add to the user data script"
  type = list(object({
    content      = string
    content_type = string
  }))
  default = []
}

variable "gwlb_enabled" {
  description = "Enables the Gateway Load Balancer integration"
  type        = bool
  default     = false  
}

variable "gwlb_health_check_port" {
  description = "The Gateway Load Balancer health check port"
  type        = number
  default     = 8008
}

# GWLB additional configuration
variable "gwlb_subnet_ids" {
  description = "Subnet IDs for the Gateway Load Balancer deployment"
  type        = list(string)
  default     = []
}

variable "gwlb_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing for the Gateway Load Balancer"
  type        = bool
  default     = false
}

variable "gwlb_health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks required to mark target as healthy"
  type        = number
  default     = 3
}

variable "gwlb_health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks required to mark target as unhealthy"
  type        = number
  default     = 3
}

variable "gwlb_health_check_interval" {
  description = "Time between health checks in seconds"
  type        = number
  default     = 30
}

variable "gwlb_endpoint_service_enabled" {
  description = "Enable VPC Endpoint Service for the Gateway Load Balancer"
  type        = bool
  default     = false
}

variable "gwlb_endpoint_service_acceptance_required" {
  description = "Whether acceptance is required for VPC Endpoint Service connections"
  type        = bool
  default     = true
}

variable "gwlb_endpoint_service_allowed_principals" {
  description = "List of ARNs of principals allowed to discover the endpoint service"
  type        = list(string)
  default     = []
}

variable "gwlb_endpoint_subnet_ids" {
  description = "List of subnet IDs for GWLB VPC endpoint (spans multiple AZs)"
  type        = list(string)
  default     = []
}

# Cross-AZ ASG configuration
variable "subnet_ids" {
  description = "List of subnet IDs for cross-AZ ASG deployment. If provided, takes precedence over subnet_id"
  type        = list(string)
  default     = []
}

# ASG capacity configuration
variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_health_check_grace_period" {
  description = "Time after instance comes into service before checking health"
  type        = number
  default     = 300
}

# Dynamic scaling configuration
variable "asg_dynamic_scaling_enabled" {
  description = "Enable dynamic scaling policies for the Auto Scaling Group"
  type        = bool
  default     = false
}

variable "asg_disable_scale_in" {
  description = "Disable scale-in for target tracking policies"
  type        = bool
  default     = false
}

# CPU target tracking
variable "asg_cpu_target_tracking_enabled" {
  description = "Enable CPU utilization target tracking scaling policy"
  type        = bool
  default     = false
}

variable "asg_cpu_target_value" {
  description = "Target CPU utilization percentage for target tracking"
  type        = number
  default     = 70
}

# Network In target tracking
variable "asg_network_in_target_tracking_enabled" {
  description = "Enable Network In target tracking scaling policy"
  type        = bool
  default     = false
}

variable "asg_network_in_target_value" {
  description = "Target Network In bytes for target tracking"
  type        = number
  default     = 100000000 # 100 MB
}

# Network Out target tracking
variable "asg_network_out_target_tracking_enabled" {
  description = "Enable Network Out target tracking scaling policy"
  type        = bool
  default     = false
}

variable "asg_network_out_target_value" {
  description = "Target Network Out bytes for target tracking"
  type        = number
  default     = 100000000 # 100 MB
}

# Step scaling configuration
variable "asg_step_scaling_enabled" {
  description = "Enable step scaling policies with CloudWatch alarms"
  type        = bool
  default     = false
}

variable "asg_scale_out_adjustment" {
  description = "Number of instances to add when scaling out"
  type        = number
  default     = 1
}

variable "asg_scale_in_adjustment" {
  description = "Number of instances to remove when scaling in (use negative number)"
  type        = number
  default     = -1
}

variable "asg_scale_out_threshold" {
  description = "CPU threshold percentage for scale out alarm"
  type        = number
  default     = 80
}

variable "asg_scale_in_threshold" {
  description = "CPU threshold percentage for scale in alarm"
  type        = number
  default     = 30
}

variable "asg_scale_out_evaluation_periods" {
  description = "Number of evaluation periods for scale out alarm"
  type        = number
  default     = 2
}

variable "asg_scale_in_evaluation_periods" {
  description = "Number of evaluation periods for scale in alarm"
  type        = number
  default     = 2
}

variable "asg_scale_out_period" {
  description = "Period in seconds for scale out alarm evaluation"
  type        = number
  default     = 60
}

variable "asg_scale_in_period" {
  description = "Period in seconds for scale in alarm evaluation"
  type        = number
  default     = 60
}