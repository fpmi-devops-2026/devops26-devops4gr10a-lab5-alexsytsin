# Задание 3 - Kubernetes-кластер из трёх нод и деплой приложения

Локальный кластер Kubernetes создаётся по варианту 2 из методички - через
kind (метод Docker-in-Docker): каждая «виртуальная машина» кластера - это
отдельный Docker-контейнер. Реальные ВМ на VirtualBox/KVM в этой работе не
нужны, kind-ноды полностью выполняют их роль.

Связка инструментов: кластер поднимает **Terraform** (провайдер
`justenwalker/kind`), приложение деплоит **Ansible** (плейбук с модулем
`kubernetes.core.k8s`).

## Состав кластера

`kind_cluster.lab5` в `main.tf`:

- `lab5-control-plane` - управляющая нода, на ней проброшен порт
  `30080` на хост (extraPortMappings)
- `lab5-worker`, `lab5-worker2` - две рабочие ноды
- образ нод: `kindest/node:v1.34.0`

## Поднятие кластера

```sh
cd task3
terraform init
terraform apply   # kind_cluster.lab5: Creation complete
terraform show -json | python3 -c "import json,sys; print(json.load(sys.stdin)['values']['root_module']['resources'][0]['values']['kubeconfig'])" > kubeconfig.yaml
export KUBECONFIG=$PWD/kubeconfig.yaml
kubectl get nodes
```

Результат:

```text
lab5-control-plane   Ready    control-plane   v1.34.0
lab5-worker          Ready    <none>          v1.34.0
lab5-worker2         Ready    <none>          v1.34.0
```

## Деплой приложения из ЛР1

В кластер разворачивается приложение «салон красоты» из лабораторной 1 -
полный стек: PostgreSQL, Redis, Liquibase (миграции), FastAPI-backend и
nginx-фронт. Локальные Docker-образы загружаются в ноды командой
`kind load docker-image`, манифесты применяются Ansible-плейбуком
`ansible/deploy-app.yml`.

```sh
ansible-playbook ansible/deploy-app.yml
```

Плейбук делает два шага:

1. Загружает пять образов `niispo-lab1-*` во все ноды кластера.
2. Применяет манифесты из `manifests/`, ждёт завершения Job'а миграций и
   rollout всех deployment'ов, показывает раскладку подов по нодам и
   проверяет `GET /health` через NodePort.

### Манифесты (`manifests/`)

- `00-namespace.yaml` - namespace `beauty-salon`
- `01-secret.yaml` - Secret с доступами к БД и `DATABASE_URL`
- `02-postgres.yaml` - PVC + Deployment + Service PostgreSQL
- `03-redis.yaml` - Deployment + Service Redis
- `04-liquibase-job.yaml` - Job миграций (init-контейнер ждёт postgres)
- `05-api.yaml` - Deployment api (2 реплики, podAntiAffinity разносит их
  по разным worker-нодам) + Service
- `06-nginx.yaml` - Deployment nginx + Service типа NodePort `30080`,
  который через проброс порта доступен на `http://localhost:30080`

## Проверка работы

```text
$ kubectl get pods -n beauty-salon -o wide
api-5dd448547f-86m7x        1/1   Running   lab5-worker
api-5dd448547f-mk56k        1/1   Running   lab5-worker2
liquibase-migrate-kn2vs     0/1   Completed lab5-worker2
nginx-6594b4f746-gn5mf      1/1   Running   lab5-worker
postgres-68d474b848-7nhzj   1/1   Running   lab5-worker
redis-5ddcf88d8-v2kfx       1/1   Running   lab5-worker2
```

```sh
curl http://localhost:30080/health
# {"status":"ok","environment":"kubernetes"}

curl -X POST http://localhost:30080/api/v1/clients \
  -H 'Content-Type: application/json' \
  -d '{"full_name":"Тест Тестов","phone":"+375291112233"}'
# {"id":1,"status":"current", ...}
```

Обе реплики api лежат на разных нодах (podAntiAffinity), миграции Liquibase
выполнились один раз через Job, веб-интерфейс доступен на
`http://localhost:30080` (страница `/docs` отдаёт Swagger UI).

## Удаление

```sh
terraform destroy   # удалит кластер и все контейнеры-ноды
```
