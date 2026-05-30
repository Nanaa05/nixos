local lexer = lexer
local P, S, R = lpeg.P, lpeg.S, lpeg.R

local lex = lexer.new(...)

-- 1. Comments
local line_comment = '#' * lexer.nonnewline^0
local block_comment = lexer.range('/*', '*/')

-- 2. Strings (Standard double-quote & Nix multi-line double-single-quote)
local simple_string = lexer.range('"')
local multi_line_string = lexer.range("''")

-- 3. Numbers
local number = lexer.integer

-- 4. Native Nix Paths & URIs
local path = R('az', 'AZ', '09', '..') * S('._+-')^0 * (P('/') * R('az', 'AZ', '09', '..') * S('._+-')^0)^1
local home_path = P('~') * (P('/') * R('az', 'AZ', '09', '..') * S('._+-')^0)^1
local search_path = P('<') * R('az', 'AZ', '09', '..') * S('._+-')^0 * (P('/') * R('az', 'AZ', '09', '..') * S('._+-')^0)^0 * P('>')

-- 5. Identifiers & Operators
local identifier = lexer.word
local operator = S('=!<>+-*&|/?.,:;{}()[]')

-- Connect rules to the Lexer Engine
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))
lex:add_rule('string', lex:tag(lexer.STRING, simple_string + multi_line_string))
lex:add_rule('number', lex:tag(lexer.NUMBER, number))
lex:add_rule('path', lex:tag(lexer.INCLUDE, path + home_path + search_path))

lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:add_rule('constant', lex:tag(lexer.CONSTANT, lex:word_match(lexer.CONSTANT)))
lex:add_rule('builtin', lex:tag(lexer.FUNCTION, lex:word_match(lexer.FUNCTION)))

lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, identifier))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, operator))

-- Keywords Map
lex:set_word_list(lexer.KEYWORD, {
    'let', 'in', 'if', 'then', 'else', 'with', 'assert', 'inherit', 'rec', 'or'
})

-- Constants Map
lex:set_word_list(lexer.CONSTANT, {
    'true', 'false', 'null'
})

-- Non-namespaced + core namespaced builtin operators
lex:set_word_list(lexer.FUNCTION, {
    'abort', 'baseNameOf', 'derivation', 'derivationStrict', 'dirOf', 'fetchGit',
    'fetchMercurial', 'fetchTarball', 'import', 'isNull', 'map', 'mapAttrs', 
    'placeholder', 'removeAttrs', 'scopedImport', 'throw', 'toString', 'builtins',
    'add', 'addErrorContext', 'all', 'any', 'attrNames', 'attrValues', 'catAttrs',
    'compareVersions', 'concatLists', 'concatStringsSep', 'currentSystem', 'deepSeq',
    'div', 'elem', 'elemAt', 'fetchurl', 'filter', 'filterSource', 'findFile',
    'foldl\'', 'fromJSON', 'functionArgs', 'genList', 'genericClosure', 'getAttr',
    'getEnv', 'hasAttr', 'hasContext', 'hashString', 'head', 'intersectAttrs',
    'isAttrs', 'isBool', 'isFloat', 'isFunction', 'isInt', 'isList', 'isString',
    'langVersion', 'length', 'lessThan', 'listToAttrs', 'match', 'mul', 'nixPath',
    'nixVersion', 'parseDrvName', 'partition', 'pathExists', 'readDir', 'readFile',
    'replaceStrings', 'seq', 'sort', 'split', 'splitVersion', 'storeDir', 'storePath',
    'stringLength', 'sub', 'substring', 'tail', 'toFile', 'toJSON', 'toPath', 
    'toXML', 'trace', 'tryEval', 'typeOf', 'fromTOML', 'bitAnd', 'bitOr', 'bitXor',
    'floor', 'ceil'
})

return lex
