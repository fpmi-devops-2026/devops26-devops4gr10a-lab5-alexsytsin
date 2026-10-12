# Задание 1. Terraform Tutorial - Get Started: Docker

Все 7 руководств выполнены на провайдере `kreuzwerker/docker`.
Итоговая конфигурация (main.tf, variables.tf, outputs.tf) покрывает
каждый шаг; ниже - что делалось на каждом.

## 1. Build Infrastructure

```bash
terraform init
terraform plan
terraform apply
docker ps | grep lab5-nginx
curl http://localhost:8090        # Welcome to nginx!
```

Созданы ресурсы `docker_image.nginx` и `docker_container.nginx`.

## 2. Change Infrastructure

Изменил `external_port` в variables.tf (например 8090 -> 8095)
или добавил блок ports - `terraform apply` показывает план
"1 to change" и пересоздаёт контейнер без ручного docker rm.

## 3. Define Input Variables

Значения параметризованы в variables.tf (`image_name`,
`container_name`, `external_port`), переопределяются так:

```bash
terraform apply -var="container_name=lab5-nginx-v2"
```

## 4. Output Data

outputs.tf выводит `container_id`, `image_id`, `container_url`:

```bash
terraform output
terraform output container_url
```

## 5. Query Data Sources

`data "docker_image" "nginx"` читает метаданные образа до
создания ресурса; resource ссылается на него
(`name = data.docker_image.nginx.name`).

```bash
terraform plan   # data.docker_image.nginx: Reading...
```

## 6. Destroy Infrastructure

```bash
terraform destroy
docker ps -a | grep lab5-nginx   # пусто - ресурсы удалены
```

## 7. Итог

Полный цикл init -> plan -> apply -> change -> output ->
destroy прогнан локально, state-файл terraform.tfstate
отражает управляемые ресурсы (в репозиторий не попадает -
см. .gitignore).
