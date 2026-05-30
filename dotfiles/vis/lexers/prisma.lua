local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

local line_comment = '//' * lexer.nonnewline^0

local string = lexer.range('"')

local number = lexer.integer

local attribute = '@' * P('@')^-1 * lexer.word

local identifier = lexer.word
local operator = S('=:{}[]?|(),.')

lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment))
lex:add_rule('string', lex:tag(lexer.STRING, string))
lex:add_rule('number', lex:tag(lexer.NUMBER, number))
lex:add_rule('attribute', lex:tag(lexer.LABEL, attribute))

lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))
lex:add_rule('variable', lex:tag(lexer.VARIABLE, lex:word_match(lexer.VARIABLE)))

lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, identifier))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, operator))

lex:set_word_list(lexer.KEYWORD, {
    'datasource', 'generator', 'model', 'enum', 'type', 'view'
})

lex:set_word_list(lexer.TYPE, {
    'String', 'Boolean', 'Int', 'Float', 'DateTime', 'Json', 'Bytes', 'BigInt', 'Unsupported'
})

lex:set_word_list(lexer.VARIABLE, {
    'provider', 'output', 'previewFeatures', 'fields', 'references', 'onDelete'
})

return lex