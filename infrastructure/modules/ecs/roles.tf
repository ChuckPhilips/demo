################################################################################
# ECS Role
################################################################################

data "aws_iam_policy_document" "ecs_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecsRole-${var.postfix_in}"
  assume_role_policy = data.aws_iam_policy_document.ecs_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_role" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}


################################################################################
# Task Exec Role
################################################################################

data "aws_iam_policy_document" "task_execution_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution_role" {
  name               = "ecsTaskExecutionRole-${var.postfix_in}"
  assume_role_policy = data.aws_iam_policy_document.task_execution_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "envoy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

################################################################################
# Task Role
################################################################################

data "aws_iam_policy_document" "task_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "task_role" {
  name               = "ecsTaskRole-${var.postfix_in}"
  assume_role_policy = data.aws_iam_policy_document.task_role_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_role" {
  name   = "AllowTaskPermissions"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "task_role_xray_daemon_write_access" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "task_role_envoy_access" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}


################################################################################
# Tasks EC2 Instance Profile
################################################################################

data "aws_iam_policy_document" "ec2_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_assume_role_policy.json
  name               = "ecsInstanceRole-${var.postfix_in}"
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_container_service" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance" {
  name = "ecsInstanceProfile-${var.postfix_in}"
  role = aws_iam_role.ec2_instance_role.name
}

################################################################################
# AutoScaling Role
################################################################################

data "aws_iam_policy_document" "ecs_autoscaling_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_autoscaling_role" {
  name               = "ecsAutoScalingRole-${var.postfix_in}"
  assume_role_policy = data.aws_iam_policy_document.ecs_autoscaling_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling_role" {
  role       = aws_iam_role.ecs_autoscaling_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}