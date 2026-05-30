local lexer = lexer
local P, S, R = lpeg.P, lpeg.S, lpeg.R

local lex = lexer.new(...)

-- 1. Keywords, Constants, Builtins
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:add_rule('constant', lex:tag(lexer.CONSTANT_BUILTIN, lex:word_match(lexer.CONSTANT_BUILTIN)))
lex:add_rule('builtin', lex:tag(lexer.FUNCTION_BUILTIN, lex:word_match(lexer.FUNCTION_BUILTIN)))

-- 2. Strings
local simple_string = lexer.range('"', true)
local multi_line_string = lexer.range("''")
lex:add_rule('string', lex:tag(lexer.STRING, simple_string + multi_line_string))

-- 3. Identifiers
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- 4. Comments
local line_comment = lexer.to_eol('#')
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- 5. Numbers
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- 6. Native Nix Paths & URIs
local alpha_num = R('az', 'AZ', '09')
local path_char = alpha_num + S('._+-')
local path = path_char^0 * (P('/') * path_char^1)^1
local home_path = P('~') * (P('/') * path_char^1)^1
local search_path = P('<') * path_char^1 * (P('/') * path_char^1)^0 * P('>')
lex:add_rule('path', lex:tag(lexer.PREPROCESSOR, path + home_path + search_path))

-- 7. Operators
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('=!<>+-*&|/?.,:;{}()[]')))

-- 8. Fold points
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

-- Word lists
lex:set_word_list(lexer.KEYWORD, {
    'let', 'in', 'if', 'then', 'else', 'with', 'assert', 'inherit', 'rec', 'or'
})

lex:set_word_list(lexer.CONSTANT_BUILTIN, {
    'true', 'false', 'null'
})

lex:set_word_list(lexer.FUNCTION_BUILTIN, {
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

lexer.property['scintillua.comment'] = '#'

return lex