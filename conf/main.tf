terraform {
  backend "remote" {
    organization = "chicode"

    workspaces {
      name = "robot-rumble"
    }
  }
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_ecs_cluster" "main" {
  name = "backend-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family = "app"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.fargate_cpu
  memory = var.fargate_memory

  container_definitions = <<EOF
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${var.app_image}",
    "memory": ${var.fargate_memory},
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ]
  }
]
EOF
}


resource "aws_ecs_service" "backend" {
  name = "backend"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = var.app_count
  launch_type = "FARGATE"
}
resource "aws_s3_bucket" "static_files" {
  bucket = "static_files"
  acl = "public-read"
}

resource "aws_sqs_queue" "battle_input_queue" {
  name = "battle_input_queue"
  fifo_queue = true
  content_based_deduplication = true
}

resource "aws_sqs_queue" "battle_output_queue" {
  name = "battle_output_queue"
  fifo_queue = true
  content_based_deduplication = true
}

resource "aws_lambda_function" "battle_runner" {
  function_name = "battler_runner"
  runtime = "provided"
  timeout = var.lambda_timeout
  memory_size = var.lambda_memory_size
  handler = "doesnt.matter"
  role = aws_iam_role.iam_for_lambda.arn
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lambda_event_source_mapping" "input_queue_mapping" {
  event_source_arn = aws_sqs_queue.battle_input_queue.arn
  function_name = aws_lambda_function.battle_runner.arn
}

resource "aws_lambda_event_source_mapping" "output_queue_mapping" {
  event_source_arn = aws_sqs_queue.battle_output_queue.arn
  function_name = aws_lambda_function.battle_runner.arn
}

resource "aws_db_instance" "default" {
  allocated_storage = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type = "gp2"
  engine = "postgresql"
  instance_class = var.rds_instance_class
  name = var.rds_name
  username = var.rds_username
  password = var.rds_password
}


