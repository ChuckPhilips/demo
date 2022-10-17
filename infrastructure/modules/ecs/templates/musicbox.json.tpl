[
    {
        "name": "${musicbox_container_name}",
        "image": "${musicbox_container_image}",
        "essential": true,
        "memoryReservation": ${musicbox_container_memory},
        "environment": [
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${musicbox_log_group_name}",
                "awslogs-region": "${musicbox_log_group_region}",
                "awslogs-stream-prefix": "${musicbox_awslogs_stream_prefix}"
            }
        },
        "portMappings": [
            {
              "hostPort": ${musicbox_container_port},
              "protocol": "tcp",
              "containerPort": ${musicbox_container_port}
            }
        ]
    }
]