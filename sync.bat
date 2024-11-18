REM sync.bat
REM Sxribe
REM 18/10/2023

@echo off
wally install
rojo sourcemap default.project.json --output sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
wally-package-types --sourcemap sourcemap.json ServerPackages/
ECHO:
ECHO OK!
@echo on