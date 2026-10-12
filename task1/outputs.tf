output "container_id" {
  description = "ID созданного контейнера"
  value       = docker_container.nginx.id
}

output "image_id" {
  description = "ID образа, из которого поднят контейнер"
  value       = docker_image.nginx.id
}

output "container_url" {
  description = "Адрес, по которому доступен nginx"
  value       = "http://localhost:${docker_container.nginx.ports[0].external}"
}
