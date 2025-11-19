# Задания 1-6

## Архитектурные схемы

[schema.drawio](docs/schema.drawio)

## Проверка 
Финальная реализация - с шардированием, реплицированием MongoDB, кэшированием данных в redis

### Запуск mongodb и приложения

```shell
cd mongo-sharding-repl
```

```shell
docker compose up -d
```
### Заполнение mongodb данными

```shell
./scripts/mongo-init.sh
```

### Проверка

Для просмотра настроек MongoDB откройте в браузере http://localhost:8080

Для проверки функциональности кэширования данных используйте ручку http://localhost:8080/helloDoc/users

### Все доступные эндпоинты

Список доступных эндпоинтов, swagger http://localhost:8080/docs

# Задания 7-10

## Архитектурный документ

[ADR.md](task07-10-ADR.md)
