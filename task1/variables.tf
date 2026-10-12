variable "image_name" {
  description = "Образ nginx для контейнера"
  type        = string
  default     = "nginx:1.28-alpine"
}

variable "container_name" {
  description = "Имя создаваемого контейнера"
  type        = string
  default     = "lab5-nginx"
}

variable "external_port" {
  description = "Внешний порт, проброшенный на 80-й контейнера"
  type        = number
  default     = 8090
}
