USE SportEventsDb;
GO

IF OBJECT_ID('tempdb..#TestResults') IS NOT NULL DROP TABLE #TestResults;
CREATE TABLE #TestResults (
    Id      INT IDENTITY(1,1),
    Test    NVARCHAR(200),
    Result  NVARCHAR(10),
    Details NVARCHAR(4000)
);
GO

BEGIN TRY
    DECLARE @o INT, @t INT;
    EXEC dbo.sp_Ticket_Purchase 3, 3, 1, 5, 12, @o OUTPUT, @t OUTPUT;
    INSERT INTO #TestResults VALUES (N'Не можна купити вже зайняте місце', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'Не можна купити вже зайняте місце', IIF(ERROR_NUMBER() = 50303, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

BEGIN TRY
    DECLARE @o INT, @t INT;
    EXEC dbo.sp_Ticket_Purchase 3, 3, 1, 99, 1, @o OUTPUT, @t OUTPUT;
    INSERT INTO #TestResults VALUES (N'Тригер: неіснуючий ряд у секторі', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'Тригер: неіснуючий ряд у секторі', IIF(ERROR_NUMBER() = 50310, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

BEGIN TRY
    DECLARE @o INT, @t INT;
    EXEC dbo.sp_Ticket_Purchase 3, 1, 1, 1, 1, @o OUTPUT, @t OUTPUT;
    INSERT INTO #TestResults VALUES (N'Тригер: квиток на завершений матч', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'Тригер: квиток на завершений матч', IIF(ERROR_NUMBER() = 50310, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

BEGIN TRY
    DECLARE @e INT;
    EXEC dbo.sp_Event_Create 1, 1, 1, 2, '2026-11-20T20:00:00', 100, 2, @e OUTPUT;
    INSERT INTO #TestResults VALUES (N'Арена зайнята — подію не створено', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'Арена зайнята — подію не створено', IIF(ERROR_NUMBER() = 50203, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

BEGIN TRY
    DECLARE @e INT;
    EXEC dbo.sp_Event_Create 1, 1, 1, 5, '2027-01-10T18:00:00', 100, 2, @e OUTPUT;
    INSERT INTO #TestResults VALUES (N'Команда не зареєстрована в турнірі', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'Команда не зареєстрована в турнірі', IIF(ERROR_NUMBER() = 50201, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

BEGIN TRY
    DECLARE @e INT;
    EXEC dbo.sp_Event_Create 1, 1, 1, 1, '2027-01-10T18:00:00', 100, 2, @e OUTPUT;
    INSERT INTO #TestResults VALUES (N'CHECK: команда не грає сама з собою', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'CHECK: команда не грає сама з собою', IIF(ERROR_NUMBER() = 547, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

BEGIN TRY
    EXEC dbo.sp_Event_SoftDelete @EventId = 3, @ChangedBy = 1;
    INSERT INTO #TestResults VALUES (N'Не можна видалити подію з проданими квитками', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'Не можна видалити подію з проданими квитками', IIF(ERROR_NUMBER() = 50205, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

BEGIN TRY
    INSERT INTO dbo.Users (RoleId, Email, PasswordHash, FullName) VALUES (3, N'fan@gmail.com', N'x', N'Дублікат');
    INSERT INTO #TestResults VALUES (N'Унікальний email серед активних', N'FAIL', N'Помилки не було');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults VALUES (N'Унікальний email серед активних', IIF(ERROR_NUMBER() = 2601, N'PASS', N'FAIL'), ERROR_MESSAGE());
END CATCH;
GO

DECLARE @r NVARCHAR(10);
BEGIN TRANSACTION;
    UPDATE dbo.Users SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME() WHERE Email = N'fan@gmail.com';
    BEGIN TRY
        INSERT INTO dbo.Users (RoleId, Email, PasswordHash, FullName) VALUES (3, N'fan@gmail.com', N'x', N'Новий акаунт');
        SET @r = N'PASS';
    END TRY
    BEGIN CATCH
        SET @r = N'FAIL';
    END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
INSERT INTO #TestResults VALUES (N'Email можна використати після soft delete', @r, NULL);
GO

