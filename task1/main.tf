terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6.2"
    }
  }
  required_version = ">= 1.2"
}

provider "docker" {}

# Шаг 7 (data sources): образ описывается data source'ом,
# а resource docker_image скачивает его по ссылке из data.
data "docker_image" "nginx" {
  name = var.image_name
}

# Шаг 1 (build): образ и контейнер как ресурсы.
# Шаг 4 (variables): имя и порт приходят из переменных.
resource "docker_image" "nginx" {
  name = data.docker_image.nginx.name
  # образ общий с другими лабораторными - destroy удаляет
  # только контейнер, образ остаётся на хосте
  keep_locally = true
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = var.container_name

  # Шаг 2 (change): проброс порта добавлен изменением конфигурации.
  ports {
    internal = 80
    external = var.external_port
  }
}

# Шаг 6 (outputs): значения ниже выводятся после apply - см. outputs.tf.
