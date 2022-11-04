[
    {
        "name": "${app_container_name}",
        "image": "${app_container_image}",
        "essential": true,
        "memoryReservation": ${app_container_memory},
        "environment": [
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${app_log_group_name}",
                "awslogs-region": "${app_log_group_region}",
                "awslogs-stream-prefix": "${app_awslogs_stream_prefix}"
            }
        },
        "portMappings": [
            {
              "hostPort": ${app_container_port},
              "protocol": "tcp",
              "containerPort": ${app_container_port}
            }
        ]
    }
]