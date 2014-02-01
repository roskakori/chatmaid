# -*- coding: utf-8 -*-
"""
Mod text file according to a mod description.
"""
import ast
import fnmatch
import logging
import os
import tokenize
from io import BytesIO

_log = logging.getLogger('modtext')

_UTF8BOM = b'\xff\xbb\xbf'


def _cleanedLine(line):
    return line.rstrip('\n\r\t ')


def _tokens(lineNumber, line):
    assert lineNumber >= 0
    assert line is not None

    def absoluteLocation(location, lineNumberToAdd):
        assert location is not None
        assert len(location) == 2
        assert lineNumberToAdd >= 0
        result = (location[0] + lineNumberToAdd, location[1])
        return result
        
    result = []
    for toky in tokenize.tokenize(BytesIO(line.encode('utf-8')).readline):
        if toky.type != tokenize.ENCODING:
            result.append(tokenize.TokenInfo(
                type=toky.type, string=toky.string,
                start=absoluteLocation(toky.start, lineNumber),
                end=absoluteLocation(toky.end, lineNumber),
                line=toky.line))
    return result


def _unquotedString(quotedString):
    assert quotedString is not None
    assert len(quotedString) >= 2

    return ast.literal_eval(quotedString)


class ModError(ValueError):
    def __init__(self, location, message):
        assert location is not None
        assert message is not None
        if isinstance(location, tuple):
            assert len(location) == 2
            assert location[0] >= 0
            assert location[1] >= 0
            self.lineNumber, self.columnNumber = location
        else:
            assert location >= 0
            self.lineNumber = location
            self.columnNumber = 0
        self.message = message

    def __str__(self):
        return '%d;%d: %s' % (self.lineNumber, self.columnNumber, self.message)


class BaseFinder(object):
    def __init__(self, keyword, tokens):
        assert (tokens[0].type, tokens[0].string) == (tokenize.OP, '@'), 'tokens[0]=' + str(tokens[0])
        assert (tokens[1].type, tokens[1].string) == (tokenize.NAME, keyword)

        self._searchTerm = None
        self._isGlob = False
        self._isLast = False
        self._isContains = False
        for token in tokens[2:]:
            if token.type == tokenize.NAME:
                if token.string == 'contains':
                    if self._isContains:
                        raise ModError(token.start, 'duplicate "contains" must be removed')
                    self._isGlob = True
                elif token.string == 'glob':
                    if self._isGlob:
                        raise ModError(token.start, 'duplicate "glob" must be removed')
                    self._isGlob = True
                elif token.string == 'last':
                    if self._isLast:
                        raise ModError(token.start, 'duplicate "last" must be removed')
                    self._isLast = True
                else:
                    raise ModError(token.start, 'cannot process unknown keyword "%s"' % token.string)
            elif token.type == tokenize.STRING:
                if self._searchTerm is None:
                    self._searchTerm = _unquotedString(token.string)
                    if self._searchTerm.rstrip() != self._searchTerm:
                        raise ModError(token.start,
                            'trailing white space in search term must be removed because trailing white space in input is automatically discarded and consequently can never be found')
                else:
                    raise ModError(token.start, 'duplicate search term must be removed')
            elif token.type != tokenize.ENDMARKER:
                raise ModError(token.start, 'cannot process unknown keyword "%s"' % token.string)
        if self._searchTerm is None:
            raise ModError(tokens[0].start, 'search term must be specified')
        if self._isContains and self._isGlob:
            self._searchTerm = '*' + self._searchTerm + '*'

    def foundAt(self, lines, startLineNumber=0):
        assert lines is not None
        assert startLineNumber >= 0

        result = None
        lineIndex = startLineNumber
        lineCount = len(lines)
        _log.info('  find starting at %d: %r', lineIndex + 1, self._searchTerm)
        while (lineIndex < lineCount) and ((result is None) or self._isLast):
            lineToExamine = lines[lineIndex]
            _log.debug('    examine %d: %r', lineIndex + 1, lineToExamine)
            if self._isGlob:
                found = fnmatch.fnmatch(lineToExamine, self._searchTerm)
            elif self._isContains:
                found = self._searchTerm in lineToExamine
            else:
                found = (self._searchTerm == lineToExamine)
            if found:
                result = lineIndex
            lineIndex += 1
        if result is None:
            raise ModError(startLineNumber, 'cannot find search term: %s' % self._searchTerm)
        _log.info('    found in line %d: %r', result + 1, self._searchTerm)
        return result


class AfterFinder(BaseFinder):
    def __init__(self, tokens):
        super().__init__('after', tokens)

    def foundAt(self, lines, startLineNumber=0):
        return super().foundAt(lines, startLineNumber) + 1


class BeforeFinder(BaseFinder):
    def __init__(self, tokens):
        super().__init__('before', tokens)


