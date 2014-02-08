# -*- coding: utf-8 -*-
"""
Build Firefall chatmaid mod.
"""

# Ensure Python is current enough.
import sys
if sys.version_info < (3, 3):
    raise EnvironmentError('Python 3.3 or later must be installed')

import errno
import logging
import os
import shutil
import string
import zipfile

import modtext

__version__ = '0.4'

# TODO: Obtain current Firefall patch number programmatically.
_FirefallVersion = '0.8.1740'

# Numeric ID from the attachments link in the Firefall forums; used by Melder button.
# See http://forums.firefallthegame.com/community/threads/mod-chatmaid-improve-conversations-in-zone-chat.2868821/.
_AttachmentId = 1508621
_MelderSymbols = {
    'AttachmentId': _AttachmentId,
    'ChatmaidVersion': __version__,
    'FirefallVersion': _FirefallVersion,
}
_buildFolder = os.path.abspath('build')
_distFolder = os.path.abspath('dist')

_FirefallChatFolderPath = r'C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\HUD\Chat'
_ChatOptionsLuaPath = os.path.join(_FirefallChatFolderPath, 'ChatOptions.lua')
_ChatLuaPath = os.path.join(_FirefallChatFolderPath, 'Chat.lua')
_modifiedChatLuaPath = os.path.join(_buildFolder, 'Chat.lua')
_modifiedChatOptionsLuaPath = os.path.join(_buildFolder, 'ChatOptions.lua')

_log = logging.getLogger('build_chatmaid')


def _backupPath(sourcePath):
    _, sourceName = os.path.split(sourcePath)
    baseName, suffix = os.path.splitext(sourceName)
    backupName = baseName + '_backup' + suffix
    result = os.path.join(_buildFolder, backupName)
    return result


def _possiblyBuildBackup(sourcePath):
    backupPath = _backupPath(sourcePath)
    if os.path.exists(backupPath):
        _log.info('preserve existing backup: %s', backupPath)
    else:
        _log.info('build backup: %s', backupPath)
        shutil.copy2(sourcePath, backupPath)


def _slurped(pathToRead):
    _log.info('read %s', pathToRead)
    result = []
    with open(pathToRead, 'r', encoding='utf-8') as fileToRead:
        for line in fileToRead:
            result.append(line.rstrip('\n\r\t '))
    return result


def _buildModifiedLuaFiles():
    chatOptionsRules = modtext.ModRules(os.path.abspath('ChatOptions_mod.lua'))
    chatOptionsRules.apply(_backupPath(_ChatOptionsLuaPath), _modifiedChatOptionsLuaPath)
    chatRules = modtext.ModRules(os.path.abspath('Chat_mod.lua'))
    chatRules.apply(_backupPath(_ChatLuaPath), _modifiedChatLuaPath)


def _buildChatmaidZip():
    melderInfoTemplatePath = 'melder_info_template.ini'
    _log.info('read template for melder info from %s', melderInfoTemplatePath)
    with open(melderInfoTemplatePath, 'r', encoding='utf-8') as melderInfoTemplateFile:
        melderInfoTemplate = string.Template(melderInfoTemplateFile.read())

    melderInfoPath = os.path.join(_buildFolder, 'melder_info.ini')
    _log.info('write melder info to %s', melderInfoPath)
    textToWrite = melderInfoTemplate.substitute(_MelderSymbols)
    with open(melderInfoPath, 'w', encoding='utf-8') as melderInfoFile:
        melderInfoFile.write(textToWrite)

    targetZipName = 'Chatmaid_v' + __version__ + '.zip'
    targetZipPath = os.path.join(_distFolder, targetZipName)
    _log.info('write distribution archive to %s', targetZipPath)
    with zipfile.ZipFile(targetZipPath, 'w') as targetZipFile:
        for pathToAdd in (_modifiedChatOptionsLuaPath, _modifiedChatLuaPath, melderInfoPath):
            _log.info('  add %s', pathToAdd)
            targetZipFile.write(pathToAdd, os.path.basename(pathToAdd))

    melderAddonsPath = os.path.expandvars(os.path.join('${LOCALAPPDATA}', 'Melder', 'addons'))
    melderZipPath = os.path.join(melderAddonsPath, targetZipName)
    _log.info('copy melder addon to %s', melderZipPath)
    shutil.copy2(targetZipPath, melderZipPath)


def _logMelderButton():
    _log.info('''bbCode for Melder button:
[center][url=http://astrekassociation.com/melder.php?id=%d][img]http://bit.ly/MelderButton[/img][/url]
[size=1][color=#161C1C][melder_info]version=%s;patch=%s;dlurl=%d[/melder_info][/color][/size][/center]''',
        _AttachmentId, __version__, _FirefallVersion, _AttachmentId)


def _permutations(pools):
    poolCount = len(pools)
    indices = [0] * poolCount
    maxIndices = [len(pools[i]) - 1 for i in range(len(pools))]
    poolIndex = 0
    while poolIndex >= 0:
        yield [pools[i][indices[i]] for i in range(poolCount)]
        poolIndex = poolCount - 1
        hasAdvanced = False
        while (poolIndex >= 0) and not hasAdvanced:
            if indices[poolIndex] == maxIndices[poolIndex]:
                indices[poolIndex] = 0
                poolIndex -= 1
            else:
                indices[poolIndex] += 1
                hasAdvanced = True
    

def _logLuaSmilies():
    smilies = ['"' + ''.join(smilie) + '"' for smilie in _permutations((':;8BX', '-^o', ')(PD'))]
    _log.info('lua code for smilies:\nlocal _SMILIES = Set{' + ', '.join(smilies) + '}')
    

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    _log.info('build chatmaid v' + __version__)
    os.makedirs(_buildFolder, exist_ok=True)
    os.makedirs(_distFolder, exist_ok=True)
    _possiblyBuildBackup(_ChatOptionsLuaPath)
    _possiblyBuildBackup(_ChatLuaPath)
    _buildModifiedLuaFiles()
    _buildChatmaidZip()
    _logMelderButton()
    _logLuaSmilies()
    _log.info('finished')
