# Kittygram Infrastructure and Deployment

Этот репозиторий содержит инфраструктурный код и пайплайны CI/CD для автоматического развертывания проекта [Kittygram](https://github.com/yandex-praktikum/kittygram) в Yandex Cloud.

## 📚 Что было сделано

В рамках домашнего задания был выполнен полный цикл автоматизированного деплоя приложения Kittygram в облаке Yandex Cloud. Для этого была разработана и настроена инфраструктура с использованием Terraform: созданы необходимые ресурсы — виртуальная машина, публичный IP-адрес, облачная сеть и конфигурация SSH-доступа. На этапе инициализации ВМ применяется cloud-init, с помощью которого происходит автоматическая установка Docker, настройка docker-compose и добавление SSH-ключей.

Развёртывание самого приложения реализовано через GitHub Actions. Создан CI/CD-пайплайн, состоящий из нескольких стадий: сборка Docker-образов фронтенда, бэкенда и nginx, публикация их на DockerHub, подключение к облачной ВМ и запуск контейнеров с использованием docker-compose.production.yml. Также добавлены Telegram-уведомления для информирования о статусе пайплайна. Для повышения надёжности проекта присутствуют автотесты, проверяющие корректность конфигурации, доступность приложения и публикацию образов в DockerHub. Проект полностью контейнеризирован и готов к развёртыванию.

## 📦 Стек технологий

- [Terraform](https://www.terraform.io/) — инфраструктура как код
- [GitHub Actions](https://docs.github.com/en/actions) — CI/CD пайплайны
- [Docker](https://www.docker.com/) — упаковка и запуск приложения
- [Yandex Cloud](https://cloud.yandex.ru/) — облачная платформа
- [cloud-init](https://cloudinit.readthedocs.io/en/latest/) — первичная настройка ВМ
- [Telegram Bot](https://core.telegram.org/bots/api) — уведомления

## ⚙️ Структура проекта

```
├── README.md  
├── .github
│   └── workflows
│       ├── deploy.yml              # GitHub Actions: пайплайн деплоя проекта на удалённую ВМ
│       └── terraform.yml           # GitHub Actions: пайплайн для применения Terraform-инфраструктуры
├── backend                         # Django-бэкенд Kittygram 
│   ├── Dockerfile
│   ├── README.md
│   ├── cats
│   ├── entrypoint.sh
│   ├── kittygram_backend
│   ├── manage.py
│   └── requirements.txt
├── docker-compose.production.yml   # Compose-файл для прод-сборки (frontend + backend + nginx)
├── frontend                        # React-фронтенд Kittygram
│   ├── Dockerfile
│   ├── README.md
│   ├── package-lock.json
│   ├── package.json
│   ├── public
│   └── src
├── infra                           # Terraform-код для создания инфраструктуры в Yandex Cloud
│   ├── main.tf                     # Основной файл: создаёт ВМ, сеть, диск и привязку ключей
│   ├── output.tf                   # Выходные данные Terraform
│   ├── provider.tf                 # Настройки провайдера Yandex Cloud
│   └── variables.tf                # Описание переменных Terraform
├── nginx                           # Конфигурация для reverse-proxy Nginx
│   ├── Dockerfile
│   └── nginx.conf
├── pytest.ini
├── .env                            # Файл окружения для локального запуска приложения. Смотри .env.example
├── tests
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_connection.py
│   ├── test_dockerhub_images.py
│   └── test_files.py
└── tests.yml
```

## Необходимые секреты

| Название | Описание |
|------------------|----------|
| YC_SA_JSON_CREDENTIALS | JSON-файл с ключами сервисного аккаунта Yandex Cloud |
| YC_FOLDER_ID | ID каталога Yandex Cloud |
| YC_CLOUD_ID | ID облака Yandex Cloud |
| TELEGRAM_CHAT_ID | ID чата Telegram для уведомлений |
| TELEGRAM_BOT_TOKEN | Токен Telegram бота для уведомлений |
| ACCESS_KEY | Доступ к S3-совместимому хранилищу |
| SECRET_KEY | Секретный ключ доступа к S3-совместимому хранилищу |
| DOCKER_PASSWORD | Пароль от Docker Hub |
| DOCKER_USERNAME | Логин от Docker Hub |
| PRODUCTION_HOST_ADDR | IP-адрес продакшн-сервера на который будет развернуто приложение |
| PRODUCTION_HOST_LOGIN | Логин для доступа к продакшн-серверу |
| PRODUCTION_HOST_SSH_PRIVATE_KEY | Приватный SSH-ключ для доступа к продакшн-серверу. Используется для доступа к серверу и развертывания приложения через Deploy Action. |
| PRODUCTION_HOST_SSH_PUBLIC_KEY | Публичный SSH-ключ для доступа к продакшн-серверу. Используется для создания виртуальной машины и настройки доступа к ней. |
| ALLOWED_HOSTS | Список разрешённых хостов для Django-приложения. |
| DEBUG | Режим отладки Django-приложения. |
| POSTGRES_PASSWORD | Пароль для PostgreSQL. |
| POSTGRES_USER | Имя пользователя для PostgreSQL. |
| POSTGRES_DB | Имя базы данных для PostgreSQL. |
| POSTGRES_HOST | Адрес подключения к PostgreSQL. |
| POSTGRES_PORT | Порт подключения PostgreSQL. |


## 🚀 Pipelines

### Инфраструктура `terraform.yml`

Запускается через GitHub Actions → Terraform. Необходимо перейти в  Run workflow → выбрать действие:
 - plan — просмотр изменений
 - apply — создать ресурсы
 - destroy — удалить ресурсы

После успешного apply у тебя появится виртуальная машина с Docker и docker-compose из cloud-init.

### CI/CD `deploy.yml`

Пайплайн автоматически запускается при пуше в ветку main/master

Stages
- Сборку образов frontend, backend и nginx
- Тестирование образов frontend, backend и nginx
- Публикацию образов на DockerHub
- Подключение к удалённой ВМ
- Запуск контейнеров с помощью docker-compose.production.yml
- Проверку доступности приложения
- Отправку уведомления в Telegram

## Примечание

Разработано в рамках учебного задания магистратуры DevOps-инженер от Яндекс Практикума.