class ModOptions(object):
    def __init__(self):
        self._keyToValuesMap = {
            'encoding': 'utf-8'
        }
    def setOption(self, key, value):
        assert key is not None
        assert value is not None
        if key in self._keyToValuesMap:
            self._keyToValuesMap[key] = value
        else:
            raise ModError('option name %s must be changed to one of: %s' % (key, sorted(self._keyToValuesMap.keys())))

    def getOption(self, key):
        assert key is not None
        result = self.get(self._keyToValuesMap[key])
        if result is None:
            raise ModError('option name %s must be changed to one of: %s' % (key, sorted(self._keyToValuesMap.keys())))
        return result


class Mod(object):
    def __init__(self, modLines, textLines):
        assert modLines is not None
        assert len(modLines) >= 1
        firstLineNumber, firstLine = modLines[0]
        assert firstLine.startswith('@mod'), 'firstLine=%r' % firstLine
        assert textLines is not None

        self._finders = []
        self._textLines = list(textLines)

        # Extract mod description.
        modLineNumber, modLine = modLines[0]
        modTokens = _tokens(modLineNumber, modLine)
        _log.debug(modTokens)
        assert (modTokens[0].type, modTokens[0].string) == (tokenize.OP, '@')
        assert (modTokens[1].type, modTokens[1].string) == (tokenize.NAME, 'mod')
        self.description = _unquotedString(modTokens[2].string)
        if modTokens[2].type != tokenize.STRING:
            raise ModError(modLineNumber, 'after @mod a string to describe the mod must be specified (found: %r)' % self.description)
        if modTokens[3].type != tokenize.ENDMARKER:
            raise ModError(modLineNumber, 'unexpected text after @mod "..." must be removed')
        _log.info('declare mod %s', self.description)

        # Process finders and imports.
        for lineNumber, line in modLines[1:]:
            assert line.startswith('@')
            tokens = _tokens(lineNumber, line)
            if line.startswith('@after'):
                self._finders.append(AfterFinder(tokens))
            elif line.startswith('@before'):
                self._finders.append(BeforeFinder(tokens))
            elif line.startswith('@include'):
                self._includeTextLines(tokens)
                
            else:
                raise ModError(lineNumber, 'unknown mod statement: %s' % line)
        if self._textLines == []:
            raise ModError(modLineNumber, '@mod must be followed by text lines or @include: %s' % self.description)

    def _includeTextLines(self, tokens):
        assert (tokens[0].type, tokens[0].string) == (tokenize.OP, '@')
        assert (tokens[1].type, tokens[1].string) == (tokenize.NAME, 'include')
        pathToIncludeToken = tokens[2]
        if pathToIncludeToken.type != tokenize.STRING:
            raise ModError(modLineNumber, 'after @include a string containing the path to include must be specified (found: %r)' % pathToIncludeToken.string)
        if tokens[3].type != tokenize.ENDMARKER:
            raise ModError(modLineNumber, 'unexpected text after @include "..." must be removed')
        pathToInclude = _unquotedString(pathToIncludeToken.string)
        _log.info('  read include "%s"', pathToInclude)
        # TODO: Make encoding an option.
        with open(pathToInclude, 'r', encoding='utf-8') as includeFile:
            for lineNumber, line in enumerate(includeFile):
                line = _cleanedLine(line)
                self._textLines.append((lineNumber, line))
        
        
    def modded(self, lines):
        assert lines is not None
        lineToInsertTextAt = 0
        for finder in self._finders:
            lineToInsertTextAt = finder.foundAt(lines, lineToInsertTextAt)
        return (lineToInsertTextAt, self._textLines)


