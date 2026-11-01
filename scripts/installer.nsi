; NightlyFox Windows installer (per-user, no admin needed). Built with makensis on Linux.
; Defines expected from the command line: FLAVOR VERSION SRCDIR OUTFILE
Unicode true
!include "MUI2.nsh"

Name "NightlyFox (${FLAVOR})"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Programs\NightlyFox-${FLAVOR}"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 64
BrandingText "NightlyFox - unofficial Firefox Nightly build"

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\firefox.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Start NightlyFox (${FLAVOR})"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\NightlyFox-${FLAVOR}"

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "${SRCDIR}/*"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  CreateShortcut "$SMPROGRAMS\NightlyFox (${FLAVOR}).lnk" "$INSTDIR\firefox.exe"
  WriteRegStr   HKCU "${UNINST_KEY}" "DisplayName"     "NightlyFox (${FLAVOR})"
  WriteRegStr   HKCU "${UNINST_KEY}" "DisplayVersion"  "${VERSION}"
  WriteRegStr   HKCU "${UNINST_KEY}" "Publisher"       "NightlyFox (unofficial)"
  WriteRegStr   HKCU "${UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr   HKCU "${UNINST_KEY}" "DisplayIcon"     "$INSTDIR\firefox.exe"
  WriteRegStr   HKCU "${UNINST_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$SMPROGRAMS\NightlyFox (${FLAVOR}).lnk"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "${UNINST_KEY}"
SectionEnd
