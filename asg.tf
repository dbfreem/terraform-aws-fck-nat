# EIP pool for GWLB mode - one EIP per max ASG instance
resource "aws_eip" "gwlb_pool" {
  count = var.gwlb_enabled ? var.asg_max_size : 0

  domain = "vpc"

  tags = merge({ Name = "${var.name}-${count.index}" }, var.tags)
}

resource "aws_autoscaling_group" "main" {
  count = var.ha_mode ? 1 : 0

  name                = var.name
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = var.gwlb_enabled ? "ELB" : "EC2"
  health_check_grace_period = var.asg_health_check_grace_period

  # Cross-AZ support: use multiple subnets if provided, otherwise fall back to single subnet
  vpc_zone_identifier = length(var.subnet_ids) > 0 ? var.subnet_ids : [var.subnet_id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = lookup(var.tags, "Name", null) == null ? ["Name"] : []

    content {
      key                 = "Name"
      value               = var.name
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTotalCapacity",
    "WarmPoolDesiredCapacity",
    "WarmPoolWarmedCapacity",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTotalCapacity",
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity"
  ]

  timeouts {
    delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target tracking scaling policy - CPU utilization
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  count = var.ha_mode && var.asg_dynamic_scaling_enabled && var.asg_cpu_target_tracking_enabled ? 1 : 0

  name                   = "${var.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.main[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = var.asg_cpu_target_value
    disable_scale_in = var.asg_disable_scale_in
  }
}

# Target tracking scaling policy - Network In
resource "aws_autoscaling_policy" "network_in_target_tracking" {
  count = var.ha_mode && var.gwlb_enabled && var.asg_dynamic_scaling_enabled && var.asg_network_in_target_tracking_enabled ? 1 : 0

  name                   = "${var.name}-network-in-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.main[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkIn"
    }
    target_value     = var.asg_network_in_target_value
    disable_scale_in = var.asg_disable_scale_in
  }
}

# Target tracking scaling policy - Network Out
resource "aws_autoscaling_policy" "network_out_target_tracking" {
  count = var.ha_mode && var.gwlb_enabled && var.asg_dynamic_scaling_enabled && var.asg_network_out_target_tracking_enabled ? 1 : 0

  name                   = "${var.name}-network-out-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.main[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkOut"
    }
    target_value     = var.asg_network_out_target_value
    disable_scale_in = var.asg_disable_scale_in
  }
}

# Scale out policy (step scaling)
resource "aws_autoscaling_policy" "scale_out" {
  count = var.ha_mode && var.gwlb_enabled && var.asg_dynamic_scaling_enabled && var.asg_step_scaling_enabled ? 1 : 0

  name                   = "${var.name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.main[0].name
  policy_type            = "StepScaling"
  adjustment_type        = "ChangeInCapacity"

  step_adjustment {
    scaling_adjustment          = var.asg_scale_out_adjustment
    metric_interval_lower_bound = 0
  }
}

# Scale in policy (step scaling)
resource "aws_autoscaling_policy" "scale_in" {
  count = var.ha_mode && var.gwlb_enabled && var.asg_dynamic_scaling_enabled && var.asg_step_scaling_enabled ? 1 : 0

  name                   = "${var.name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.main[0].name
  policy_type            = "StepScaling"
  adjustment_type        = "ChangeInCapacity"

  step_adjustment {
    scaling_adjustment          = var.asg_scale_in_adjustment
    metric_interval_upper_bound = 0
  }
}

# CloudWatch alarm for scale out
resource "aws_cloudwatch_metric_alarm" "scale_out" {
  count = var.ha_mode && var.gwlb_enabled && var.asg_dynamic_scaling_enabled && var.asg_step_scaling_enabled ? 1 : 0

  alarm_name          = "${var.name}-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.asg_scale_out_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.asg_scale_out_period
  statistic           = "Average"
  threshold           = var.asg_scale_out_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out[0].arn]

  tags = merge({ Name = "${var.name}-scale-out-alarm" }, var.tags)
}

# CloudWatch alarm for scale in
resource "aws_cloudwatch_metric_alarm" "scale_in" {
  count = var.ha_mode && var.gwlb_enabled && var.asg_dynamic_scaling_enabled && var.asg_step_scaling_enabled ? 1 : 0

  alarm_name          = "${var.name}-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.asg_scale_in_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.asg_scale_in_period
  statistic           = "Average"
  threshold           = var.asg_scale_in_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in[0].arn]

  tags = merge({ Name = "${var.name}-scale-in-alarm" }, var.tags)
}
