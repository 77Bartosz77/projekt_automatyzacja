resource "aws_ecs_cluster" "ecs" {
  name = "express_app_cluster"
}

resource "aws_ecs_service" "service" {
  name = "express_app_service"
  cluster                = aws_ecs_cluster.ecs.arn
  launch_type            = "FARGATE"
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  task_definition                    = aws_ecs_task_definition.td.arn

  lifecycle {
    ignore_changes = [desired_count]
  }

 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = "express_app"
   container_port   = 80
 }
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.express_app_sg.id]
    subnets          = [aws_subnet.sn1.id, aws_subnet.sn2.id, aws_subnet.sn3.id]
  }
}

resource "aws_ecs_task_definition" "td" {
  container_definitions = jsonencode([
    {
      name         = "express_app"
      image        = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/express_app_repo"
      cpu          = 256
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  family                   = "express_app"
  requires_compatibilities = ["FARGATE"]

  cpu                = "256"
  memory             = "512"
  network_mode       = "awsvpc"
  task_role_arn      = "arn:aws:iam::${var.account_id}:role/ecsTaskExecutionRole"
  execution_role_arn = "arn:aws:iam::${var.account_id}:role/ecsTaskExecutionRole"
}