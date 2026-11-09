# Лабораторна 1 — Варіант 13: Система управління спортивними подіями

СУБД: **Microsoft SQL Server 2016 SP1+** (клієнт — DBeaver). Код: **C# / .NET 8** (Dapper + Microsoft.Data.SqlClient).

## Вимоги до системи (п. 3)

1. Організатор веде довідник видів спорту, арен із секторами та турнірів.
2. Команди реєструються в турнірах; у команд є склад (спортсмени з номерами) і тренери.
3. Матч (подія) створюється лише між зареєстрованими командами; арена не може приймати дві події з різницею менше 3 годин.
4. На матч призначаються судді; після гри фіксується рахунок, переможець визначається автоматично.
5. Турнірна таблиця рахується автоматично: 3 очки за перемогу, 1 за нічию.
6. Вболівальник купує квиток на конкретне місце; одне місце не можна продати двічі; ціна = базова ціна × коефіцієнт сектора.
7. Замовлення можна оплатити або скасувати з поверненням коштів.
8. Турніри мають спонсорів із рівнем партнерства.
9. Користувачі, арени, турніри, команди, спортсмени, події й замовлення **не видаляються фізично** (soft delete) і можуть бути відновлені.
10. Для цих сутностей зберігається **дата останньої зміни та користувач**, що її вніс; зміни подій і команд пишуться в журнал `AuditLog` (JSON до/після).

## Відповідність пунктам завдання

| Пункт | Де виконано |
|---|---|
| 1. Схема БД | `diagram/schema.dbml` — вставити на dbdiagram.io |
| 2. ≥ 15 сутностей | 21 таблиця (`sql/01_schema.sql`) |
| 3. Soft delete + аудит | `IsDeleted/DeletedAt` і `UpdatedAt/UpdatedBy` у 7 таблицях, `AuditLog` |
| 4. Реалізація в СУБД | `sql/01_schema.sql` |
| 5. ≥ 10 програмних об'єктів | 32: 6 view, 5 функцій, 15 процедур, 6 тригерів (`sql/03_programmability.sql`) |
| 6. ≥ 2 типи індексів | clustered, nonclustered, unique filtered, covering (INCLUDE), columnstore (`sql/02_indexes.sql`) |
| 7. Repository + Unit of Work | `src/SportEvents.App` — читання лише з view, зміни лише через процедури |

### Soft delete реалізовано двома способами
- процедури `sp_Event_SoftDelete`, `sp_Team_SoftDelete` (з бізнес-перевірками);
- тригери `INSTEAD OF DELETE` — навіть звичайний `DELETE FROM dbo.Events` лише ставить `IsDeleted = 1`.

### Як тригери знають, хто змінив дані
Застосунок одразу після відкриття з'єднання викликає `sp_set_session_context 'UserId'`, а тригери читають його функцією `dbo.fn_CurrentUserId()`.

## Як запустити

### База даних у DBeaver
1. Підключіться до SQL Server.
2. **Важливо:** DBeaver за замовчуванням ділить скрипт по `;`, а процедури й змінні так ламаються.
   Налаштуйте: *Window → Preferences → Editors → SQL Editor → SQL Processing*:
   роздільник команд — `GO`, «Blank line is statement delimiter» — `Never`.
3. Відкрийте й виконайте як скрипт (**Alt+X**) по черзі: `01_schema.sql` → `02_indexes.sql` → `03_programmability.sql` → `04_seed_and_demo.sql` → `05_tests.sql`.
4. Останній скрипт виводить таблицю тестів із PASS/FAIL і підсумок `Passed / Failed`. Очікується 18 PASS і 0 FAIL.

Повторний запуск з нуля: `USE master; DROP DATABASE SportEventsDb;`

### C#-застосунок
```bash
cd src/SportEvents.App
dotnet run
```
Рядок підключення — на початку `Program.cs` (за замовчуванням Windows-автентифікація на `localhost`).

Програма демонструє 4 сценарії:
1. Створення команди, реєстрація в турнірі й створення матчу — одна транзакція.
2. Запис результату та виведення турнірної таблиці.
3. Помилка посеред Unit of Work (арена зайнята) → відкат усіх змін, команда не з'являється в БД.
4. Soft delete події, перегляд «кошика», відновлення та історія змін з `AuditLog`.

## Структура коду

```
Data/
  DbSession.cs        — з'єднання + транзакція + поточний користувач
  IUnitOfWork.cs      — інтерфейс: Teams, Events, Results, Commit, Rollback
  UnitOfWork.cs       — відкриває з'єднання, session context, транзакцію
Repositories/
  TeamRepository      — vw_ActiveTeams, vw_TeamRoster, sp_Team_*, sp_Tournament_RegisterTeam
  EventRepository     — vw_ActiveEvents, vw_DeletedEvents, sp_Event_*, sp_Audit_GetHistory
  EventResultRepository — sp_EventResult_Set, sp_Tournament_GetStandings
Models/Models.cs      — DTO для view і параметри процедур
```
