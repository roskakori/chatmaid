'''Build R5Chat.lua that integrates chatmaid.lua'''

# Ensure Python is current enough.
import sys
if sys.version_info < (3, 3):
    raise EnvironmentError('Python 3.3 or later must be installed')

import errno
import logging
import os
import shutil
import zipfile

__version__ = '0.2'

# TODO: Obtain current Firefall patch number programatically.
_FirefallVersion='0.7.1729'

# Numeric ID from the attachments link in the Firefall forums; used by Melder button.
# See http://forums.firefallthegame.com/community/threads/mod-chatmaid-improve-conversations-in-zone-chat.2868821/.
_AttachmentId=0

_buildFolder = os.path.abspath('build')
_distFolder = os.path.abspath('dist')

_R5ChatLuaPath = r'C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\Panels\R5Chat\R5Chat.lua'
_modifiedR5ChatLuaPath = os.path.join(_buildFolder, 'R5Chat.lua')

_log = logging.getLogger('chatmaid')

# Code to be injected in R5Chat.lua to call chatmaid's sanitize().
_SanitizeLuaCode = [
    '\ttext, action = sanitized(args.channel, args.text)',
    '\tif action ~= nil then',
    '\t\tif enableTraceActions then',
    '\t\t\targs.text = args.text.." ["..action.."]"',
    '\t\telseif not text then',
    '\t\t\treturn nil',
    '\t\telse',
    '\t\t\targs.text = text',
    '\t\tend',
    '\tend',
]

# Code for melder_info.ini.
_MelderInfoCode = [
    'title=Chatmaid',
    'author=roskakori',
    'version=%s' % __version__,
    'patch=%s' % _FirefallVersion,
    'url=http://forums.firefallthegame.com/community/threads/addon-chatmaid-improve-conversations-in-zone-chat.2868821/',
    'destination=\gui\components\MainUI\Panels\R5Chat',
    'description=Chatmaid improves the level of conversation in the /zone chat.',
]


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


def _indexOfLineWhereToInsertChatmaid(lines):
    result = 0
    for index, line in enumerate(lines):
        if line.startswith('require'):
            result = index + 1
    assert result != 0, 'R5Chat.lua must contain lines starting with "require"'
    return result


def _indexOfLineWhereToInsertSanitize(lines):
    result = None
    isInOnChatMessage = False
    for index, line in enumerate(lines):
        if not isInOnChatMessage:
            if line.startswith('function OnChatMessage'):
               isInOnChatMessage = True
        else:
            if line.rstrip() == 'end':
                isInOnChatMessage = False
            elif line.strip() == 'if (not args.author) then':
                result = index
    assert result is not None, 'R5Chat.lua must contain OnChatMessage() with author query'
    return result


def _insertChatmaidLines(targetLines, targetIndex, linesToInsert):
    assert targetLines is not None
    assert targetIndex >= 0
    assert linesToInsert is not None

    targetLines.insert(targetIndex, '')
    targetLines.insert(targetIndex, '-- chatmaid - end')
    for line in reversed(linesToInsert):
        targetLines.insert(targetIndex, line)
    targetLines.insert(targetIndex, '-- chatmaid - begin')
    targetLines.insert(targetIndex, '')


def _buildModifiedR5ChatLuaFile():
    chatmaidLuaPath = os.path.abspath('chatmaid.lua')
    chatmaidLines = _slurped(chatmaidLuaPath)
    r5ChatBackupPath = _backupPath(_R5ChatLuaPath)
    r5ChatLines = _slurped(r5ChatBackupPath)
    indexOfLineWhereToInsertChatmaid = _indexOfLineWhereToInsertChatmaid(r5ChatLines)
    indexOfLineWhereToInsertSanitize = _indexOfLineWhereToInsertSanitize(r5ChatLines)
    assert indexOfLineWhereToInsertChatmaid < indexOfLineWhereToInsertSanitize
    _insertChatmaidLines(r5ChatLines, indexOfLineWhereToInsertSanitize, _SanitizeLuaCode)
    _insertChatmaidLines(r5ChatLines, indexOfLineWhereToInsertChatmaid, chatmaidLines)
    _log.info('write modified %s', _modifiedR5ChatLuaPath)
    with open(_modifiedR5ChatLuaPath, 'w', encoding='utf-8') as modifiedR5ChatLuaFile:
        for lineToWrite in r5ChatLines:
            if 'enableTraceActions = true' in lineToWrite:
                lineToWrite = lineToWrite.replace('true', 'false')
                _log.info('  set enableTraceActions = false')
            modifiedR5ChatLuaFile.write(lineToWrite)
            modifiedR5ChatLuaFile.write('\n')  # automatically changed to os.linesep


def _buildChatmaidZip():
    melderInfoPath = os.path.join(_buildFolder, 'melder_info.ini')
    _log.info('write melder info to %s', melderInfoPath)
    with open(melderInfoPath, 'w', encoding='utf-8') as melderInfoFile:
        for lineToWrite in _MelderInfoCode:
            melderInfoFile.write(lineToWrite)
            melderInfoFile.write('\n')

    targetZipName = 'Chatmaid_v' + __version__ + '.zip'
    targetZipPath = os.path.join(_distFolder, targetZipName)
    _log.info('write distribution archive to %s', targetZipPath)
    with zipfile.ZipFile(targetZipPath, 'w') as targetZipFile:
        for pathToAdd in (_modifiedR5ChatLuaPath, melderInfoPath):
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
    while (poolIndex >= 0):
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
    _possiblyBuildBackup(_R5ChatLuaPath)
    _buildModifiedR5ChatLuaFile()
    _buildChatmaidZip()
    _logMelderButton()
    _logLuaSmilies()
    _log.info('finished')
