# Задание 2 - Ansible: инвентарь, ad-hoc команды, плейбуки

Управляем нодами kind-кластера `lab5` из задания 3. Ноды кластера - это
Docker-контейнеры без SSH-сервера, поэтому вместо стандартного
`ansible_connection=ssh` используется connection-плагин
`community.docker.docker`: Ansible заходит внутрь контейнера через
`docker exec` и выполняет там обычные модули (на нодах уже есть Python 3.11).

## Структура

- `ansible.cfg` - путь к инвентарю, настройки по умолчанию
- `inventory/hosts.ini` - инвентарный файл с группами хостов
- `playbooks/node-setup.yml` - подготовка всех нод кластера
- `playbooks/nginx-workers.yml` - установка и управление nginx на worker-нодах

## Инвентарный файл

Хосты разбиты на группы:

- `control_plane` - управляющая нода кластера
- `workers` - две рабочие ноды
- `k8s_nodes` - родительская группа, объединяющая все три ноды

Общие переменные группы задают способ подключения:

```ini
[k8s_nodes:vars]
ansible_connection=community.docker.docker
ansible_user=root
ansible_python_interpreter=/usr/bin/python3
```

Проверка инвентаря:

```sh
ansible-inventory --list
ansible-inventory --graph
```

## Ad-hoc (специальные) команды

Ping всей группы нод одной командой:

```sh
ansible k8s_nodes -m ping
```

Результат:

```text
lab5-control-plane | SUCCESS => { "ping": "pong" }
lab5-worker        | SUCCESS => { "ping": "pong" }
lab5-worker2       | SUCCESS => { "ping": "pong" }
```

Выполнение shell-команды на всех нодах:

```sh
ansible k8s_nodes -m shell -a 'echo "shell: $0"; hostname; uptime'
```

Только на worker-нодах:

```sh
ansible workers -m command -a 'cat /etc/os-release | head -2'
```

Сбор фактов об узле:

```sh
ansible lab5-control-plane -m setup -a 'filter=ansible_os_family'
```

Перезапуск службы ad-hoc командой:

```sh
ansible workers -m service -a 'name=nginx state=restarted'
```

## Плейбуки

### node-setup.yml

Подготовка всех трёх нод: обновление кеша apt, установка утилит
(`curl`, `htop`, `jq`), раскладка файла-метки `/etc/lab5-marker` с именем ноды.

```sh
ansible-playbook playbooks/node-setup.yml
```

Результат запуска: `ok=6 changed=2` на каждой из трёх нод, ни одной ошибки.

### nginx-workers.yml

Установка и управление приложением на группе `workers`: ставится nginx,
раскладывается своя стартовая страница, служба запускается и включается в
автозагрузку, handler перезапускает nginx после смены страницы, ответ
проверяется HTTP-запросом прямо на ноде.

```sh
ansible-playbook playbooks/nginx-workers.yml
```

Результат запуска: на обеих worker-нодах `ok=7 changed=4`, служба в
состоянии `active`, страница `Lab5 - <имя ноды>` отдаётся на `127.0.0.1:80`.
