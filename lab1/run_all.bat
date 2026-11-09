@echo off
chcp 65001 >nul
cd /d "%~dp0sql"
set S=localhost,1433

echo Видалення старої бази (якщо є)...
sqlcmd -S %S% -E -I -Q "IF DB_ID('SportEventsDb') IS NOT NULL BEGIN ALTER DATABASE SportEventsDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE SportEventsDb; END"

echo 01 Таблиці...
sqlcmd -S %S% -E -I -f 65001 -b -i 01_schema.sql || goto error
echo 02 Індекси...
sqlcmd -S %S% -E -I -f 65001 -b -i 02_indexes.sql || goto error
echo 03 Процедури, функції, view, тригери...
sqlcmd -S %S% -E -I -f 65001 -b -i 03_programmability.sql || goto error
echo 04 Тестові дані...
sqlcmd -S %S% -E -I -f 65001 -i 04_seed_and_demo.sql -o 04_output.txt
echo 05 Тести:
sqlcmd -S %S% -E -I -f 65001 -W -i 05_tests.sql
echo.
echo Готово.
pause
exit /b 0

:error
echo.
echo ПОМИЛКА. Зробіть скріншот цього вікна.
pause
exit /b 1
