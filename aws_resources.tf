resource "aws_iam_role" "spot_role" {
  name_prefix = "spot_role_"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "spotfleet.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "spot_policy" {
  name_prefix = "spot_policy_"
  description = "EC2 Spot Fleet Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeSubnets",
                "ec2:RequestSpotInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:CreateTags",
                "ec2:RunInstances",
                "iam:CreateServiceLinkedRole",
                "iam:ListRoles",
                "iam:ListInstanceProfiles"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "ec2.amazonaws.com",
                        "ec2.amazonaws.com.cn"
                    ]
                }
            },
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:*/*"
            ]
        }
    ]
}
EOF
}

locals {
  role = aws_iam_role.spot_role
  zone = join("", [var.region, "a"])
}

// -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "spot_role_policy_attachment" {
  role       = local.role.name
  policy_arn = aws_iam_policy.spot_policy.arn
}

// -----------------------------------------------------------------------------

resource "aws_security_group" "spot_security_group" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.spot_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc" "spot_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "spot_vpc"
  }
}

resource "aws_subnet" "spot_subnet" {
  vpc_id                  = aws_vpc.spot_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.zone

  tags = {
    Name = "spot_subnet"
  }
}

resource "aws_internet_gateway" "spot_igw" {
  vpc_id = aws_vpc.spot_vpc.id

  tags = {
    Name = "spot_vpc"
  }
}

resource "aws_route" "spot_route" {
  route_table_id         = aws_vpc.spot_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.spot_igw.id
}

resource "aws_spot_fleet_request" "spot_fleet_request" {
  iam_fleet_role  = local.role.arn
  spot_price      = var.spot_price
  target_capacity = var.capacity
  # Workaround to terminate instances on request cancelation
  # ref: https://github.com/hashicorp/terraform-provider-aws/issues/10083#issuecomment-578390938
  terminate_instances_with_expiration = true

  launch_specification {
    instance_type          = "r6g.medium"
    ami                    = var.ami
    key_name               = var.key_name
    subnet_id              = aws_subnet.spot_subnet.id
    availability_zone      = local.zone
    vpc_security_group_ids = [aws_security_group.spot_security_group.id]
  }

  launch_specification {
    instance_type          = "a1.large"
    ami                    = var.ami
    key_name               = var.key_name
    subnet_id              = aws_subnet.spot_subnet.id
    availability_zone      = local.zone
    vpc_security_group_ids = [aws_security_group.spot_security_group.id]
  }

  depends_on = [aws_internet_gateway.spot_igw]
}

// -----------------------------------------------------------------------------

data "aws_instances" "running_spot_instances" {
  filter {
    name   = "tag:aws:ec2spot:fleet-request-id"
    values = [aws_spot_fleet_request.spot_fleet_request.id]
  }
}

// -----------------------------------------------------------------------------

output "spot_fleet_request_id" {
  value = aws_spot_fleet_request.spot_fleet_request.id
}

output "running_spot_instances" {
  value = {
    ids        = data.aws_instances.running_spot_instances.ids
    public_ips = data.aws_instances.running_spot_instances.public_ips
  }
}
