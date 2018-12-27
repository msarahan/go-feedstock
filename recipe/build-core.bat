setlocal enabledelayedexpansion

rem Do not use GOROOT_FINAL. Otherwise, every conda environment would
rem need its own non-hardlinked copy of the go (+100MB per env).
rem It is better to rely on setting GOROOT during environment activation.
rem
rem c.f. https://github.com/conda-forge/go-feedstock/pull/21#discussion_r202513916
set "GOROOT=%SRC_DIR%\go"
set "GOCACHE=off"
cd "%GOROOT%\src"

rem CGO is only available when the go_platform matched the target_platform
set CGO_ENABLED=0

call all.bat
if errorlevel 1 exit 1

rem Don't need the cached build objects
rmdir /s /q %SRC_DIR%\go\pkg\obj

mkdir "%PREFIX%\go"
xcopy /s /y /i /q "%SRC_DIR%\go\*" "%PREFIX%\go\"

rem Right now, it's just go and gofmt, but might be more in the future!
if not exist "%LIBRARY_BIN%" mkdir "%LIBRARY_BIN%"
for %%f in ("%PREFIX%\go\bin\*.exe") do (
  move %%f "%LIBRARY_BIN%"
)

rem all files in bin are gone
rmdir /q /s "%PREFIX%\go\bin"
if errorlevel 1 exit 1

rem Copy the rendered [de]activate scripts to %PREFIX%\etc\conda\[de]activate.d.
rem go finds its *.go files via the GOROOT variable
for %%F in (activate deactivate) do (
  if not exist "%PREFIX%\etc\conda\%%F.d" mkdir "%PREFIX%\etc\conda\%%F.d"
  if errorlevel 1 exit 1
  copy "%RECIPE_DIR%\%%F-go-core.bat" "%PREFIX%\etc\conda\%%F.d\%%F-z60-go-core.bat"
  if errorlevel 1 exit 1
  dir %PREFIX%\etc\conda\%%F.d\
)
