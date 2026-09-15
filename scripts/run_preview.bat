@echo off
REM Chay Web Mobile Preview cho QuanLyCongViecApp bang mot cu nhap dup.
REM Chi dung de xem truoc giao dien mobile tren Chrome - khong phai mot
REM ung dung Web doc lap. Android/iOS van la muc tieu chinh cua app.

cd /d "%~dp0\.."

echo ============================================
echo   QuanLyCongViecApp - Web Mobile Preview
echo ============================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
    echo [LOI] Khong tim thay lenh "flutter" trong PATH.
    echo Vui long cai dat Flutter SDK va them vao PATH truoc.
    pause
    exit /b 1
)

echo Dang tai dependencies...
call flutter pub get
if errorlevel 1 (
    echo [LOI] "flutter pub get" that bai.
    pause
    exit /b 1
)

echo.
echo Dang mo Chrome de Preview giao dien mobile...
echo (Chon "Dung thu o Che do Demo" khi man hinh Dang nhap hien ra)
echo.
call flutter run -d chrome

pause