class ModRules(object):
    def __init__(self, readable):
        assert readable is not None

        AT_HEADER = 'head'
        AT_MOD = 'mod '
        AT_TEXT = 'text'

        self.mods = []
        self._modLines = []
        self._textLines = []
        state = AT_HEADER
        if isinstance(readable, str):
            readable = open(readable, 'r', encoding='utf-8')
            isClosable = True
        else:
            isClosable = True
        try:
            for lineNumber, line in enumerate(readable):
                line = _cleanedLine(line)
                ignored = False
                lineNumberAndLine = (lineNumber, line)
                if state == AT_HEADER:
                    if (line == '') or line.startswith('#') or line.startswith('--') or line.startswith('//'):
                        ignored = True
                    else:
                        state = AT_TEXT
                if state == AT_TEXT:
                    if line.startswith('@mod'):
                        self._possiblyAppendMod()
                        self._modLines.append(lineNumberAndLine)
                        state = AT_MOD
                    elif self._modLines != []:
                        self._textLines.append(lineNumberAndLine)
                    else:
                        raise ModError(lineNumber, '@mod must occur before text line: %r' % line)
                elif state == AT_MOD:
                    if line.startswith('@'):
                        self._modLines.append(lineNumberAndLine)
                    else:
                        self._textLines.append(lineNumberAndLine)
                        state = AT_TEXT
                _log.debug('%3d:%s - %s', lineNumber, state, line)
        finally:
            if isClosable:
                readable.close()
        self._possiblyAppendMod()
        self._modLines = None
        self._textLines = None

    def _possiblyAppendMod(self):
        if self._modLines != []:
            # If the last text line is empty, remove it.
            if (self._textLines != []) and (self._textLines[-1] == ''):
                self._textLines = self._textLines[:-1]

            self.mods.append(Mod(self._modLines, self._textLines))
            self._modLines = []
            self._textLines = []
        else:
            assert self._textLines == []

    def _lineCommentPrefix(self, path):
        assert path is not None
        suffix = os.path.splitext(path)[1]
        suffix = suffix if not suffix.startswith('.') else suffix[1:]
        if suffix in ('c', 'cc', 'cpp', 'cs', 'cxx', 'c++', 'java', 'js', 'm'):
            result = '//'
        elif suffix in ('lua', 'sql'):
            result = '--'
        elif suffix in ('cfg', 'ini', 'py', 'sh'):
            result = '#'
        else:
            result = None
        return result

    def apply(self, sourcePath, targetPath):
        assert sourcePath is not None
        assert targetPath is not None

        # TODO: Take encoding option into account.
        _log.info('read source "%s"', sourcePath)
        with open(sourcePath, 'r', encoding='utf-8') as sourceFile:
            sourceLines = []
            for line in sourceFile:
                sourceLines.append(_cleanedLine(line))
        _log.info('  read %d lines', len(sourceLines))

        lineNumberToModdedLinesMap = {}
        for mod in self.mods:
            lineNumberToInsertAt, moddedLines = mod.modded(sourceLines)
            if lineNumberToInsertAt not in lineNumberToModdedLinesMap:
                lineNumberToModdedLinesMap[lineNumberToInsertAt] = mod, moddedLines
            else:
                existingMod, _ = lineNumberToModdedLinesMap[lineNumberToInsertAt]
                raise ModError(lineNumberToModdedLinesMap,
                    'only one modification must match the line but currently "%s" and "%s" do: %r' % (
                    existingMod.description, mod.description, sourceLines[lineNumberToInsertAt]))

        _log.info('write modfied target "%s"', targetPath)
        lineCommentPrefix = self._lineCommentPrefix(targetPath)
        if lineCommentPrefix is not None:
            _log.info('  add mod comments using "%s"', lineCommentPrefix)

        with open(targetPath, 'w', encoding='utf-8') as targetFile:
            for lineNumberToWrite, lineToWrite in enumerate(sourceLines):
                modAndModdedLines = lineNumberToModdedLinesMap.get(lineNumberToWrite)
                if modAndModdedLines is not None:
                    mod, moddedLines = modAndModdedLines
                    _log.info('  insert %d modded lines at %d for: %s',
                        len(moddedLines), lineNumberToWrite + 1, mod.description)
                    if lineCommentPrefix is not None:
                        targetFile.write('%s mod begin: %s\n' % (lineCommentPrefix, mod.description))
                    for moddedLocationAndLine in moddedLines:
                        assert len(moddedLocationAndLine) == 2, 'moddedLocationAndLine=%r' % moddedLocationAndLine
                        _, moddedLine = moddedLocationAndLine
                        targetFile.write(moddedLine)
                        targetFile.write('\n')
                    if lineCommentPrefix is not None:
                        targetFile.write('%s mod end: %s\n' % (lineCommentPrefix, mod.description))
                targetFile.write(lineToWrite)
                targetFile.write('\n')
        _log.info('  wrote %d lines', len(sourceLines))


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)

    modPath = r'C:\Users\teflonlove\workspace\chatmaid\ChatOptions_mod.lua'
    sourcePath = r'C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\Panels\R5Chat\ChatOptions.lua'
    targetPath = r'C:\temp\ChatOptions.lua'

#    modPath = r'C:\Users\teflonlove\workspace\chatmaid\R5Chat_mod.lua'
#    sourcePath = r'C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\Panels\R5Chat\R5Chat.lua'
#    targetPath = r'C:\temp\R5Chat.lua'

    _log.info('read mods from "%s"', modPath)
#    with open(modPath, 'r', encoding='utf-8') as modFile:
#        rules = ModRules(modFile)
    rules = ModRules(modPath)
    rules.apply(sourcePath, targetPath)

##        def appendMod(lineNumber, linesToAppend):
##            assert linesToAppend != []
##            # Remove last empty line (if any).
##            if linesToAppend[:-1] == '':
##                linesToAppend = linesToAppend[:-1]
##            mods.append(linesToAppend)
##                
##        for lineNumber, line in enumerate(modFile):
##            line = line.rstrip('\n\r\t ')
##            print(lineNumber, line)
