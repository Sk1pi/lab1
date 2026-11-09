# Лабораторна робота №1

**Варіант 13:** Система управління спортивними подіями
**СУБД:** MS SQL Server
**Мова:** C# (.NET 8, Dapper)

## Структура

```
diagram/   схема БД (schema.dbml для dbdiagram.io, schema.png)
sql/       01_schema, 02_indexes, 03_programmability, 04_seed_and_demo, 05_tests
src/       C# застосунок (Repository + Unit of Work)
```

## Вимоги до системи

- Турніри з видами спорту, команди, спортсмени, тренери, судді, арени з секторами.
- Матч створюється лише між командами, зареєстрованими в турнірі; арена не може бути зайнята двома матчами з різницею менше 3 годин.
- Після матчу фіксується рахунок, переможець і турнірна таблиця рахуються автоматично.
- Продаж квитків на конкретні місця, оплата й скасування замовлень з поверненням коштів.
- Спонсори турнірів.
- Soft delete для Users, Venues, Tournaments, Teams, Athletes, Events, Orders.
- Для цих таблиць зберігаються дата останньої зміни та користувач, що її зробив; зміни Events і Teams пишуться в AuditLog.

## Що реалізовано

| Пункт | Реалізація |
|---|---|
| Схема | 21 таблиця, зв'язки 1:N, M:N, 1:1 |
| Soft delete | поля IsDeleted/DeletedAt, процедури SoftDelete/Restore, тригери INSTEAD OF DELETE |
| Аудит | UpdatedAt/UpdatedBy, таблиця AuditLog, користувач передається через SESSION_CONTEXT |
| Програмні об'єкти | 6 view, 5 функцій, 15 процедур, 6 тригерів |
| Індекси | clustered, nonclustered, unique filtered, covering (INCLUDE), columnstore |
| Код | Repository + Unit of Work для Teams, Events, EventResults; читання через view, зміни через збережені процедури |

## Запуск

База даних (усі скрипти по черзі + тести):

```
run_all.bat
```

або вручну для кожного файлу:

```
sqlcmd -S localhost,1433 -E -I -f 65001 -i sql\01_schema.sql
```

Очікуваний результат тестів: `Passed 18, Failed 0`.

Застосунок:

```
cd src/SportEvents.App
dotnet run
```

Рядок підключення задається в `Program.cs`.
