'''Build R5Chat.lua that integrates chatmaid.lua'''
import logging
import os.path
import shutil

_R5ChatLuaPath = r'C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\Panels\R5Chat\R5Chat.lua'

_log = logging.getLogger('chatmaid')

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

def _backupPath(sourcePath):
    backupFolder, sourceName = os.path.split(sourcePath)
    baseName, suffix = os.path.splitext(sourceName)
    backupName = baseName + '_backup' + suffix
    result = os.path.join(backupFolder, backupName)
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
    result = 0
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
    assert result != 0, 'R5Chat.lua must contain OnChatMessage() with author query'
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


def _integrateChatmaidInR5Chat(r5ChatLuaPath):
    chatmaidLuaPath = os.path.abspath('chatmaid.lua')
    chatmaidLines = _slurped(chatmaidLuaPath)
    r5ChatBackupPath = _backupPath(r5ChatLuaPath)
    r5ChatLines = _slurped(r5ChatBackupPath)
    indexOfLineWhereToInsertChatmaid = _indexOfLineWhereToInsertChatmaid(r5ChatLines)
    indexOfLineWhereToInsertSanitize = _indexOfLineWhereToInsertSanitize(r5ChatLines)
    assert indexOfLineWhereToInsertChatmaid < indexOfLineWhereToInsertSanitize
    _insertChatmaidLines(r5ChatLines, indexOfLineWhereToInsertSanitize, _SanitizeLuaCode)
    _insertChatmaidLines(r5ChatLines, indexOfLineWhereToInsertChatmaid, chatmaidLines)
    # TODO: Remove: r5ChatLuaPath = r'c:\temp\R5Chat.lua'
    _log.info('write modified %s', r5ChatLuaPath)
    with open(r5ChatLuaPath, 'w', encoding='utf-8') as r5ChatLuaFile:
        for lineToWrite in r5ChatLines:
            r5ChatLuaFile.write(lineToWrite)
            r5ChatLuaFile.write('\n')  # automatically changed to os.linesep
    _log.info('finished')


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    _possiblyBuildBackup(_R5ChatLuaPath)
    _integrateChatmaidInR5Chat(_R5ChatLuaPath)
    
    