DECLARE @r NVARCHAR(10);
BEGIN TRANSACTION;
    DELETE FROM dbo.Teams WHERE TeamId = 6;
    SET @r = IIF(EXISTS (SELECT 1 FROM dbo.Teams WHERE TeamId = 6 AND IsDeleted = 1 AND DeletedAt IS NOT NULL)
                 AND NOT EXISTS (SELECT 1 FROM dbo.vw_ActiveTeams WHERE TeamId = 6), N'PASS', N'FAIL');
ROLLBACK TRANSACTION;
INSERT INTO #TestResults VALUES (N'INSTEAD OF DELETE: команда лише позначена видаленою', @r, NULL);
GO

DECLARE @r NVARCHAR(10);
BEGIN TRANSACTION;
    EXEC dbo.sp_Team_Update @TeamId = 5, @Name = N'Політехнік-2', @City = N'Львів', @FoundedYear = 1985, @ChangedBy = 1;
    SET @r = IIF(EXISTS (SELECT 1 FROM dbo.Teams
                          WHERE TeamId = 5 AND UpdatedBy = 1
                            AND UpdatedAt >= DATEADD(MINUTE, -1, SYSUTCDATETIME()))
                 AND EXISTS (SELECT 1 FROM dbo.AuditLog
                              WHERE TableName = N'Teams' AND RecordId = 5 AND Action = N'UPDATE'
                                AND NewData LIKE N'%Політехнік-2%'), N'PASS', N'FAIL');
ROLLBACK TRANSACTION;
INSERT INTO #TestResults VALUES (N'Аудит: UpdatedAt, UpdatedBy і запис в AuditLog', @r, NULL);
GO

DECLARE @r NVARCHAR(10);
BEGIN TRANSACTION;
    EXEC dbo.sp_Order_Cancel @OrderId = 1, @ChangedBy = 1;
    SET @r = IIF((SELECT Status FROM dbo.Orders WHERE OrderId = 1) = N'Refunded'
                 AND NOT EXISTS (SELECT 1 FROM dbo.Tickets  WHERE OrderId = 1 AND Status <> N'Cancelled')
                 AND NOT EXISTS (SELECT 1 FROM dbo.Payments WHERE OrderId = 1 AND Status <> N'Refunded'), N'PASS', N'FAIL');
ROLLBACK TRANSACTION;
INSERT INTO #TestResults VALUES (N'Скасування оплаченого замовлення → повернення коштів', @r, NULL);
GO

INSERT INTO #TestResults
SELECT N'Тригер визначив переможця (2:1 → Сокіл)',
       IIF((SELECT WinnerTeamId FROM dbo.EventResults WHERE EventId = 1) = 1, N'PASS', N'FAIL'), NULL
UNION ALL
SELECT N'Нічия → переможця немає',
       IIF((SELECT WinnerTeamId FROM dbo.EventResults WHERE EventId = 2) IS NULL, N'PASS', N'FAIL'), NULL
UNION ALL
SELECT N'Функція: ціна VIP = 200 × 2.5',
       IIF(dbo.fn_GetTicketPrice(3, 3) = 500.00, N'PASS', N'FAIL'), CAST(dbo.fn_GetTicketPrice(3, 3) AS NVARCHAR(20))
UNION ALL
SELECT N'Функція: вільні місця (1250 − 1 проданий)',
       IIF(dbo.fn_GetAvailableSeats(3) = 1249, N'PASS', N'FAIL'), CAST(dbo.fn_GetAvailableSeats(3) AS NVARCHAR(20))
UNION ALL
SELECT N'Турнірна таблиця: Сокіл має 3 очки',
       IIF(dbo.fn_GetTeamPoints(1, 1) = 3, N'PASS', N'FAIL'), CAST(dbo.fn_GetTeamPoints(1, 1) AS NVARCHAR(20))
UNION ALL
SELECT N'View продажів: виручка події 3 = 200',
       IIF((SELECT Revenue FROM dbo.vw_EventSales WHERE EventId = 3) = 200.00, N'PASS', N'FAIL'), NULL;
GO

SELECT Id, Result, Test, Details FROM #TestResults ORDER BY Id;

SELECT SUM(IIF(Result = N'PASS', 1, 0)) AS Passed,
       SUM(IIF(Result = N'FAIL', 1, 0)) AS Failed
FROM #TestResults;
GO
