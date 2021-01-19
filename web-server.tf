
# User data
data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.sh")}"
}

resource "aws_launch_configuration" "web" {
  name_prefix = "${var.tags.environment}-web-launch-configuration"

  image_id                    = "${data.aws_ami.amazon-linux-2.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  enable_monitoring           = false
  security_groups             = ["${aws_security_group.web.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "web" {
  name = "${var.tags.environment}-web-asg"

  min_size             = 1
  desired_capacity     = 1
  max_size             = 1
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.elb.id]
  launch_configuration = "${aws_launch_configuration.web.name}"
  vpc_zone_identifier  = aws_subnet.private.*.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.tags.environment}-web"
      propagate_at_launch = true
    },
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
}

# Security group
resource "aws_security_group" "web" {
  name_prefix = "${var.tags.environment}-web-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  tags = merge(map("Name", format("%s-web-security-group", var.tags["environment"])), var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["55.55.55.55/32"]
  security_group_id = "${aws_security_group.web.id}"
}


resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.web.id}"

}

# Security group
resource "aws_security_group" "elb" {
  name_prefix = "${var.tags.environment}-elb-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  tags = merge(map("Name", format("%s-elb-security-group", var.tags["environment"])), var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.elb.id}"
}

resource "aws_security_group_rule" "allow_all_outbound01" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.elb.id}"

}

### Creating ELB
resource "aws_elb" "elb" {
  name = "${var.tags.environment}-elb"

  tags = merge(map("Name", format("%s-elb", var.tags["environment"])), var.tags)

  security_groups = ["${aws_security_group.elb.id}"]
  subnets = aws_subnet.public.*.id
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
  
}
