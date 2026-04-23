# Bankir Backend

Рекомендованный backend для этого проекта: `NestJS + PostgreSQL + Prisma`.

Почему этот стек:

- `NestJS` дает предсказуемую модульную структуру под `auth`, `users`, `payments`, `transactions`.
- `PostgreSQL` подходит для финансовых сущностей, истории операций и строгих транзакций.
- `Prisma` ускоряет разработку схемы и доступ к данным без хаоса в SQL-слое.

## Что уже заскелечено

- `auth` для логина, регистрации и refresh токенов
- `users` для профиля
- `payments` для перевода, пополнения и оплаты счетов
- `transactions` для истории операций
- `health` для базовой проверки сервиса
- `prisma/schema.prisma` с основными моделями

## Базовые маршруты

- Все маршруты идут с префиксом `/api`
- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `GET /api/users/me`
- `POST /api/payments/transfer`
- `POST /api/payments/top-up`
- `POST /api/payments/bills`
- `GET /api/transactions`

## Как поднять локально

1. Создай `.env` на основе `.env.example`.
2. Установи зависимости: `npm install`
3. Сгенерируй Prisma client: `npm run prisma:generate`
4. Прогони миграцию: `npm run prisma:migrate`
5. Запусти dev server: `npm run start:dev`

## Что дальше для iOS

Текущий клиент уже имеет:

- `AuthManager`
- `NetworkManager`
- `PaymentsAPI`

Следующий шаг после установки зависимостей:

- заменить локальный mock-логин на вызовы `POST /auth/login`
- перевести регистрацию с локального `SwiftData` на `POST /auth/register`
- подключить реальные вызовы платежей вместо `Task.sleep`
