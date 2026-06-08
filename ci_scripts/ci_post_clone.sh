#!/bin/sh
set -euo pipefail

# InAppKit depends on MockableMacro — required for non-interactive builds (Xcode Cloud, CI).
/usr/bin/defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
