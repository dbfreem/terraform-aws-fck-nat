# Gateway Load Balancer for fck-nat instances
resource "aws_lb" "gwlb" {
  count = var.gwlb_enabled ? 1 : 0

  name               = "${var.name}-gwlb"
  load_balancer_type = "gateway"
  subnets            = var.gwlb_subnet_ids

  enable_cross_zone_load_balancing = var.gwlb_cross_zone_load_balancing

  tags = merge({ Name = "${var.name}-gwlb" }, var.tags)
}

resource "aws_lb_target_group" "gwlb" {
  count = var.gwlb_enabled ? 1 : 0

  name        = "${var.name}-gwlb-tg"
  port        = 6081
  protocol    = "GENEVE"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = var.gwlb_health_check_port
    healthy_threshold   = var.gwlb_health_check_healthy_threshold
    unhealthy_threshold = var.gwlb_health_check_unhealthy_threshold
    interval            = var.gwlb_health_check_interval
  }

  tags = merge({ Name = "${var.name}-gwlb-tg" }, var.tags)
}

resource "aws_lb_listener" "gwlb" {
  count = var.gwlb_enabled ? 1 : 0

  load_balancer_arn = aws_lb.gwlb[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb[0].arn
  }

  tags = merge({ Name = "${var.name}-gwlb-listener" }, var.tags)
}

resource "aws_vpc_endpoint_service" "gwlb" {
  count = var.gwlb_enabled ? 1 : 0

  acceptance_required        = var.gwlb_endpoint_service_acceptance_required
  gateway_load_balancer_arns = [aws_lb.gwlb[0].arn]

  allowed_principals = var.gwlb_endpoint_service_allowed_principals

  tags = merge({ Name = "${var.name}-gwlb-endpoint-service" }, var.tags)
}

# Create one GWLB endpoint per subnet (AWS requires single subnet per GWLB endpoint)
resource "aws_vpc_endpoint" "gwlb" {
  for_each = var.gwlb_enabled ? toset(var.gwlb_endpoint_subnet_ids) : toset([])

  service_name      = aws_vpc_endpoint_service.gwlb[0].service_name
  subnet_ids        = [each.value]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.vpc_id

  tags = merge({ Name = "${var.name}-gwlbe-${each.key}" }, var.tags)
}

resource "aws_autoscaling_attachment" "gwlb" {
  count = var.gwlb_enabled && var.ha_mode ? 1 : 0

  autoscaling_group_name = aws_autoscaling_group.main[0].name
  lb_target_group_arn    = aws_lb_target_group.gwlb[0].arn
}
